#!/usr/bin/env python

"""
https://github.com/haithium/hyprkan

App-Aware kanata Layer Switcher for Linux
This script acts as an application-aware keyboard layer switcher for Kanata.
It monitors the currently focused window and dynamically adjusts Kanata's
keyboard layer based on the window's class and title.

Core Features:
- Per-app Kanata layer switching
- Run shell commands on window focus
- Send virtual keys to automate input behavior
- Move mouse to a specific (x, y) position

Usage:
    hyprkan [options]

Dependencies:
- Python >= 3.8
- kanata >= 1.8.1
- i3ipc (for Sway)
- python-xlib (for X11)
"""

import argparse
import json
import logging
import os
import re
import signal
import socket
import subprocess
import sys
import threading
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from time import sleep
from typing import Any, Dict, Literal, NoReturn, Optional, Tuple, TypedDict, Union

SCRIPT_VERSION = "2.2.0"


log = logging.getLogger()


class Rule(TypedDict, total=False):
    layer: str
    cls: str
    title: str
    cmd: str
    fake_key: tuple[str, str]
    set_mouse: tuple[int, int]


class WinInfo(TypedDict):
    cls: str
    title: str


# pylint: disable=invalid-name
class utils:

    @staticmethod
    def is_blank(s: str) -> bool:
        """Check if a string is empty/whitespace only."""
        return not s.strip()

    @staticmethod
    def validate_port(port: Union[int, str]) -> tuple[str, int]:
        """Validate a port number or an IP:PORT combination and return (host, port)."""
        port_str = str(port)
        if utils._is_valid_port(port_str):
            return ("127.0.0.1", int(port_str))  # default host localhost
        if utils._is_valid_ip_port(port_str):
            host, port_part = port_str.split(":")
            return (host, int(port_part))

        fatal(
            "Invalid port '%s': Please specify either a port number (e.g., 10000) or "
            "an IP address with port (e.g., 127.0.0.1:10000).",
            port,
        )

    @staticmethod
    def positive_int(value):
        ivalue = int(value)
        if ivalue < 0:
            fatal(f"Expected non-negative integer, got '{value}'")
        return ivalue

    @staticmethod
    def _is_valid_port(port: Union[int, str]) -> bool:
        if isinstance(port, int):
            return 0 < port <= 65535
        if isinstance(port, str) and port.isdigit():
            val = int(port)
            return 0 < val <= 65535
        return False

    @staticmethod
    def _is_valid_ip_port(value: str) -> bool:
        pattern = r"(\d{1,3}(?:\.\d{1,3}){3}):(\d{1,5})"
        match = re.fullmatch(pattern, value)
        if not match:
            return False

        ip, port_str = match.groups()
        port = int(port_str)

        if not utils._is_valid_port(port):
            return False

        if ip == "localhost":
            return True

        octets = ip.split(".")
        return all(o.isdigit() and 0 <= int(o) <= 255 for o in octets)

    @staticmethod
    def _run_cmd(cmd: str):
        """Run a shell command and handle errors."""
        try:
            subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as e:
            fatal("Error occurred while running command: %s\n%s", e, e.stderr)

    @staticmethod
    def run_cmd_bg(cmd: str):
        """Execute a shell command in the background."""
        thread = threading.Thread(target=utils._run_cmd, args=(cmd,))
        thread.start()

    @staticmethod
    def require_env(var_name: str) -> str:
        """Return the value of an environment variable or exit if unset."""
        value = os.getenv(var_name)
        if not value:
            fatal("Required environment variable '%s' is not set.", var_name)
        return value

    @staticmethod
    def validate_fake_key(
        fake_key: tuple[str, str], rule_no: Optional[int]
    ) -> tuple[str, str]:
        name, action = fake_key
        if utils.is_blank(name):
            fatal("Fake key name must not be blank")

        valid_actions = {"Press", "Release", "Tap", "Toggle"}
        action = action.capitalize()
        if action not in valid_actions:
            actions = ", ".join(valid_actions)
            if rule_no:
                msg = f"Invalid config: rule #{rule_no} '{action}' must be one of: {actions}"
            else:
                msg = f"Invalid action '{action}'. Must be one of: {actions}"
            fatal(msg)

        return name, action


