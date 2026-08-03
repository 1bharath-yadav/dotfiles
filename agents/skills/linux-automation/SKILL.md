---
name: linux-automation
description: >-
  Single unified Linux workstation automation skill for Arch Linux + Hyprland
  (Wayland). Use whenever the task involves controlling the local desktop GUI:
  clicking, typing, reading or interacting with native application windows,
  managing Hyprland workspaces/windows/monitors/scratchpads, taking screenshots,
  running OCR, or driving the clipboard. Provides a `linux-automation` CLI and a
  Python `api` module. Built around a strict interaction priority that minimizes
  screenshot-based reasoning: (1) Browser DOM/CDP for web content, (2) AT-SPI
  accessibility tree for native desktop apps (GTK/Qt/Electron), (3) Hyprland IPC
  `hyprctl -j` for compositor state, (4) OCR (tesseract) for canvases/images,
  (5) raw coordinate input (ydotool) as a last resort. Prefers structured,
  machine-readable sources over vision. Run `linux-automation doctor` first on a
  new machine to verify backends.
metadata:
  version: "2.0"
  author: chizmoi
  targets:
    distro: arch
    compositor: hyprland
    session: wayland
  backends:
    browser: agent-browser (Chrome CDP)
    accessibility: AT-SPI2 via gi.repository.Atspi (system python3 worker)
    compositor: hyprctl -j
    input: ydotool / ydotoold
    screenshot: grim / slurp
    ocr: tesseract
    clipboard: wl-copy / wl-paste / cliphist
---

# linux-automation

Control this Arch + Hyprland workstation through structured APIs, not pixels.

## The priority ladder (the most important thing in this skill)

Every GUI interaction has a *fastest reliable tier*. Always try the highest tier
first and only fall through when it can't see what you need:

| Tier | Backend | Use for | Command |
|------|---------|---------|---------|
| 1 | **Browser DOM/CDP** | anything inside a browser tab | `linux-automation browser ...` |
| 2 | **AT-SPI accessibility tree** | native app widgets (buttons, fields, menus, text) | `linux-automation a11y ...` |
| 3 | **Hyprland IPC** | windows, workspaces, monitors, scratchpads, focus | `linux-automation window\|workspace\|monitor ...` |
| 4 | **OCR (tesseract)** | canvases, images, PDFs, games, remote desktops | `linux-automation ocr ...` |
| 5 | **Coordinate input (ydotool)** | last resort, or when you only have screen coords | `linux-automation mouse\|keyboard ...` |

Why this order exists and how to choose between tiers is explained in
[`references/a11y.md`](references/a11y.md). Read it before doing any non-trivial
desktop-app automation — AT-SPI is dramatically faster and more reliable than
reading screenshots.

## First run on a new machine

```
linux-automation doctor
```

Verifies every backend (at-spi bus, `gi.repository.Atspi`, ydotool socket,
hyprctl, grim/slurp, tesseract, wl-clipboard, cliphist, agent-browser, chrome).
It prints green/red per check and the exact non-sudo command to fix each red
one. **The skill never runs `sudo`/`pacman` itself** — you decide what to install.

If `a11y check` reports apps but yours is missing, see the "why an app doesn't
appear" notes in `references/a11y.md` (Electron needs `--force-renderer-accessibility`,
Qt needs `QT_ACCESSIBILITY=1`, apps started before the gsetting was enabled must
be restarted).

## CLI surface

```
linux-automation doctor                          # health-check all backends
linux-automation a11y check|apps|tree|find|click|type|read   # AT-SPI (tier 2)
linux-automation browser status|open|click|type|scroll|extract|screenshot|pdf
linux-automation window <action> [--target T]    # Hyprland windows
linux-automation workspace <action> [target]     # focus, movetoworkspace, toggle_special, organize
linux-automation monitor <action> [target]
linux-automation screenshot [fullscreen|monitor|active|region] [--delay S] [--output P]
linux-automation ocr [region|clipboard|file|active] [--file P] [--boxes]
linux-automation clipboard copy|paste|history|clear [--text T]
linux-automation mouse <action> X Y [--to-x X --to-y Y]
linux-automation keyboard type|hotkey "text"
linux-automation notify "summary" ["body"]
linux-automation launch "cmd" [--workspace W]   # open in planned workspace (max 2 per WS)
linux-automation learn                           # rebuild keybindings knowledge cache
```

Full flags + examples for every subcommand live in
[`references/cli-reference.md`](references/cli-reference.md).

## Workspace Planning & Organization (MANDATORY RULE)

Organizing workspaces is a **required and mandatory part** of this skill:

