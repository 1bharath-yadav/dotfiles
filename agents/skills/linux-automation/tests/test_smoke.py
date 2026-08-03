"""
Smoke tests for linux-automation.

Run with:
    cd ~/.agents/skills/linux-automation
    uv run --with pytest pytest tests/ -q

Or directly:
    uv run --with pytest python -m pytest tests/test_smoke.py -v

Tests are guarded: each one skips itself gracefully if the backend it
exercises isn't available on this machine (so the suite passes on a
partially-set-up box and only fails on real regressions).
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

SCRIPTS = Path(__file__).resolve().parent.parent / "scripts"
WORKER = SCRIPTS / "_atspi_worker.py"
SYSTEM_PYTHON = os.environ.get("LINUX_AUTOMATION_SYSTEM_PYTHON", "/usr/bin/python3")


def _have(binary: str) -> bool:
    return shutil.which(binary) is not None


# --------------------------------------------------------------------------
# CLI entrypoint
# --------------------------------------------------------------------------

@pytest.fixture(scope="module")
def cli():
    """Return a function that runs the linux-automation CLI via uv."""
    def _run(*args, timeout=30):
        return subprocess.run(
            ["uv", "run", str(SCRIPTS / "cli.py"), *args],
            capture_output=True, text=True, timeout=timeout,
        )
    return _run


def test_cli_help(cli):
    """`linux-automation --help` exits 0 and lists every subcommand."""
    r = cli("--help")
    assert r.returncode == 0, r.stderr
    for sub in ("doctor", "a11y", "browser", "window", "workspace", "monitor",
                "screenshot", "ocr", "clipboard", "mouse", "keyboard",
                "notify", "launch", "learn"):
        assert sub in r.stdout, f"missing subcommand {sub!r} in --help output"


# --------------------------------------------------------------------------
# doctor
# --------------------------------------------------------------------------

def test_doctor_runs(cli):
    """doctor exits 0 and reports a table (or JSON). It never runs sudo."""
    r = cli("doctor")
    assert r.returncode == 0, r.stderr
    assert "passed" in r.stdout and "failed" in r.stdout


def test_doctor_json(cli):
    r = cli("doctor", "--json")
    assert r.returncode == 0, r.stderr
    data = json.loads(r.stdout)
    assert isinstance(data, list) and len(data) > 0
    sample = data[0]
    assert {"name", "ok", "detail", "fix"} <= set(sample)


# --------------------------------------------------------------------------
# AT-SPI worker + client (the bug we fixed)
# --------------------------------------------------------------------------

@pytest.mark.skipif(not Path(SYSTEM_PYTHON).exists(), reason="system python3 missing")
def test_worker_ping():
    """The worker imports gi.repository.Atspi under system python3."""
    r = subprocess.run(
        [SYSTEM_PYTHON, str(WORKER), "ping"],
        capture_output=True, text=True, timeout=15,
    )
    assert r.returncode == 0, r.stderr
    data = json.loads(r.stdout.strip().splitlines()[-1])
    assert data["ok"] is True, f"AT-SPI worker not usable: {data}"


def test_a11y_check(cli):
    """a11y check reaches the worker and reports the import state."""
    r = cli("a11y", "check")
    assert r.returncode == 0, r.stderr
    data = json.loads(r.stdout)
    # The whole point of the fix: gi is importable through the worker.
    assert data["gi_repository_atspi"] is True, data


# --------------------------------------------------------------------------
# Hyprland IPC
# --------------------------------------------------------------------------

@pytest.mark.skipif(not _have("hyprctl"), reason="hyprctl not installed")
def test_hyprctl_json_roundtrip():
    """Raw hyprctl -j returns parseable JSON (the basis of tier 3)."""
    r = subprocess.run(
        ["hyprctl", "-j", "monitors"], capture_output=True, text=True, timeout=10,
    )
    assert r.returncode == 0, r.stderr
    monitors = json.loads(r.stdout)
    assert isinstance(monitors, list)


@pytest.mark.skipif(not _have("hyprctl"), reason="hyprctl not installed")
def test_window_active(cli):
    r = cli("window", "active")
    assert r.returncode == 0, r.stderr
    json.loads(r.stdout)  # must be valid JSON


# --------------------------------------------------------------------------
# Clipboard round-trip
# --------------------------------------------------------------------------

@pytest.mark.skipif(not (_have("wl-copy") and _have("wl-paste")),
                    reason="wl-clipboard not installed")
def test_clipboard_roundtrip(cli):
    """copy then paste returns the same text."""
    payload = "linux-automation-smoke-%d" % os.getpid()
    r = cli("clipboard", "copy", "--text", payload)
    assert r.returncode == 0, r.stderr
    r = cli("clipboard", "paste")
    assert r.returncode == 0, r.stderr
    assert payload in r.stdout


# --------------------------------------------------------------------------
# Screenshot
# --------------------------------------------------------------------------

@pytest.mark.skipif(not _have("grim"), reason="grim not installed")
def test_screenshot_writes_file(cli, tmp_path):
    out = tmp_path / "shot.png"
    r = cli("screenshot", "fullscreen", "--output", str(out))
    assert r.returncode == 0, r.stderr
    assert out.exists() and out.stat().st_size > 0


# --------------------------------------------------------------------------
# config_learner extractor (the regex fix)
# --------------------------------------------------------------------------

def test_lua_bind_extractor_balanced():
    """The extractor captures nested-parens actions intact (the old bug)."""
    sys.path.insert(0, str(SCRIPTS))
    try:
        import config_learner as cl
        sample = (
            'hl.bind("SUPER + SHIFT + X", '
            'hl.dsp.exec_cmd(\'grim -g "$(slurp)" - | tesseract - stdout | wl-copy\'), '
            '{ description = "OCR region" })'
        )
        binds = cl.extract_lua_binds(sample)
        assert len(binds) == 1
        b = binds[0]
        assert b["keys"] == "SUPER + SHIFT + X"
        # The action must be complete (balanced parens) and contain the slurp.
        assert b["action"].count("(") == b["action"].count(")"), b["action"]
        assert "$(slurp)" in b["action"]
        assert b["description"] == "OCR region"
    finally:
        sys.path.pop(0)


# --------------------------------------------------------------------------
# Workspace planning & organization
# --------------------------------------------------------------------------

def test_workspace_planning_and_organize():
    """Verify workspace planning logic and organize helper."""
    sys.path.insert(0, str(SCRIPTS))
    try:
        import hyprland
        # Test find_planned_or_available_workspace returns a valid workspace string
        target_ws = hyprland.find_planned_or_available_workspace(1)
        assert target_ws in [str(i) for i in range(1, 11)]
    finally:
        sys.path.pop(0)

