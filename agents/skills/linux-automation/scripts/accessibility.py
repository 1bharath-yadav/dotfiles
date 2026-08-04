"""
Accessibility (AT-SPI) automation client for linux-automation.

This is a *thin client*. The real AT-SPI work happens in
``_atspi_worker.py``, which runs under the system ``python3`` (not
``uv run``) so it can import ``gi.repository.Atspi`` from system
site-packages. Every function here shells out to the worker and parses
one JSON line of output. See ``_atspi_worker.py`` for why this split
exists, and ``references/a11y.md`` for the full guide.

PRIORITY IN THIS SKILL
----------------------
    1. Browser DOM/CDP        (scripts/browser.py)   -- for browser tabs
    2. AT-SPI accessibility   (this module)          -- for desktop apps
    3. Hyprland IPC           (scripts/hyprland.py)  -- window/workspace state
    4. OCR                    (scripts/ocr.py)       -- canvases, images, games
    5. Raw coordinate clicks  (scripts/input.py)     -- last resort

Only fall through to a lower tier when the higher one can't see the
element you need.

PREREQUISITES (quick)
---------------------
- ``at-spi-dbus-bus.service`` running (it is, on this system).
- ``org.gnome.desktop.interface toolkit-accessibility`` == ``true`` (it is).
- ``python-gobject`` + ``at-spi2-core`` installed (they are).
- Electron apps need ``--force-renderer-accessibility``; Qt apps need
  ``QT_ACCESSIBILITY=1``; terminals generally don't expose a useful tree.

Run ``linux-automation a11y check`` or ``linux-automation doctor`` to
verify all of the above at once.
"""
from __future__ import annotations

import json
import os
import subprocess
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from rich.console import Console

console = Console()

# Resolve the worker once. __file__ is .../scripts/accessibility.py, so the
# worker lives right next to it.
WORKER = str(Path(__file__).resolve().parent / "_atspi_worker.py")
SYSTEM_PYTHON = os.environ.get("LINUX_AUTOMATION_SYSTEM_PYTHON", "/usr/bin/python3")


# --------------------------------------------------------------------------
# Worker transport
# --------------------------------------------------------------------------

class AtspiError(RuntimeError):
    """Raised when the worker reports ``ok: false`` or fails to run."""