class Kanata:
    """TCP client for communicating with kanata."""

    def __init__(self, addr: Tuple[str, int]):
        self.addr = addr
        self._client: socket.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._buffer = ""
        self._connected = False

    def _connect(self):
        log.debug("Connecting to %s:%s", *self.addr)
        try:
            self._client.connect(self.addr)
            self._client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self._client.settimeout(0.5)
            self._connected = True

            # Send a dummy command to avoid the server doesn't error if the client
            # closes without sending anything
            self.get_current_layer_name()

        except socket.error as e:
            ip, port = self.addr
            fatal(
                "Kanata connection error: %s — make sure kanata is running with the -p option "
                "(e.g. `-p %s` or `-p %s:%s`).",
                e,
                port,
                ip,
                port,
            )

    def close(self):
        """Close the client socket connection gracefully."""
        if self._client:
            log.warning("Closing client socket to %s", self.addr)
            try:
                self._client.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass  # Socket may already be closed or unconnected
            self._client.close()

    def _flush_buffer(self):
        """
        Flushes any stale complete messages from the socket buffer before
        sending a new command.
        """
        self._client.settimeout(0.01)
        try:
            while True:
                chunk = self._client.recv(1024)
                if not chunk:
                    break
                self._buffer += chunk.decode("utf-8")
        except socket.timeout:
            pass

        if "\n" in self._buffer:
            parts = self._buffer.split("\n")
            self._buffer = parts[-1]  # Keep only last incomplete piece

    def send(self, cmd: dict) -> Optional[str]:
        if not self._connected:
            self._connect()
        logging.debug("Sending command: %s", cmd)
        msg = json.dumps(cmd) + "\n"

        self._flush_buffer()  # Discard old responses
        self._client.sendall(msg.encode("utf-8"))
        self._client.settimeout(0.05)

        try:
            while "\n" not in self._buffer:
                chunk = self._client.recv(1024)
                if not chunk:
                    break
                self._buffer += chunk.decode("utf-8")
        except socket.timeout:
            return None

        lines = self._buffer.split("\n")
        self._buffer = lines[-1]  # Save incomplete part

        for line in lines[:-1]:
            if line.strip():
                logging.debug("Received response line: %s", line.strip())
                return line.strip()

        return None

    def get_current_layer_name(self) -> str:
        data = self._parse_json_response(self.send({"RequestCurrentLayerName": {}}))
        return data.get("CurrentLayerName", {}).get("name")

    def get_current_layer_info(self) -> Optional[Dict[str, str]]:
        data = self._parse_json_response(self.send({"RequestCurrentLayerInfo": {}}))
        return data.get("CurrentLayerInfo")

    def get_layer_names(self) -> list[str]:
        data = self._parse_json_response(self.send({"RequestLayerNames": {}}))
        return data.get("LayerNames", {}).get("names")

    def change_layer(self, layer: str) -> bool:
        if layer == self.get_current_layer_name():
            log.debug("Layer '%s' is already active.", layer)
            return False
        self._parse_json_response(self.send({"ChangeLayer": {"new": layer}}))
        log.info("Switched to layer '%s'", layer)
        return True

    def act_on_fake_key(self, fake_key: tuple[str, str]) -> None:
        name, action = utils.validate_fake_key(fake_key, rule_no=None)
        self._parse_json_response(
            self.send({"ActOnFakeKey": {"name": name, "action": action}})
        )

    def set_mouse(self, pos: tuple[int, int]) -> None:
        """
        Sends a SetMouse command to Kanata.

        ⚠️ This command is not supported on Linux as of Kanata v1.8.1.
        This method exists as a placeholder for future support.
        """
        x, y = pos
        self._parse_json_response(self.send({"SetMouse": {"x": x, "y": y}}))

    def _parse_json_response(self, response: Optional[str]) -> Dict[str, Any]:
        if response:
            try:
                return json.loads(response)
            except json.JSONDecodeError:
                return {}
        return {}