1. **Workspace Allocation & Max 2 Windows Limit**:
   - Every workspace MUST have at most **2 mapped applications/windows**.
   - When launching new applications, they MUST be opened in planned/dedicated workspaces or the first available workspace with fewer than 2 windows.
   - Standard workspace structure:
     - **Workspace 1**: Web Browsers / Main Web Workflows (Chrome, ChatGPT)
     - **Workspace 2**: AI Desktop Apps / Specialized Clients (Claude Desktop)
     - **Workspace 3**: Terminal / Code Editors / Shell
     - **Workspace 4**: Docs / Auxiliary Apps / Media
2. **Workspace Reorganization (`workspace organize`)**:
   - Always run `linux-automation workspace organize` when launching multiple applications to ensure windows are organized, spaced out cleanly, and capped at 2 windows per workspace.

### Common patterns

Find a button by name, then click it via its tree path (no coords needed):
```
linux-automation a11y find --app firefox --role "push button" --name "Save"
linux-automation a11y click --path 0,4,2,1     # path from the find output
```

Organize workspaces to enforce max 2 apps per workspace:
```
linux-automation workspace organize
```

Read what a window says without OCR:
```
linux-automation a11y read --path 0,2,0
```

Toggle a scratchpad, move a window, resize:
```
linux-automation workspace toggle_special obsidian
linux-automation window move 3                  # move active window to workspace 3
linux-automation window resize "20 -10"          # grow width 20px, shrink height 10px
```

## Python API

The same primitives are importable. The CLI loads modules as flat top-level
names, so add the `scripts/` dir to `sys.path`:

```python
import sys
sys.path.insert(0, "~/.agents/skills/linux-automation/scripts")
import api

api.focus("firefox")              # Hyprland focus by class
api.hotkey("ctrl+l")              # address bar
api.type_text("example.com")
api.hotkey("return")
api.copy("some text")
print(api.paste())
path = api.capture(mode="active") # screenshot of active window
print(api.ocr(source="file", file=path))
```

## Hyprland specifics for this setup

This is a **Lua-based** config (dots-hyprland / Hyprlua), not plain
`hyprland.conf`. Window/workspace dispatchers go through `hl.dsp.*` Lua calls,
which is why `hyprland.dispatch_lua('hl.dsp.focus({ workspace = "3" })')` is the
primary dispatch path (raw `hyprctl dispatch <keyword>` also works via
`hyprland.dispatch`). Scratchpads are special workspaces toggled with
`hyprctl dispatch togglespecialworkspace <name>`.

The parsed keybindings from your config are cached in
`knowledge/keybindings.json` (rebuilt by `linux-automation learn`, which uses
SHA-256 file hashes to skip work when nothing changed). Full details — monitor
layout, the scratchpad map, where to add binds — are in
[`references/hyprland.md`](references/hyprland.md).

## Browser automation

CDP is always preferred over accessibility for browser content (DOM access,
selectors, JS execution, downloads). Nothing exposes a CDP port by default on
this machine, so the first browser action launches Chrome with
`--remote-debugging-port`. See [`references/browser.md`](references/browser.md)
for the launch recipe and how `browser.py` delegates to the `agent-browser` CLI.

## Architecture (one paragraph)

`scripts/cli.py` is the `uv run`-powered entrypoint; it lazily imports one module
per subcommand. AT-SPI is special: `gi.repository.Atspi` lives in system
site-packages that `uv`'s isolated venv can't see, so `accessibility.py` is a
*thin client* that shells out to `_atspi_worker.py` under `/usr/bin/python3` and
parses one JSON line of stdout. Every other backend (`hyprland`, `input`,
`screen`, `ocr`, `clipboard`, `browser`) is imported directly under `uv run`.
`api.py` re-exports the composable primitives for Python callers.

## Troubleshooting

- **`a11y` says "worker unreachable"** → run `linux-automation doctor`; the
  `python-gobject` / `at-spi2-core` check is the usual culprit.
- **App doesn't appear in `a11y apps`** → see `references/a11y.md` §
  "Why an app doesn't register". Most common: Electron app needs
  `--force-renderer-accessibility`, or it was started before
  `toolkit-accessibility` was enabled (restart it).
- **`hyprctl dispatch <x>` says "unknown dispatcher"** → that's a plain Hyprland
  keyword; if it's actually a `hl.dsp.*` bind in your config, use
  `dispatch_lua('hl.dsp.<thing>(...)')` instead.
- **ydotool does nothing** → `doctor` will flag a missing
  `/run/user/$UID/.ydotool_socket`; start `ydotoold` (no systemd unit on this setup).
