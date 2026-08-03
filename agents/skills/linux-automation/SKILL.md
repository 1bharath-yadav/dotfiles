---
name: linux-automation
description: Intent-based desktop automation, high-level workflow macros, event-driven orchestration, and composite desktop routines for Arch Linux + Hyprland. Handles macros like `start_coding`, `clean_desktop`, `open_research_environment`, `presentation_mode`, `system_maintenance`, `daily_startup`, `daily_shutdown`, `record_session`, and `dictation_note`. Reads semantic state resources (`desktop://`) and orchestrates multi-step desktop workflows deterministically using Hyprland compositor primitives and Linux subsystem integrations. Trigger whenever the user asks for desktop routines, workflow automation, workspace setup, macro actions, or multi-step Arch Linux system routines.
---

# Linux Automation (Arch Linux + Hyprland + Wayland)

High-level intent macros, workflow orchestration, and event-driven automation for Arch Linux + Hyprland. Combines low-level `linux-control` primitives into reliable, deterministic, multi-step workflows.

---

## High-Level Macro Workflows (Layer 4)

### 1. `start_coding`
*Intent: Set up an ideal development workspace instantly.*
```bash
# 1. Switch to workspace 1 for coding
hyprctl dispatch workspace 1

# 2. Launch Kitty terminal or open project editor
hyprctl dispatch exec kitty

# 3. Toggle Obsidian scratchpad for quick note taking
hyprctl dispatch togglespecialworkspace obsidian

# 4. Notify user
notify-send "Workflow" "Development environment ready on workspace 1"
```

### 2. `clean_desktop`
*Intent: Tidies up active workspace by un-floating windows and closing scratchpads.*
```bash
# 1. Inspect open windows
hyprctl activewindow -j

# 2. Unfloat active floating windows if tiled layout desired
hyprctl dispatch togglefloating

# 3. Close any active special scratchpads if open
hyprctl dispatch togglespecialworkspace
```

### 3. `open_research_environment`
*Intent: Open browser, reader, and notes for deep focus research.*
```bash
# 1. Launch Zen Browser (SUPER + ALT + E)
zen-browser &

# 2. Switch to workspace 2
hyprctl dispatch workspace 2

# 3. Bring up Obsidian scratchpad (SUPER + ALT + O)
hyprctl dispatch togglespecialworkspace obsidian
```

### 4. `presentation_mode`
*Intent: Prepare desktop for screen sharing / recording.*
```bash
# 1. Toggle Do-Not-Disturb on notifications (mako / swaync / dunst)
swaync-client -d -s 2>/dev/null || makoctl mode -a do-not-disturb 2>/dev/null

# 2. Maximize / tile focus window
hyprctl dispatch fullscreen 1

# 3. Notify user quietly
notify-send "Presentation Mode" "Do-Not-Disturb enabled, window fullscreen"
```

### 5. `system_maintenance`
*Intent: Full Arch Linux health check and package update routine.*
```bash
# 1. Check system journal errors
journalctl -p 3 -xb -n 20

# 2. Perform system upgrade using user yay alias
yay -Syu --noconfirm

# 3. Clean orphan packages using user alias `po`
yay -Qtdq | sudo pacman -Rns - --noconfirm 2>/dev/null || true

# 4. Clear package cache using user alias `pc`
yay -Sc --noconfirm

# 5. Check disk usage and notify
df -h /
notify-send "System Maintenance" "Arch Linux package update and cleanup completed!"
```

### 6. `daily_startup` & `daily_shutdown`
```bash
# Startup Routine:
# - Refresh chezmoi dotfiles status (`chezmoi status`)
# - Open Scratchpad Yazi (SUPER + Y) & Kitty (SUPER + Z)
# - Display daily GATE study targets

# Shutdown Routine:
# - Sync git changes in dotfiles (`git status --short`)
# - Lock screen or suspend (`systemctl suspend`)
```

### 7. `dictation_note`
*Intent: Voice dictation to Obsidian note flow.*
```bash
# 1. Trigger dictation keybind (~/.local/bin/transcribe --mode toggle)
~/.local/bin/transcribe --mode toggle

# 2. Paste transcript into active Obsidian scratchpad (`wl-paste`)
```

---

## Desktop State Resources (`desktop://`)

Before triggering composite automations, inspect desktop state resources:

| Resource URI | Implementation Command | State Description |
|---|---|---|
| `desktop://focused-window` | `hyprctl activewindow -j` | Active focused window details |
| `desktop://windows` | `hyprctl clients -j` | All open GUI windows |
| `desktop://workspaces` | `hyprctl workspaces -j` | Active & populated workspaces |
| `desktop://monitors` | `hyprctl monitors -j` | Displays, resolutions & scales |
| `desktop://clipboard` | `wl-paste` | Current Wayland clipboard content |
| `desktop://notifications` | `swaync-client -c` / `makoctl history` | Recent notification history |
| `desktop://packages` | `pacman -Qe` | Explicitly installed Arch packages |
| `desktop://battery` | `acpi -b` / `upower -i` | Power and battery status |

---

## Reactive Event Triggers

When system events occur, react deterministically:

1. **Window Opened / Workspace Changed**: Adjust window layout, auto-group, or tile.
2. **Low Battery Event**: Notify via `notify-send`, dim display (`brightnessctl set 30%`), enable power-saver profile.
3. **Clipboard Updated**: Sync or process snippet if note conversion or send-to-phone requested (`send_file.sh`).

---

## Composite Skill Integration

- Blend `linux-automation` with `notes-to-obsidian` for converting captured desktop research into Obsidian cards.
- Blend with `config-refresh` for updating desktop component configs (`hyprland`, `quickshell`, `kitty`).
- Blend with `gate-study` for automated study workspace positioning.