# pylint: disable=too-few-public-methods
class Config:
    """Load and validate data configuration from a JSON file."""

    def __init__(self, path: str, kanata: Kanata):
        self._path = path
        self._kanata = kanata
        self.rules = self._load()
        self._validate()

    def _load(self) -> list[Rule]:
        if os.path.exists(self._path):
            try:
                with open(self._path, "r", encoding="utf-8") as file:
                    log.info("Loaded configuration file from '%s'", self._path)
                    return json.load(file)
            except json.JSONDecodeError as e:
                fatal("Failed to decode JSON from '%s': %s", self._path, e)
        else:
            fatal("Configuration file not found: %s", self._path)

    def _validate(self) -> None:
        if not isinstance(self.rules, list):
            fatal("Invalid config format: expected an array.")
        allowed_rule_keys = {"class", "title", "layer", "fake_key", "set_mouse", "cmd"}
        kanata_layers = self._kanata.get_layer_names()

        for i, rule in enumerate(self.rules):
            rule_no = i + 1
            rule_fake_key = rule.get("fake_key")
            rule_set_mouse = rule.get("set_mouse")

            unexpected_rule_keys = rule.keys() - allowed_rule_keys
            if unexpected_rule_keys:
                fatal(
                    "Invalid config: rule #%d contains unexpected keys(s): %s. "
                    "Allowed keys: [%s].",
                    rule_no,
                    ", ".join(unexpected_rule_keys),
                    ", ".join(allowed_rule_keys),
                )

            for key in ["class", "title", "layer", "cmd"]:
                value = rule.get(key)
                if value is False or value is None:
                    continue
                if not isinstance(value, str) or utils.is_blank(value):
                    fatal(
                        "Invalid config: key '%s' in rule #%d must be a non-empty "
                        "string or set to false/null or be removed to disable it.",
                        key,
                        rule_no,
                    )

            if not isinstance(rule, dict) or not rule:
                fatal(
                    "Invalid config: rule #%d must be a non-empty JSON object "
                    "(key-value pairs).",
                    rule_no,
                )

            if rule_fake_key:
                if not isinstance(rule_fake_key, list) or not all(
                    isinstance(k, str) for k in rule_fake_key
                ):
                    fatal(
                        "Invalid config: 'fake_key' in rule #%d must be an array of strings.",
                        rule_no,
                    )
                utils.validate_fake_key(rule_fake_key, rule_no)

            if rule_set_mouse and (
                not isinstance(rule_set_mouse, list)
                or not all(isinstance(k, int) for k in rule_set_mouse)
            ):
                fatal(
                    "Invalid config: 'set_mouse' in rule #%d must be an array of integers.",
                    rule_no,
                )

            layer = rule.get("layer")
            if layer and layer not in kanata_layers:
                fatal(
                    "Invalid config: layer '%s' in rule #%d is not defined in your "
                    "Kanata config. Use -l or --layers to list available layers.",
                    layer,
                    rule_no,
                )

        log.info("Configuration at '%s' is valid.", self._path)

    def detect_rule(self, win_info) -> Optional[Rule]:
        """
        Resolve the appropriate rule based on active window information.

        Matches the window's class and title against a set of predefined rules.
        If a rule matches, it is returned. If no rules match, None is returned.
        """

        current_win_class = win_info.get("cls", "*")
        current_win_title = win_info.get("title", "*")

        def to_pattern(value):
            return f".*{value}.*" if value != "*" else ".*"

        for rule in self.rules:
            pattern_class = to_pattern(rule.get("class", "*"))
            pattern_title = to_pattern(rule.get("title", "*"))
            log.debug(
                "Evaluating rule: %s | Current window: {'class':'%s', 'title':'%s'}",
                rule,
                current_win_class,
                current_win_title,
            )

            if re.match(pattern_class, current_win_class) and re.match(
                pattern_title, current_win_title
            ):
                log.debug("Matching rule found: %s", rule)
                return rule

        log.debug("No matching rule found.")
        return None


class BaseWM:
    """Base class for window manager/compositor implementations."""

    def get_active_win(self) -> WinInfo:
        """Return information about the active window; must be overridden."""
        raise NotImplementedError("Implement in subclass")


