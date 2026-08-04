#!/usr/bin/env python3
"""
AT-SPI worker process.

This file is deliberately run with the *system* ``python3`` (no uv, no
venv), not the ``uv run`` interpreter that powers the rest of this
skill's CLI. AT-SPI bindings (``gi.repository.Atspi``) come from the
``python-gobject`` + ``at-spi2-core`` Arch packages, which install into
system site-packages -- PyGObject is not a pip-installable manylinux
wheel, and ``uv run``'s isolated venvs deliberately don't see system
site-packages. So ``accessibility.py`` (which lives inside the
uv-managed CLI) shells out to this worker and exchanges JSON over stdout
instead of importing ``gi`` directly.

Protocol
--------
    python3 _atspi_worker.py <action> '<json-args>'

The worker prints exactly ONE JSON value on stdout (a single line,
UTF-8, flushed) and exits. On any internal failure it prints a JSON
object of the form ``{"ok": false, "reason": "..."}`` and exits 0 so the
caller can always ``json.loads`` the output. Non-zero exit is reserved
for catastrophes (worker failed to start).

Actions: ping, check, apps, tree, find, click, set_text, get_text
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from typing import Optional

try:
    import gi

    gi.require_version("Atspi", "2.0")
    from gi.repository import Atspi

    _IMPORT_ERROR = None
except Exception as e:  # pragma: no cover - environment dependent
    Atspi = None  # type: ignore
    _IMPORT_ERROR = str(e)


# --------------------------------------------------------------------------
# Low-level safe accessors
# --------------------------------------------------------------------------

def _safe(fn, default=None):
    """Run ``fn``; return ``default`` on any exception. AT-SPI calls raise
    liberally when an object dies mid-traversal, so every access is guarded."""
    try:
        return fn()
    except Exception:
        return default


def _bounds_of(acc):
    """Return ``[x, y, w, h]`` in screen coords, or ``None``."""
    component = _safe(lambda: acc.get_component_iface())
    if not component:
        return None
    try:
        extents = component.get_extents(Atspi.CoordType.SCREEN)
        return [extents.x, extents.y, extents.width, extents.height]
    except Exception:
        return None


def _states_of(acc):
    """Return the list of AT-SPI state-nicknames (e.g. ``focused``, ``sensitive``)."""
    try:
        state_set = acc.get_state_set()
        return [s.value_nick for s in state_set.get_states()]
    except Exception:
        return []


def _node_dict(acc, app_name, path, include_children, depth=0, max_depth=6):
    """Serialise one accessible (and optionally its subtree) to a dict."""
    d = {
        "name": _safe(acc.get_name, "") or "",
        "role": _safe(acc.get_role_name, "") or "",
        "states": _states_of(acc),
        "bounds": _bounds_of(acc),
        "path": path,
        "app": app_name,
    }
    if include_children and depth < max_depth:
        children = []
        count = _safe(acc.get_child_count, 0) or 0
        for i in range(count):
            child = _safe(lambda: acc.get_child_at_index(i))
            if child is not None:
                children.append(
                    _node_dict(child, app_name, path + [i], True, depth + 1, max_depth)
                )
        d["children"] = children
    return d


def _resolve_path(path):
    """Walk child-index path ``[app_idx, child, child, ...]`` from the desktop root."""
    desktop = Atspi.get_desktop(0)
    acc = desktop.get_child_at_index(path[0])
    for idx in path[1:]:
        acc = acc.get_child_at_index(idx)
    return acc


# --------------------------------------------------------------------------
# Actions
# --------------------------------------------------------------------------

def ping() -> dict:
    """Lightweight liveness probe used by ``doctor``. Does not touch the tree."""
    return {"ok": Atspi is not None, "import_error": _IMPORT_ERROR}


def check() -> dict:
    """Full diagnostics: import state, gsetting, registered app count, and hints."""
    result = {
        "gi_repository_atspi": Atspi is not None,
        "import_error": _IMPORT_ERROR,
        "toolkit_accessibility_enabled": None,
        "desktop_app_count": None,
        "notes": [],
    }
    if Atspi is None:
        result["notes"].append(
            "gi.repository.Atspi not importable under system python3. "
            "Install with: sudo pacman -S python-gobject at-spi2-core"
        )
        return result
    try:
        out = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "toolkit-accessibility"],
            capture_output=True, text=True,
        ).stdout.strip()
        result["toolkit_accessibility_enabled"] = out == "true"
        if out != "true":
            result["notes"].append(
                "toolkit-accessibility is disabled. Enable with: "
                "gsettings set org.gnome.desktop.interface toolkit-accessibility true, "
                "then restart target apps."
            )
    except Exception:
        pass
    try:
        desktop = Atspi.get_desktop(0)
        count = desktop.get_child_count()
        result["desktop_app_count"] = count
        if count <= 1:
            result["notes"].append(
                "Few/no apps registered with AT-SPI. Apps started before "
                "toolkit-accessibility was enabled won't appear until restarted; "
                "Electron apps need --force-renderer-accessibility; Qt apps need "
                "QT_ACCESSIBILITY=1."
            )
    except Exception as e:
        result["notes"].append(f"Could not query AT-SPI desktop: {e}")
    return result


def apps() -> list:
    desktop = Atspi.get_desktop(0)
    out = []
    for i in range(desktop.get_child_count()):
        app = _safe(lambda: desktop.get_child_at_index(i))
        if app is None:
            continue
        out.append({
            "index": i,
            "name": _safe(app.get_name, "") or "",
            "role": _safe(app.get_role_name, "") or "",
            "pid": _safe(app.get_process_id, -1),
        })
    return out


def tree(app_name: Optional[str], max_depth: int) -> list:
    desktop = Atspi.get_desktop(0)
    out = []
    for i in range(desktop.get_child_count()):
        app = _safe(lambda: desktop.get_child_at_index(i))
        if app is None:
            continue
        name = _safe(app.get_name, "") or ""
        if app_name and app_name.lower() not in name.lower():
            continue
        out.append(_node_dict(app, name, [i], True, 0, max_depth))
    return out


def find(app_name: Optional[str], role: Optional[str], name_contains: Optional[str], max_depth: int = 20) -> list:
    """Recursive search by role and/or case-insensitive name substring."""
    desktop = Atspi.get_desktop(0)
    matches = []

    def visit(acc, app_disp_name, path, depth):
        if depth > max_depth:
            return
        n = _safe(acc.get_name, "") or ""
        r = _safe(acc.get_role_name, "") or ""
        role_ok = role is None or role.lower() == r.lower()
        name_ok = name_contains is None or name_contains.lower() in n.lower()
        if role_ok and name_ok and (role is not None or name_contains is not None):
            matches.append(_node_dict(acc, app_disp_name, path, False))
        count = _safe(acc.get_child_count, 0) or 0
        for i in range(count):
            child = _safe(lambda: acc.get_child_at_index(i))
            if child is not None:
                visit(child, app_disp_name, path + [i], depth + 1)

    for i in range(desktop.get_child_count()):
        app = _safe(lambda: desktop.get_child_at_index(i))
        if app is None:
            continue
        disp_name = _safe(app.get_name, "") or ""
        if app_name and app_name.lower() not in disp_name.lower():
            continue
        visit(app, disp_name, [i], 0)
    return matches


def click(path: list) -> dict:
    """Invoke an element's Action interface; fall back to a coordinate click."""
    acc = _resolve_path(path)
    if acc is None:
        return {"ok": False, "reason": "element not found"}
    action_iface = _safe(lambda: acc.get_action_iface())
    if action_iface and (_safe(action_iface.get_n_actions, 0) or 0) > 0:
        try:
            action_iface.do_action(0)
            return {"ok": True, "method": "atspi_action"}
        except Exception:
            pass
    bounds = _bounds_of(acc)
    if bounds:
        x, y, w, h = bounds
        cx, cy = x + w // 2, y + h // 2
        try:
            subprocess.run(["ydotool", "mousemove", "-a", "--", str(cx), str(cy)], check=True)
            subprocess.run(["ydotool", "click", "0x110"], check=True)
            return {"ok": True, "method": "ydotool_click", "x": cx, "y": cy}
        except Exception as e:
            return {"ok": False, "reason": f"ydotool click failed: {e}"}
    return {"ok": False, "reason": "no invocable action and no bounds"}


