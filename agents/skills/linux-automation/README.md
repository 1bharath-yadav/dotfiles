# linux-automation

A production-grade Linux desktop automation skill for **Arch Linux + Hyprland
(Wayland)**. Single source of truth for controlling this workstation through
structured APIs rather than screenshot-based reasoning.

## The priority ladder

Every GUI interaction has a fastest reliable tier — try the highest first,
fall through only when it can't see what you need:

1. **Browser DOM/CDP** (`agent-browser`) — for anything in a browser tab.
2. **AT-SPI accessibility tree** (`gi.repository.Atspi`) — native app widgets.
3. **Hyprland IPC** (`hyprctl -j`) — windows, workspaces, monitors, scratchpads.
4. **OCR** (`tesseract`) — canvases, images, PDFs, games.
5. **Coordinate input** (`ydotool`) — last resort.

See [`SKILL.md`](SKILL.md) and [`references/a11y.md`](references/a11y.md).

## Quick start

```bash
# 1. Verify every backend is healthy (never runs sudo)
linux-automation doctor

# 2. Inspect the accessibility tree of a desktop app (no screenshots!)
linux-automation a11y apps
linux-automation a11y find --app firefox --role "push button" --name "Save"
linux-automation a11y click --path 3,0,2,5

# 3. Drive the browser via CDP
linux-automation browser open --url https://example.com
linux-automation browser extract

# 4. Window/workspace/monitor management
linux-automation window active
linux-automation workspace toggle_special obsidian
```

## CLI surface

```
doctor          health-check all backends
a11y            AT-SPI accessibility tree (tier 2)
browser         Chrome CDP via agent-browser (tier 1)
window          Hyprland window management (tier 3)
workspace       workspaces + scratchpads
monitor         monitors
screenshot      grim-based capture
ocr             tesseract OCR
clipboard       wl-copy/wl-paste/cliphist
mouse           ydotool mouse (tier 5)
keyboard        ydotool/wtype keyboard (tier 5)
notify          notify-send
launch          spawn a command
learn           rebuild keybindings knowledge cache
```

Full flags + examples: [`references/cli-reference.md`](references/cli-reference.md).

## Python API

```python
import sys
sys.path.insert(0, "~/.agents/skills/linux-automation/scripts")
import api

api.focus("firefox")
api.hotkey("ctrl+l")
api.type_text("example.com")
api.hotkey("return")
```

## Architecture

`scripts/cli.py` is the `uv run` entrypoint; it lazily imports one module per
subcommand. AT-SPI is special: `gi.repository.Atspi` lives in system
site-packages that `uv`'s isolated venv can't see, so `accessibility.py` is a
thin client that shells out to `_atspi_worker.py` under `/usr/bin/python3` and
parses one JSON line of stdout. Every other backend is imported directly under
`uv run`.

```
scripts/
├── linux-automation     # bash shim → uv run cli.py "$@"
├── cli.py               # argparse dispatcher (lazy per-subcommand imports)
├── _atspi_worker.py     # AT-SPI engine, runs under system python3
├── accessibility.py     # thin client → worker
├── api.py               # composable Python primitives
├── doctor.py            # backend health checks
├── hyprland.py input.py screen.py ocr.py clipboard.py browser.py
└── config_learner.py    # parses ~/.config/hypr/**/*.lua → knowledge/
knowledge/               # cached keybindings.json + SHA-256 hashes
references/              # progressive-disclosure docs (a11y, cli, hyprland, browser)
tests/                   # smoke tests (pytest)
```

## Dependencies

System (already installed on this machine): `at-spi2-core`, `python-gobject`,
`ydotool`/`ydotoold`, `hyprctl`, `grim`, `slurp`, `tesseract`, `wl-clipboard`,
`cliphist`, `google-chrome`, `agent-browser`, `jq`, `libnotify`.

uv-resolved (PEP 723 in `cli.py`): `requests`, `rich`, `pillow`.

`python-pyatspi` is **not** needed — we use the `gi.repository.Atspi` GIR binding
instead, which is already present. Run `linux-automation doctor` to confirm.