class WMBaseListener(BaseWM):
    """
    Base class handling window focus events.
    Subclasses must implement `get_active_win` and `_setup_event_listener`.
    """

    def listen(self, kanata: Kanata, cfg: Config):
        """Start listening for window focus changes and manage Kanata layer switching."""

        last_win_title = None
        last_win_class = None

        def on_focus_event():
            nonlocal last_win_title, last_win_class
            win_info = self.get_active_win()
            active_win_class = win_info["cls"]
            active_win_title = win_info["title"]

            if active_win_title != last_win_title or active_win_class != last_win_class:
                log.info(
                    "current_win: {'class':'%s', 'title':'%s'}",
                    active_win_class,
                    active_win_title,
                )
                matched_rule = cfg.detect_rule(win_info)

                if matched_rule:
                    last_win_title = active_win_title
                    last_win_class = active_win_class
                    rule_layer = matched_rule.get("layer")

                    if not rule_layer:
                        return
                    ok = kanata.change_layer(rule_layer)

                    if ok:
                        rule_cmd = matched_rule.get("cmd")
                        fake_key = matched_rule.get("fake_key")
                        set_mouse = matched_rule.get("set_mouse")
                        if rule_cmd:
                            utils.run_cmd_bg(rule_cmd)
                        if fake_key:
                            kanata.act_on_fake_key(fake_key)
                        if set_mouse:
                            kanata.set_mouse(set_mouse)

        self._setup_event_listener(on_focus_event)

    def _setup_event_listener(self, on_focus_callback):
        raise NotImplementedError("Implement in subclass")


class Hyprland(WMBaseListener):
    """
    Interface for Hyprland IPC over UNIX sockets to track active window
    and change Kanata layers.
    """

    def __init__(self):
        self._soc = self._get_soc()
        self._soc2 = self._get_soc2()
        self._validate_sockets()

    def _get_soc(self) -> str:
        runtime_dir = utils.require_env("XDG_RUNTIME_DIR")
        instance_sig = utils.require_env("HYPRLAND_INSTANCE_SIGNATURE")
        return f"{runtime_dir}/hypr/{instance_sig}/.socket.sock"

    def _get_soc2(self) -> str:
        runtime_dir = utils.require_env("XDG_RUNTIME_DIR")
        instance_sig = utils.require_env("HYPRLAND_INSTANCE_SIGNATURE")
        return f"{runtime_dir}/hypr/{instance_sig}/.socket2.sock"

    def _validate_sockets(self):
        """Ensure both Hyprland socket paths exist."""
        for path in [self._soc, self._soc2]:
            if not os.path.exists(path):
                fatal("Hyprland socket not found at %s", path)
            log.debug("Hyprland socket path is valid: %s", path)

    def get_active_win(self) -> WinInfo:
        """Fetch class and title of the active window via Hyprland's JSON IPC."""
        log.debug("Connecting to socket at %s", self._soc)

        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.connect(self._soc)
            sock.send(b"j/activewindow")
            response = sock.recv(4096).decode("utf-8")

        log.debug("Received response: %s", response)

        try:
            win_info = json.loads(response)
        except json.JSONDecodeError:
            log.warning("Failed to parse JSON from socket: %s", response)
            return {"cls": "*", "title": "*"}

        return {
            "cls": win_info.get("class", "*"),
            "title": win_info.get("title", "*"),
        }

    def _setup_event_listener(self, on_focus_callback):
        log.debug("Listening for Hyprland events on socket: %s", self._soc2)

        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(self._soc2)
                sock_file = sock.makefile("r")
                for line in sock_file:
                    event = line.strip()
                    if event.startswith("activewindow>>"):
                        on_focus_callback()
        except FileNotFoundError:
            fatal("Socket not found at: %s", self._soc2)
        except ConnectionRefusedError:
            fatal("Connection refused for socket: %s", self._soc2)


