"""
Backend health checks for linux-automation.

``doctor`` verifies every backend the skill depends on and prints a
green/red table. For each failing check it prints the exact, non-sudo
command that fixes it. It never runs ``sudo`` / ``pacman`` itself -- the
user (or the driving agent) decides whether to apply the fix.

Run via the CLI: ``linux-automation doctor``.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Callable

from rich.console import Console
from rich.table import Table

console = Console()

WORKER = str(Path(__file__).resolve().parent / "_atspi_worker.py")
SYSTEM_PYTHON = os.environ.get("LINUX_AUTOMATION_SYSTEM_PYTHON", "/usr/bin/python3")


def _have(binary: str) -> bool:
    return shutil.which(binary) is not None


def _user_service_active(unit: str) -> bool:
    try:
        r = subprocess.run(
            ["systemctl", "--user", "is-active", unit],
            capture_output=True, text=True,
        )
        return r.stdout.strip() == "active"
    except Exception:
        return False


def _gsetting_true(schema: str, key: str) -> bool | None:
    """Return the bool value of a gsetting, or None if unreadable."""
    try:
        out = subprocess.run(
            ["gsettings", "get", schema, key],
            capture_output=True, text=True,
        ).stdout.strip()
        return out == "true" if out else None
    except Exception:
        return None


def _worker_ping() -> tuple[bool, str]:
    """Probe the AT-SPI worker; returns (ok, detail)."""
    try:
        r = subprocess.run(
            [SYSTEM_PYTHON, WORKER, "ping"],
            capture_output=True, text=True, timeout=10,
        )
        if r.returncode != 0:
            return False, f"worker exit {r.returncode}: {r.stderr.strip()}"
        data = json.loads(r.stdout.strip().splitlines()[-1])
        return bool(data.get("ok")), data.get("import_error") or "ok"
    except Exception as e:
        return False, f"worker unreachable: {e}"


# --------------------------------------------------------------------------
# Checks -- each returns a dict: {name, ok, detail, fix}
# --------------------------------------------------------------------------

def check() -> list[dict]:
    checks: list[dict] = []

    # --- Accessibility (the priority backend) ---
    a11y_bus = _user_service_active("at-spi-dbus-bus.service")
    checks.append({
        "name": "at-spi bus (at-spi-dbus-bus.service)",
        "ok": a11y_bus,
        "detail": "active" if a11y_bus else "not active",
        "fix": "systemctl --user start at-spi-dbus-bus.service",
    })

    toolkit = _gsetting_true("org.gnome.desktop.interface", "toolkit-accessibility")
    checks.append({
        "name": "toolkit-accessibility gsetting",
        "ok": toolkit is True,
        "detail": str(toolkit).lower() if toolkit is not None else "unreadable",
        "fix": "gsettings set org.gnome.desktop.interface toolkit-accessibility true",
    })

    ok, detail = _worker_ping()
    checks.append({
        "name": "AT-SPI worker (gi.repository.Atspi via system python3)",
        "ok": ok,
        "detail": detail,
        "fix": "sudo pacman -S python-gobject at-spi2-core",
    })

    # --- Input injection ---
    have_ydotool = _have("ydotool")
    checks.append({
        "name": "ydotool (input injection)",
        "ok": have_ydotool,
        "detail": "present" if have_ydotool else "missing",
        "fix": "sudo pacman -S ydotool",
    })
    yd_socket = Path("/run/user") / str(os.getuid()) / ".ydotool_socket"
    socket_ok = yd_socket.exists()
    checks.append({
        "name": "ydotoold socket",
        "ok": socket_ok,
        "detail": str(yd_socket) if socket_ok else f"not found at {yd_socket}",
        "fix": "run ydotoold (no systemd unit on this setup)",
    })

    # --- Compositor ---
    hyprctl = _have("hyprctl")
    checks.append({
        "name": "hyprctl (Hyprland IPC)",
        "ok": hyprctl,
        "detail": "present" if hyprctl else "missing",
        "fix": "you're not on Hyprland? install hyprland",
    })

    # --- Screenshots / OCR ---
    for tool, pkg in [("grim", "grim"), ("slurp", "slurp"), ("tesseract", "tesseract")]:
        have = _have(tool)
        checks.append({
            "name": f"{tool}",
            "ok": have,
            "detail": "present" if have else "missing",
            "fix": f"sudo pacman -S {pkg}",
        })

    # --- Clipboard ---
    for tool in ("wl-copy", "wl-paste"):
        have = _have(tool)
        checks.append({
            "name": tool,
            "ok": have,
            "detail": "present" if have else "missing",
            "fix": "sudo pacman -S wl-clipboard",
        })
    cliphist = _have("cliphist")
    checks.append({
        "name": "cliphist (clipboard history)",
        "ok": cliphist,
        "detail": "present" if cliphist else "missing (history disabled)",
        "fix": "sudo pacman -S cliphist",
    })

    # --- Browser automation ---
    agent_browser = shutil.which("agent-browser") or "/home/archer/.openagents/nodejs/bin/agent-browser"
    ab_ok = Path(agent_browser).exists()
    checks.append({
        "name": "agent-browser (CDP driver)",
        "ok": ab_ok,
        "detail": agent_browser if ab_ok else "not found",
        "fix": "install agent-browser (npm/openagents)",
    })
    chrome = any(_have(b) for b in ("google-chrome-stable", "chromium", "brave-browser"))
    checks.append({
        "name": "chrome / chromium / brave",
        "ok": chrome,
        "detail": "present" if chrome else "none found",
        "fix": "sudo pacman -S google-chrome  # or chromium",
    })

    # --- Misc helpers ---
    for tool, pkg in [("jq", "jq"), ("notify-send", "libnotify")]:
        have = _have(tool)
        checks.append({
            "name": tool,
            "ok": have,
            "detail": "present" if have else "missing",
            "fix": f"sudo pacman -S {pkg}",
        })

    return checks


def handle_cli(args):
    """Print the doctor table. ``--json`` emits machine-readable output."""
    results = check()
    if getattr(args, "json", False):
        console.print_json(data=results)
        return

    table = Table(title="linux-automation — backend health", show_lines=False)
    table.add_column("Status", style="bold", justify="center", width=6)
    table.add_column("Check", style="cyan")
    table.add_column("Detail")
    table.add_column("Fix (you run it)", style="yellow")

    passed = failed = 0
    for c in results:
        status = "[green]✓[/green]" if c["ok"] else "[red]✗[/red]"
        table.add_row(status, c["name"], c["detail"], "" if c["ok"] else c["fix"])
        if c["ok"]:
            passed += 1
        else:
            failed += 1

    console.print(table)
    console.print(
        f"\n[green]{passed} passed[/green], [red]{failed} failed[/red]. "
        "Fixes above are run by you (the skill never runs sudo)."
    )
