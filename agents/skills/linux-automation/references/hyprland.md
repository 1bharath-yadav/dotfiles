# Hyprland integration (tier 3)

This skill targets this specific setup: **Arch Linux + Hyprland 0.56.x,
Wayland, single-session**. The compositor state (windows, workspaces, monitors,
focus) is always available as JSON via `hyprctl -j`, which is why it sits above
OCR in the priority ladder: it's machine-readable and instant.

## Lua-based config (important)

Unlike the canonical `hyprland.conf`, this setup uses a **Lua** config — the
[dots-hyprland](https://github.com/end-4 dots)/Hyprlua stack. Entry point:

```
~/.config/hypr/hyprland.lua        # require()s the modules below
~/.config/hypr/hyprland/           # framework defaults (env, execs, keybinds, rules)
~/.config/hypr/custom/             # USER overrides — add your binds here
```

The dispatcher surface you see in binds is `hl.dsp.*`, not raw `hyprctl`
keywords. For example a bind like:

```lua
hl.bind("SUPER + Return", hl.dsp.exec("kitty"))
```

is dispatched at the Hyprlua layer. `hyprland.py` exposes both:

- `dispatch_lua(expr)` → `hyprctl dispatch <expr>` — use for `hl.dsp.*` calls
  (this is what the CLI's window/workspace/monitor handlers use).
- `dispatch(expr)` → same `hyprctl dispatch <expr>` — kept as an alias for plain
  Hyprland keywords like `resizeactive`, `movefocus`, `togglegroup`.

If `hyprctl dispatch <keyword>` returns `unknown dispatcher`, it's because that
keyword is actually wrapped by Hyprlua — switch to the `hl.dsp.<thing>(...)`
form.

## Monitor layout (current)

Single laptop panel:

| Name   | Resolution   | Scale | Position | Reserved (top bar) |
|--------|--------------|-------|----------|--------------------|
| `eDP-1`| 1920×1080@60 | 1.0   | `0,0`    | `[0,40,0,0]`       |

Workspaces are dynamic (Hyprland default). Currently in use: regular `1–4` plus
specials (below).

## Workspace Planning & Max 2 Windows Policy

Organizing workspaces is a mandatory rule in this automation skill:
- **Max 2 windows per workspace**: No numeric workspace should contain more than 2 mapped applications.
- **Planned Placement**: When launching apps via `linux-automation launch "cmd" [--workspace W]`, the command selects an available workspace with < 2 windows.
- **Reorganization**: `linux-automation workspace organize` inspects mapped clients and moves excess windows so every workspace stays organized with at most 2 applications.

## Scratchpads (special workspaces)

Toggled with `hyprctl dispatch togglespecialworkspace <name>` — exposed as
`linux-automation workspace toggle_special <name>`:

| Bind (in `custom/keybinds.lua`) | Special workspace | App |
|--------------------------------|-------------------|-----|
| `SUPER+ALT+O` | `obsidian` | Obsidian |
| `SUPER+Y` | `yazi` | yazi file manager |
| `SUPER+Z` | `kitty` | kitty (scratch terminal) |
| `SUPER+Minus` | `quicknote` | quick note |
| `CTRL+SUPER+C` | `calendar` | calendar |
| `CTRL+SUPER+K` | `keep` | Google Keep |
| `CTRL+SUPER+L` | `tasks` | Google Tasks |
| `CTRL+SUPER+M` | `gmail` | Gmail |
| `SUPER+Comma` | `hermes` | hermes |

A generic `special:special` also exists at runtime.

## Where to add binds

`~/.config/hypr/custom/keybinds.lua`. The framework merges `custom/` over
`hyprland/` defaults, so user binds live there and survive framework updates.
After editing, run `linux-automation learn` to refresh
`knowledge/keybindings.json` (it SHA-256-hashes every `.lua` file and skips
rebuilding when nothing changed).

## Default apps (`custom/variables.lua`)

All routed through `launch_first_available.sh`, which picks the first installed
binary:

- terminal: `kitty -1` → foot → alacritty → wezterm → konsole
- browser: `google-chrome-stable` → zen-browser → firefox → brave
- editor: `antigravity` → code → codium → cursor → zed

## Useful raw commands

```bash
hyprctl -j monitors               # monitor list (used by `monitor list`)
hyprctl -j clients                # every mapped window (used by `window list`)
hyprctl -j activewindow           # focused window (used by `window active`)
hyprctl -j workspaces             # workspaces
hyprctl -j activeworkspace        # focused workspace (+ its monitor)
hyprctl dispatch togglespecialworkspace obsidian
hyprctl dispatch resizeactive 20 0     # +20px width, 0 height
hyprctl dispatch movefocus l           # focus the window to the left
hyprctl kill                      # hard-kill the active window
```

## IPC / events (advanced)

`hyprctl` also exposes a Unix socket (`$HYPRLAND_INSTANCE_SIGNATURE`) and an
event stream (`hyprctl events` / the `hyprland-ipc` sockets under
`$XDG_RUNTIME_DIR/hypr`). This skill doesn't subscribe to events today — it
polls `hyprctl -j` on demand, which is cheap enough. If you build something that
needs reactive behavior (e.g. "when a window opens, do X"), subscribe to the
event socket rather than polling.
