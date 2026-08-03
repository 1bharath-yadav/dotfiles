"""
High-level automation API for linux-automation.

These are composable primitives an agent (or a user script) can call
directly. They are thin wrappers over the per-backend modules so the CLI
and the API share one code path.

Importing from the CLI's flat-module layout (how ``cli.py`` loads us):
``uv run cli.py`` adds this directory to ``sys.path`` and imports modules
as flat top-level names (``import hyprland``), so this file uses flat
imports to match. If you import the package from elsewhere, add this
``scripts/`` directory to ``sys.path`` first::

    import sys
    sys.path.insert(0, "~/.agents/skills/linux-automation/scripts")
    import api
"""
import subprocess
import time

import hyprland
import input as system_input
import clipboard as system_clip
import ocr as system_ocr
import browser as system_browser


def click(x=0, y=0, button="left"):
    """Click at screen coords ``(x, y)``. ``button`` is ``"left"`` or ``"right"``."""
    btn = "0x110" if button == "left" else "0x111"
    if x or y:
        system_input.run_ydotool(["mousemove", "-a", "--", str(x), str(y)])
    system_input.run_ydotool(["click", btn])


def type_text(text: str):
    """Type a string via ydotool (real keystrokes, honours current layout)."""
    system_input.run_ydotool(["type", text])


def hotkey(keys: str):
    """
    Press a key combination, e.g. ``"ctrl+c"``, ``"super+return"``,
    ``"ctrl+shift+t"``. Delegates to :func:`input.hotkey` which prefers
    ``wtype`` and falls back to ``ydotool key``.
    """
    system_input.hotkey(keys)


def launch(cmd: str, workspace: str | int | None = None) -> str:
    """
    Spawn ``cmd`` detached (non-blocking) in a planned workspace.
    Enforces max 2 applications per workspace by selecting an available workspace.
    """
    target_ws = hyprland.find_planned_or_available_workspace(workspace)
    hyprland.focus_workspace(target_ws)
    subprocess.Popen(cmd, shell=True)
    return target_ws


def organize_workspaces():
    """Organize mapped windows so max 2 applications share any single workspace."""
    return hyprland.organize_workspaces()


def wait(seconds: float):
    """Sleep for ``seconds``."""
    time.sleep(seconds)


def focus(target: str):
    """
    Focus a window. ``target`` is a Hyprland window specifier: a class
    name (``"firefox"``), an address (``"0x..."``), or a prefixed form
    (``"class:firefox"``, ``"address:0x123"``).
    """
    hyprland.focus_window(target)


def find_window(class_name: str):
    """Return the active ``clients`` entry whose class matches, else ``None``."""
    clients = hyprland.get_json("clients") or []
    for c in clients:
        if class_name.lower() in str(c.get("class", "")).lower():
            return c
    return None


def copy(text: str):
    """Set the Wayland clipboard to ``text``."""
    subprocess.run(["wl-copy"], input=text.encode())


def paste() -> str:
    """Return the current Wayland clipboard text."""
    return subprocess.run(
        ["wl-paste"], capture_output=True, text=True
    ).stdout.strip()


def capture(mode="fullscreen", output=None, delay=0.0):
    """Take a screenshot; returns the output path. See ``screen.handle_cli``."""
    import screen
    return screen.capture(mode=mode, output=output, delay=delay)


def ocr(source="region", file=None, boxes=False):
    """Run OCR; returns the extracted text (or boxes dict). See ``ocr.handle_cli``."""
    return system_ocr.run_ocr(source=source, file=file, boxes=boxes)


def find_window_by_title(title_substring: str):
    """Return the first clients entry matching title substring."""
    clients = hyprland.get_json("clients") or []
    for c in clients:
        if title_substring.lower() in str(c.get("title", "")).lower():
            return c
    return None


def move_window(target_workspace: str):
    """Move active window to target workspace."""
    hyprland.dispatch_lua(f'hl.dsp.window.move({{ workspace = "{target_workspace}" }})')


def toggle_special(scratchpad_name: str = "special"):
    """Toggle special workspace scratchpad."""
    hyprland.toggle_special(scratchpad_name)


def maximize():
    """Maximize/fullscreen toggle for active window."""
    hyprland.dispatch_lua('hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })')


def close_window():
    """Close active window."""
    hyprland.dispatch_lua('hl.dsp.window.close()')


def browser_open(url: str):
    """Open ``url`` in the CDP-driven browser via agent-browser."""
    system_browser.run_agent_browser(["goto", url])


def browser_click(selector: str):
    """Click the first element matching ``selector`` (CSS/XPath)."""
    system_browser.run_agent_browser(["click", selector])


def browser_extract(selector: str = None):
    """Read page text (or a specific element's text) via CDP."""
    args = ["get-dom"]
    if selector:
        args += ["--selector", selector]
    return system_browser.run_agent_browser(args)