class Niri(WMBaseListener):
    """
    Interface for Niri IPC over UNIX sockets to track active window.
    """

    def __init__(self):
        self._soc = utils.require_env("NIRI_SOCKET")

    def get_active_win(self) -> WinInfo:
        """Fetch class and title of the focused window via Niri's JSON IPC."""
        log.debug("Connecting to Niri socket at %s", self._soc)

        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.connect(self._soc)
            request = json.dumps({"FocusedWindow": None}) + "\n"
            sock.sendall(request.encode())

            response = sock.makefile().readline()
            log.debug("Received response: %s", response)

            try:
                data = json.loads(response)
                focused = data["Ok"]["FocusedWindow"]
                return {
                    "cls": focused.get("app_id", "*"),
                    "title": focused.get("title", "*"),
                }
            except (KeyError, json.JSONDecodeError) as e:
                log.warning("Failed to get focused window info: %s", e)
                return {"cls": "*", "title": "*"}

    def _setup_event_listener(self, on_focus_callback):
        log.debug("Listening for Niri events on socket: %s", self._soc)

        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(self._soc)
                sock_file = sock.makefile("r")

                request = json.dumps({"EventStream": None}) + "\n"
                sock.sendall(request.encode())

                for line in sock_file:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        log.warning("Failed to decode event JSON: %s", line)
                        continue

                    if "WindowFocusChanged" in event:
                        log.debug("Focus changed event: %s", event)
                        on_focus_callback()

        except FileNotFoundError:
            fatal("Niri socket not found at: %s", self._soc)
        except ConnectionRefusedError:
            fatal("Connection refused for socket: %s", self._soc)


class Sway(WMBaseListener):
    """Sway interface using i3ipc to get active window info."""

    def __init__(self):
        try:
            import i3ipc  # pylint: disable=import-outside-toplevel
        except ImportError:
            fatal("Missing dependency: i3ipc is required for Sway support.")

        self.ipc = i3ipc.Connection()

    def get_active_win(self) -> WinInfo:
        focused = self.ipc.get_tree().find_focused()
        if not focused:
            return {"cls": "*", "title": "*"}
        return {
            "cls": focused.app_id or focused.window_class or "*",
            "title": focused.name or "*",  # type: ignore
        }

    def _setup_event_listener(self, on_focus_callback):
        def handler(_ipc, _event):
            on_focus_callback()

        self.ipc.on("window::focus", handler)
        self.ipc.main()


@dataclass
class Atoms:
    """Stores X11 atom identifiers for commonly used window properties."""

    NET_ACTIVE_WINDOW: int
    NET_WM_NAME: int
    WM_CLASS: int


class X11(WMBaseListener):
    """X11 interface using python-xlib to get active window info."""

    def __init__(self):
        # pylint: disable=import-outside-toplevel
        try:
            from Xlib import X, display
            from Xlib.error import (
                BadWindow,
                DisplayConnectionError,
                DisplayError,
                XError,
            )
        except ImportError as exc:
            fatal(
                "Missing dependency: python-xlib is required for X11 support. (%s)", exc
            )

        self.X = X
        self.errors = {
            "DisplayError": DisplayError,
            "XError": XError,
            "BadWindow": BadWindow,
            "DisplayConnectionError": DisplayConnectionError,
        }

        try:
            self.disp = display.Display()
        except DisplayError as e:
            fatal("Failed to connect to X11 display: %s", e)

        self.screen = self.disp.screen()
        self.root = self.screen.root
        self.atoms = Atoms(
            NET_ACTIVE_WINDOW=self.disp.intern_atom("_NET_ACTIVE_WINDOW"),
            NET_WM_NAME=self.disp.intern_atom("_NET_WM_NAME"),
            WM_CLASS=self.disp.intern_atom("WM_CLASS"),
        )
        self.last_seen = {"xid": None}

    def get_active_win(self) -> WinInfo:
        try:
            window_id_prop = self.root.get_full_property(
                self.atoms.NET_ACTIVE_WINDOW, self.X.AnyPropertyType
            )
            if not window_id_prop or not window_id_prop.value:
                return {"cls": "*", "title": "*"}
            window_id = window_id_prop.value[0]
            window = self.disp.create_resource_object("window", window_id)

            title = "*"
            title_prop = window.get_full_property(self.atoms.NET_WM_NAME, 0)
            if title_prop and title_prop.value:
                title = title_prop.value.decode("utf-8", errors="ignore")

            cls = "*"
            class_prop = window.get_full_property(self.atoms.WM_CLASS, 0)
            if class_prop and class_prop.value:
                class_data = class_prop.value.decode("utf-8", errors="ignore").split(
                    "\x00"
                )
                if len(class_data) >= 2:
                    cls = class_data[1]

            return {"cls": cls, "title": title}
        except (
            self.errors["DisplayError"],
            self.errors["XError"],
            UnicodeDecodeError,
            IndexError,
        ) as e:
            log.warning("Failed to get active window info: %s", e)
            return WinInfo(cls="*", title="*")

    def _setup_event_listener(self, on_focus_callback):
        self.root.change_attributes(event_mask=self.X.PropertyChangeMask)
        self.disp.flush()

        while True:
            try:
                event = self.disp.next_event()
                if (
                    event.type == self.X.PropertyNotify
                    and event.atom == self.atoms.NET_ACTIVE_WINDOW
                ):
                    window_id_prop = self.root.get_full_property(
                        self.atoms.NET_ACTIVE_WINDOW, self.X.AnyPropertyType
                    )
                    window_id = (
                        window_id_prop.value[0]
                        if window_id_prop and window_id_prop.value
                        else None
                    )
                    if window_id != self.last_seen["xid"]:
                        self.last_seen["xid"] = window_id
                        on_focus_callback()
            except (
                self.errors["DisplayConnectionError"],
                self.errors["XError"],
                self.errors["BadWindow"],
                IndexError,
            ) as e:
                fatal("Error in event loop: %s", e)