def set_text(path: list, text: str) -> dict:
    """Set text via EditableText; fall back to grab-focus + ydotool type."""
    acc = _resolve_path(path)
    if acc is None:
        return {"ok": False, "reason": "element not found"}
    editable = _safe(lambda: acc.get_editable_text_iface())
    if editable:
        try:
            editable.set_text_contents(text)
            return {"ok": True, "method": "editable_text"}
        except Exception:
            pass
    component = _safe(lambda: acc.get_component_iface())
    if component:
        _safe(lambda: component.grab_focus())
    try:
        subprocess.run(["ydotool", "type", text], check=True)
        return {"ok": True, "method": "ydotool_type"}
    except Exception as e:
        return {"ok": False, "reason": f"ydotool type failed: {e}"}


def get_text(path: list) -> dict:
    """Read text via the Text interface; fall back to the accessible name."""
    acc = _resolve_path(path)
    if acc is None:
        return {"ok": False, "reason": "element not found"}
    text_iface = _safe(lambda: acc.get_text_iface())
    if text_iface:
        try:
            length = text_iface.get_character_count()
            return {"ok": True, "text": text_iface.get_text(0, length)}
        except Exception:
            pass
    return {"ok": True, "text": _safe(acc.get_name, "") or ""}


# --------------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        _emit({"ok": False, "reason": "usage: _atspi_worker.py <action> [json-args]"})
        sys.exit(1)
    action = sys.argv[1]
    raw_args = sys.argv[2] if len(sys.argv) > 2 else "{}"
    try:
        kwargs = json.loads(raw_args)
    except json.JSONDecodeError:
        _emit({"ok": False, "reason": f"invalid json args: {raw_args!r}"})
        sys.exit(1)

    # ping and check are always allowed (check reports the missing-import state).
    if action not in ("ping", "check") and Atspi is None:
        _emit({"ok": False, "reason": f"Atspi unavailable: {_IMPORT_ERROR}"})
        sys.exit(0)

    try:
        if action == "ping":
            _emit(ping())
        elif action == "check":
            _emit(check())
        elif action == "apps":
            _emit(apps())
        elif action == "tree":
            _emit(tree(kwargs.get("app"), kwargs.get("max_depth", 6)))
        elif action == "find":
            _emit(find(kwargs.get("app"), kwargs.get("role"), kwargs.get("name"), kwargs.get("max_depth", 20)))
        elif action == "click":
            _emit(click(kwargs["path"]))
        elif action == "set_text":
            _emit(set_text(kwargs["path"], kwargs["text"]))
        elif action == "get_text":
            _emit(get_text(kwargs["path"]))
        else:
            _emit({"ok": False, "reason": f"unknown action {action}"})
            sys.exit(1)
    except Exception as e:
        # Never leave the caller without parseable JSON.
        _emit({"ok": False, "reason": f"worker crash: {e}"})


def _emit(obj):
    """Print exactly one JSON line, flushed, no trailing junk on stdout."""
    sys.stdout.write(json.dumps(obj, ensure_ascii=False))
    sys.stdout.write("\n")
    sys.stdout.flush()


if __name__ == "__main__":
    main()
