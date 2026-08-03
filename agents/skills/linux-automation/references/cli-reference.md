# CLI reference

Entrypoint: `linux-automation <subcommand> [options]` (a `~/.agents/skills/
linux-automation/scripts/linux-automation` shim that runs `uv run cli.py "$@"`).
All commands print human-readable output by default; add `--json` where noted
for machine-readable output.

## doctor

Health-check every backend and print a green/red table with the exact non-sudo
fix for each failure. **Never runs `sudo`/`pacman` itself.**

```
linux-automation doctor [--json]
```

Run this first on a new machine.

## a11y — AT-SPI accessibility tree (tier 2)

See [`a11y.md`](a11y.md) for the full guide.

```
linux-automation a11y check
linux-automation a11y apps
linux-automation a11y tree [--app NAME] [--depth N]            # default depth 6
linux-automation a11y find [--app NAME] [--role ROLE] [--name SUBSTR]
linux-automation a11y click --path 0,2,1
linux-automation a11y type  --path 0,2,1 --name "the text"
linux-automation a11y read  --path 0,2,1
```

`--path` is a comma-separated child-index list from the desktop root.

## browser — Chrome CDP via agent-browser (tier 1)

```
linux-automation browser status
linux-automation browser open    --url https://example.com
linux-automation browser click   --selector "css-or-xpath"
linux-automation browser type    --selector "input#q" --text "hello"
linux-automation browser scroll  [down|up]            # default down 500px
linux-automation browser extract [--selector S]       # page or element text
linux-automation browser screenshot
linux-automation browser pdf
```

See [`browser.md`](browser.md). Delegates to the `agent-browser` CLI.

## window — Hyprland window management (tier 3)

```
linux-automation window active                       # JSON of focused window
linux-automation window list                         # JSON of all clients
linux-automation window focus   [--target CLASS|0xADDR|class:X|address:X|title:X]
linux-automation window move    --target WORKSPACE
linux-automation window resize  --target "Wdelt Hdelt"   # pixel deltas, e.g. "20 -10"
linux-automation window close
linux-automation window kill                          # hard kill
linux-automation window float                         # toggle floating
linux-automation window tile                          # alias of float (toggle)
linux-automation window fullscreen                    # toggle fullscreen
linux-automation window maximize                      # toggle maximized
linux-automation window minimize                      # move to special:minimized
```

## workspace — workspaces + scratchpads (tier 3)

```
linux-automation workspace list
linux-automation workspace focus <name-or-id>
linux-automation workspace movetoworkspace <name-or-id>     # moves active window
linux-automation workspace toggle_special [name]            # default "special"
linux-automation workspace organize                         # enforce max 2 apps per workspace
```

Scratchpads on this setup (special workspaces): `obsidian`, `yazi`, `kitty`,
`quicknote`, `calendar`, `keep`, `tasks`, `gmail`, `hermes`. See
[`hyprland.md`](hyprland.md) for the full map.

## monitor (tier 3)

```
linux-automation monitor list
linux-automation monitor active
linux-automation monitor focus <name>
```

## screenshot

```
linux-automation screenshot [fullscreen|monitor|active|region] [--delay SECONDS] [--output PATH]
```

Default output dir: `$(xdg-user-dir PICTURES)/Screenshots/`. Prints the saved path.
`region` opens `slurp` for selection; `active` captures the focused window's geometry.

## ocr

```
linux-automation ocr [region|clipboard|file|active] [--file PATH] [--boxes]
```

- `region` — `slurp` a region, OCR it (default).
- `clipboard` — OCR the image currently in the clipboard.
- `active` — OCR the active window.
- `file` — OCR `--file PATH` (the source file is never deleted).
- `--boxes` — emit tesseract TSV (word-level bounding boxes + confidence).

Prints extracted text to stdout.

## clipboard

```
linux-automation clipboard copy   --text "some text"
linux-automation clipboard paste                       # print clipboard text
linux-automation clipboard history                     # cliphist list
linux-automation clipboard clear                       # wipe both wl-clipboard and cliphist
```

## mouse — coordinate input (tier 5)

```
linux-automation mouse move X Y
linux-automation mouse click X Y                       # X,Y optional; defaults 0,0
linux-automation mouse rightclick X Y
linux-automation mouse doubleclick X Y
linux-automation mouse drag X Y --to-x X2 --to-y Y2
```

Input is serialized via an `fcntl` lock on `/tmp/linux-automation-locks/input.lock`.

## keyboard — coordinate input (tier 5)

```
linux-automation keyboard type "some text"
linux-automation keyboard hotkey "ctrl+shift+t"       # + or space separated
```

`hotkey` prefers `wtype` (Wayland-native), falls back to `ydotool key`.

## notify

```
linux-automation notify "Summary" ["body text"]
```

Wraps `notify-send`.

## launch

```
linux-automation launch "cmd --with args" [--workspace WORKSPACE]
```

Spawns the command detached in a planned workspace (or next available workspace with < 2 mapped windows). Enforces max 2 apps per workspace.

## learn

```
linux-automation learn
```

Re-scans `~/.config/hypr/**/*.lua`, SHA-256-hashes each file, and rebuilds
`knowledge/keybindings.json` only if something changed. Uses a balanced-paren
scanner so `hl.bind("K", hl.dsp.exec_cmd("grim ..."))` calls with nested parens
and string literals are captured intact.