class Session:
    """Manage the current window manager session."""

    def __init__(self):
        wm_name = self._detect_env()
        if wm_name == "Hyprland":
            self.wm = Hyprland()
        elif wm_name == "Sway":
            self.wm = Sway()
        elif wm_name == "Niri":
            self.wm = Niri()
        elif wm_name == "X11":
            self.wm = X11()
        else:
            fatal("Unsupported or unknown WM: %s", wm_name)

        log.debug("Session initialized with %s", wm_name)

    @staticmethod
    def _detect_env() -> str:
        """Detect the current display environment."""

        if os.environ.get("WAYLAND_DISPLAY"):
            if "HYPRLAND_INSTANCE_SIGNATURE" in os.environ:
                wm = "Hyprland"
            elif "SWAYSOCK" in os.environ:
                wm = "Sway"
            elif "NIRI_SOCKET" in os.environ:
                wm = "Niri"
            else:
                wm = "WaylandUnknown"
        elif os.environ.get("DISPLAY"):
            wm = "X11"
        else:
            wm = "Unknown"
        log.debug("Detected environment: %s", wm)
        return wm

    def get_active_window(self):
        """Return the active window info."""
        return self.wm.get_active_win()


class ColorFormatter(logging.Formatter):
    """Formatter that adds ANSI color to log levels for terminal output."""

    COLORS: dict[str, str] = {
        # fmt: off
        "DEBUG":    "\033[34m",  # Blue
        "INFO":     "\033[32m",  # Green
        "WARNING":  "\033[33m",  # Yellow
        "ERROR":    "\033[31m",  # Red
    }
    RESET: str = "\033[0m"
    BOLD: str = "\033[1m"

    def format(self, record):
        level = record.levelname
        color = self.COLORS.get(level, "")
        time_str = datetime.now().strftime("%H:%M:%S.%f")[:-3]  # HH:MM:SS.xxx
        msg = record.getMessage()

        return f"{time_str} {self.BOLD}{color}[{level}]{self.RESET} {msg}"


def config_logger(
    ll: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO",
):
    """Configure the logger to output to stdout with optional color if attached to a terminal."""

    if log.hasHandlers():
        log.handlers.clear()

    level = getattr(logging, ll, logging.INFO)
    log.setLevel(level)

    handler = logging.StreamHandler(sys.stdout)

    if sys.stdout.isatty():
        formatter = ColorFormatter("%(message)s")
    else:
        formatter = logging.Formatter("%(message)s")

    handler.setFormatter(formatter)
    log.addHandler(handler)


def fatal(message: str, *args: object) -> NoReturn:
    """Log an error message and exit the program."""
    log.error(message, *args)
    sys.exit(1)