def _call_worker(action: str, **kwargs):
    """
    Invoke the AT-SPI worker for ``action`` with JSON kwargs, return the
    parsed JSON response. The worker always prints exactly one JSON line.
    Raises :class:`AtspiError` if the worker can't be spawned or returns
    ``ok: false``.
    """
    payload = json.dumps(kwargs) if kwargs else "{}"
    try:
        proc = subprocess.run(
            [SYSTEM_PYTHON, WORKER, action, payload],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except FileNotFoundError:
        raise AtspiError(f"system python not found at {SYSTEM_PYTHON}")
    except subprocess.TimeoutExpired:
        raise AtspiError(f"worker timed out on action {action!r}")

    if proc.returncode != 0:
        # Worker reserves non-zero exit for startup failures; surface stderr.
        raise AtspiError(
            f"worker exited {proc.returncode} on {action!r}: {proc.stderr.strip()}"
        )

    out = proc.stdout.strip()
    if not out:
        raise AtspiError(f"worker returned no output for {action!r}")
    try:
        return json.loads(out.splitlines()[-1])
    except json.JSONDecodeError as e:
        raise AtspiError(f"worker returned non-JSON for {action!r}: {out!r} ({e})")


# --------------------------------------------------------------------------
# Availability / diagnostics
# --------------------------------------------------------------------------

def check_available() -> dict:
    """
    Diagnose whether AT-SPI automation is usable right now. Returns a dict
    the CLI/agent can inspect instead of just crashing on a missing bridge.
    Proxies to the worker's ``check`` action so the import is tested under
    the *system* python (where it actually has to work).
    """
    try:
        return _call_worker("check")
    except AtspiError as e:
        return {
            "gi_repository_atspi": False,
            "import_error": str(e),
            "toolkit_accessibility_enabled": None,
            "desktop_app_count": None,
            "notes": [f"worker unreachable: {e}"],
        }


def _require_ok(resp, what: str):
    """For action responses shaped as ``{"ok": bool, ...}``: raise if not ok."""
    if isinstance(resp, dict) and resp.get("ok") is False:
        raise AtspiError(f"{what} failed: {resp.get('reason', 'unknown')}")


# --------------------------------------------------------------------------
# Tree model (mirrors the worker's node dict for callers that want objects)
# --------------------------------------------------------------------------

@dataclass
class Node:
    name: str
    role: str
    states: list[str] = field(default_factory=list)
    bounds: Optional[tuple[int, int, int, int]] = None  # x, y, w, h
    path: list[int] = field(default_factory=list)  # child-index path from the app root
    app: str = ""
    children: list["Node"] = field(default_factory=list)

    def to_dict(self, include_children: bool = True) -> dict:
        d = {
            "name": self.name,
            "role": self.role,
            "states": self.states,
            "bounds": self.bounds,
            "path": self.path,
            "app": self.app,
        }
        if include_children:
            d["children"] = [c.to_dict() for c in self.children]
        return d

    @classmethod
    def from_dict(cls, d: dict) -> "Node":
        bounds = d.get("bounds")
        return cls(
            name=d.get("name", ""),
            role=d.get("role", ""),
            states=d.get("states", []),
            bounds=tuple(bounds) if bounds else None,
            path=list(d.get("path", [])),
            app=d.get("app", ""),
            children=[cls.from_dict(c) for c in d.get("children", [])],
        )


# --------------------------------------------------------------------------
# Public API (each shells out to the worker)
# --------------------------------------------------------------------------

def list_applications() -> list[dict]:
    """List every application currently registered on the AT-SPI bus."""
    return _call_worker("apps")


def get_tree(app_name: Optional[str] = None, max_depth: int = 6) -> list[dict]:
    """
    Return the accessibility tree as nested dicts. If app_name is given,
    only that application's subtree is returned (matched by substring,
    case-insensitive); otherwise every registered app is returned.
    """
    return _call_worker("tree", app=app_name, max_depth=max_depth)


def find(
    app_name: Optional[str] = None,
    role: Optional[str] = None,
    name_contains: Optional[str] = None,
    max_depth: int = 20,
) -> list[dict]:
    """
    Search the accessibility tree for elements matching role and/or a
    case-insensitive substring of their accessible name. This is the
    primary way to locate a button/field/menu-item before acting on it.
    """
    return _call_worker(
        "find", app=app_name, role=role, name=name_contains, max_depth=max_depth
    )


def click_path(path: list[int]) -> bool:
    """
    Click an element located by its tree path (as returned by find()/get_tree()).
    Tries the AT-SPI Action interface first (role-appropriate, no mouse
    movement, works even if the window is occluded); falls back to a real
    mouse click at the element's screen center via ydotool.
    """
    resp = _call_worker("click", path=list(path))
    if resp.get("ok"):
        return True
    console.print(f"[red]click failed:[/red] {resp.get('reason', 'unknown')}")
    return False


def set_text_path(path: list[int], text: str) -> bool:
    """Set text directly via the EditableText interface (no keystrokes needed)."""
    resp = _call_worker("set_text", path=list(path), text=text)
    if resp.get("ok"):
        return True
    console.print(f"[red]set_text failed:[/red] {resp.get('reason', 'unknown')}")
    return False


def get_text_path(path: list[int]) -> Optional[str]:
    """Read text content from an element via the Text interface, if exposed."""
    resp = _call_worker("get_text", path=list(path))
    if resp.get("ok"):
        return resp.get("text")
    return None


def wait_for(
    app_name: Optional[str] = None,
    role: Optional[str] = None,
    name_contains: Optional[str] = None,
    timeout: float = 10.0,
    poll_interval: float = 0.3,
) -> Optional[dict]:
    """Poll the tree until a matching element appears (or timeout)."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            matches = find(app_name=app_name, role=role, name_contains=name_contains)
        except AtspiError:
            matches = []
        if matches:
            return matches[0]
        time.sleep(poll_interval)
    return None


# --------------------------------------------------------------------------
# CLI glue
# --------------------------------------------------------------------------

def handle_cli(args):
    if args.action == "check":
        console.print_json(data=check_available())
        return

    # Everything below talks to the worker; surface transport errors cleanly.
    try:
        if args.action == "apps":
            console.print_json(data=list_applications())
        elif args.action == "tree":
            console.print_json(data=get_tree(app_name=args.app, max_depth=args.depth))
        elif args.action == "find":
            console.print_json(
                data=find(app_name=args.app, role=args.role, name_contains=args.name)
            )
        elif args.action == "click":
            if not args.path:
                console.print("[red]--path is required, e.g. --path 0,2,1[/red]")
                return
            path = [int(p) for p in args.path.split(",")]
            ok = click_path(path)
            console.print("[green]Clicked.[/green]" if ok else "[red]Click failed.[/red]")
        elif args.action == "type":
            if not args.path or args.name is None:
                console.print("[red]--path and --name (used as the text) are required.[/red]")
                return
            path = [int(p) for p in args.path.split(",")]
            ok = set_text_path(path, args.name)
            console.print("[green]Text set.[/green]" if ok else "[red]Failed to set text.[/red]")
        elif args.action == "read":
            if not args.path:
                console.print("[red]--path is required[/red]")
                return
            path = [int(p) for p in args.path.split(",")]
            console.print(get_text_path(path) or "")
    except AtspiError as e:
        console.print(f"[red]AT-SPI error:[/red] {e}")