def get_config_path() -> Path:
    """Return the default path to the kanata apps.json config."""
    home = os.getenv("HOME") or str(Path.home())
    config_home = os.getenv("XDG_CONFIG_HOME")
    base_path = Path(config_home) if config_home else Path(home) / ".config"
    return base_path / "kanata" / "apps.json"


def setup_signals(kanata):
    """Register signal handlers for graceful shutdown."""

    def handle_signal(signum, _frame):
        name = signal.Signals(signum).name
        log.warning("Received signal %s. Exiting gracefully...", name)
        kanata.close()
        sys.exit(1)

    signal.signal(signal.SIGINT, handle_signal)  # Ctrl+C
    signal.signal(signal.SIGTSTP, handle_signal)  # Ctrl+Z
    signal.signal(signal.SIGTERM, handle_signal)  # kill


def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="App-aware kanata Layer Switcher based on active window events."
    )
    parser.add_argument(
        "--log-level",
        type=str.upper,
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="WARNING",
        help="Set logging level (default: WARNING)",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Set logging level to ERROR (overrides --log)",
    )
    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        help="Set logging level to DEBUG (overrides --log)",
    )
    parser.add_argument(
        "--set-mouse",
        nargs=2,
        type=int,
        metavar=("X", "Y"),
        help="Set mouse position to (X, Y) and exit",
    )
    parser.add_argument(
        "--current-layer-name",
        action="store_true",
        help="Print the current active Kanata layer and exit",
    )
    parser.add_argument(
        "--current-layer-info",
        action="store_true",
        help="Print detailed info about the current active Kanata layer and exit",
    )
    parser.add_argument(
        "--fake-key",
        nargs=2,
        metavar=("KEY_NAME", "ACTION"),
        help="Trigger a virtual key's action and exit. ACTION must be one of: "
        "Press, Release, Tap, Toggle.",
    )
    parser.add_argument(
        "--change-layer",
        metavar="LAYER",
        help="Switch to the specified layer and exit.",
    )
    parser.add_argument(
        "-l",
        "--layers",
        action="store_true",
        help="Print kanata layers as JSON and exit.",
    )
    parser.add_argument(
        "-p",
        "--port",
        type=utils.validate_port,
        default="127.0.0.1:10000",
        help="kanata server port (e.g., 10000) or full address (e.g., 127.0.0.1:10000",
    )
    parser.add_argument(
        "-c",
        "--config",
        type=str,
        default=get_config_path(),
        metavar="PATH",
        help="Path to the JSON configuration file (default: $XDG_CONFIG_HOME/kanata/apps.json)",
    )
    parser.add_argument(
        "-w",
        "--current-window-info",
        type=utils.positive_int,
        nargs="?",
        const=0,
        default=None,
        metavar="SECONDS",
        help="Print current window info and exit (optionally wait SECONDS before checking)",
    )
    parser.add_argument(
        "-v",
        "--version",
        action="version",
        version=f"hyprkan {SCRIPT_VERSION}",
        help="Show hyprkan version",
    )
    return parser.parse_args()


def handle_cli_commands(args, kanata, session) -> bool:
    """Handle one-off CLI commands and return True if a command was executed."""

    if args.layers:
        print(kanata.get_layer_names())
    elif args.change_layer:
        kanata.change_layer(args.change_layer)
    elif args.set_mouse:
        kanata.set_mouse(args.set_mouse)
    elif args.fake_key:
        kanata.act_on_fake_key(args.fake_key)
    elif args.current_layer_name:
        print(kanata.get_current_layer_name())
    elif args.current_layer_info:
        print(kanata.get_current_layer_info())
    elif args.current_window_info is not None:
        sleep(args.current_window_info)
        print(session.get_active_window())
    else:
        return False
    return True


def main():
    args = parse_args()
    ll = "ERROR" if args.quiet else "DEBUG" if args.debug else args.log_level

    config_logger(ll)

    session = Session()
    kanata = Kanata(args.port)
    cfg = Config(args.config, kanata)

    setup_signals(kanata)

    if handle_cli_commands(args, kanata, session):
        return

    session.wm.listen(kanata, cfg)


if __name__ == "__main__":
    main()
