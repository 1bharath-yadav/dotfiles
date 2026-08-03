---
name: linux-control
description: OS-aware desktop and system control for Arch Linux + Hyprland + Wayland environment. Deterministically manage windows, workspaces, scratchpads, systemd services, pacman/yay packages, media, audio, brightness, clipboard, notifications, screenshots, and terminal commands using native compositor primitives (`hyprctl`), user zsh aliases, and Hyprland keybindings. Trigger whenever the user asks to move/focus/tile/close windows, switch workspaces, control system settings (volume/brightness/wifi/bluetooth/power), manage packages, take screenshots, toggle scratchpads, inspect desktop state, or run OS-level control tasks.
---

# Linux Control (Arch Linux + Hyprland + Wayland)

Native, OS-aware control skill leveraging deterministic Wayland compositor dispatches (`hyprctl`), system utilities, user Zsh aliases, and Hyprland keybindings over Vision-based GUI automation.

---

## Layered System Architecture

```
Layer 3: Intent API (e.g. "Focus Firefox", "Toggle Obsidian scratchpad", "Mute audio")
    │
    ▼
Layer 2: Hyprland API (e.g. `hyprctl dispatch focuswindow class:zen-browser`, `hyprctl -j activewindow`)
    │
    ▼
Layer 1: Linux APIs (e.g. `systemctl`, `wpctl`, `brightnessctl`, `wl-copy`, `pacman`/`yay` zsh aliases)
```

---

## 1. Hyprland Compositor Control (`hyprctl`)

Always query desktop state via JSON BEFORE performing window or workspace dispatches.

### Semantic State Queries (JSON)
```bash
# Query active window details (class, title, workspace, address, PID)
hyprctl activewindow -j

# List all open client windows
hyprctl clients -j

# List all workspaces with active client count
hyprctl workspaces -j

# List connected monitors and layouts
hyprctl monitors -j

# List active keybindings
hyprctl binds -j
```

### Window Management Dispatches
| Intent | `hyprctl` Dispatch Command |
|---|---|
| **Focus window by class/title** | `hyprctl dispatch focuswindow class:<class_name>` or `title:<title>` |
| **Move active window to workspace** | `hyprctl dispatch movetoworkspace <id_or_name>` |
| **Move window silently to workspace** | `hyprctl dispatch movetoworkspacesilent <id_or_name>` |
| **Toggle Floating / Tiled** | `hyprctl dispatch togglefloating` |
| **Toggle Fullscreen** | `hyprctl dispatch fullscreen 0` |
| **Close Active Window** | `hyprctl dispatch killactive` |
| **Center Floating Window** | `hyprctl dispatch centerwindow` |
| **Pin Window (All Workspaces)** | `hyprctl dispatch pin` |
| **Swap Window in Split** | `hyprctl dispatch swapnext` |
| **Toggle Window Group** | `hyprctl dispatch togglegroup` |
| **Change Split Ratio** | `hyprctl dispatch splitratio <+/-amount>` |

### Workspace Dispatches
```bash
# Switch to workspace by ID or relative shift (+1 / -1)
hyprctl dispatch workspace <id>
hyprctl dispatch workspace r+1
hyprctl dispatch workspace r-1

# Move active window to workspace ID or relative
hyprctl dispatch movetoworkspace <id>
```

---

## 2. User Hyprland Scratchpads & Keybindings

Use native Hyprland special workspace dispatches to toggle user scratchpads instantly:

| Scratchpad / Action | Hotkey | `hyprctl` Command / Target |
|---|---|---|
| **Obsidian** | `SUPER + ALT + O` | `hyprctl dispatch togglespecialworkspace obsidian` |
| **Yazi (File Manager)** | `SUPER + Y` | `hyprctl dispatch togglespecialworkspace yazi` |
| **Kitty (Terminal)** | `SUPER + Z` | `hyprctl dispatch togglespecialworkspace kitty` |
| **Quicknote** | `SUPER + Minus` | `hyprctl dispatch togglespecialworkspace quicknote` |
| **Calendar** | `CTRL + SUPER + C` | `hyprctl dispatch togglespecialworkspace calendar` |
| **Google Keep** | `CTRL + SUPER + K` | `hyprctl dispatch togglespecialworkspace keep` |
| **Google Tasks** | `CTRL + SUPER + L` | `hyprctl dispatch togglespecialworkspace tasks` |
| **Gmail** | `CTRL + SUPER + M` | `hyprctl dispatch togglespecialworkspace gmail` |
| **Hermes** | `SUPER + Comma` | `hyprctl dispatch togglespecialworkspace hermes` |
| **Zen Browser** | `SUPER + ALT + E` | `zen-browser` |
| **Koodo Reader** | `SUPER + ALT + K` | `koodo-reader` |
| **Dictation Toggle** | `SUPER + H` | `~/.local/bin/transcribe --mode toggle` |
| **Send File/Clipboard to Phone** | `SUPER + ALT + P` | `~/.local/bin/send_file.sh` |
| **Quickshell Session Toggle** | `SUPER + ALT + F4` | Quickshell session menu |
| **Toggle GDrive Sync** | `SUPER + ALT + G` | `~/.config/hypr/custom/scripts/toggle-gdrive.sh` |

---

## 3. Package Management (Zsh Aliases Integration)

Leverage configured zsh aliases for pacman and yay operations:

| Action | Zsh Alias / Command | Description |
|---|---|---|
| **System Upgrade** | `ySyu` (or `upd`) | Sync & upgrade system repos + AUR |
| **Install Package** | `yS <pkg>` (or `pS <pkg>`) | Install package via yay/pacman |
| **Remove Package** | `yR <pkg>` / `pRs <pkg>` | Remove package and unused dependencies |
| **Search Package** | `ySs <query>` / `pQs <query>` | Search repos and AUR |
| **Clean Package Cache** | `pc` (`yay -Sc`) | Remove cached packages |
| **Remove Orphans** | `po` (`yay -Qtdq \| sudo pacman -Rns -`) | Remove orphaned packages |
| **Query Installed** | `pQe` | List explicitly installed packages |

---

## 4. Hardware & System Subsystems

### Brightness & Power
```bash
# Set brightness (requires brightnessctl)
brightnessctl set +5%
brightnessctl set 5%-

# Power management (systemd / hyprland)
hyprctl dispatch exit          # Exit Hyprland session
systemctl suspend               # Suspend machine
systemctl reboot                # Reboot machine
systemctl poweroff              # Shutdown machine
```

### Audio & Media Control (`PipeWire` / `wpctl` / `playerctl`)
```bash
# Volume control via PipeWire wpctl
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Microphone mute toggle
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Media playback via playerctl
playerctl play-pause
playerctl next
playerctl previous
```

### Wayland Clipboard & Screenshots (`wl-clipboard` / `grim`)
```bash
# Read clipboard text
wl-paste

# Write text to clipboard
echo "content" | wl-copy

# Screenshot to clipboard
grim - | wl-copy

# Screenshot region/full to file
mkdir -p $(xdg-user-dir PICTURES)/Screenshots
grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png
```

### Desktop Notifications (`notify-send`)
```bash
notify-send "Title" "Message body" -u normal -i preferences-system
```

---

## 5. Vision & Input Fallback

Only use screenshot/vision input when non-native Xwayland applications do not expose accessibility trees or window metadata through `hyprctl`.

```bash
# Capture region screenshot for visual inspection
grim -g "$(slurp)" /tmp/inspect_region.png
```

---

## Summary Checklist for `linux-control`
1. Check `hyprctl activewindow -j` or `hyprctl clients -j` before operating on windows.
2. Use native `hyprctl dispatch` over vision/mouse coordinate clicking whenever possible.
3. Utilize user scratchpads (`SUPER+ALT+O`, `SUPER+Y`, `SUPER+Z`, etc.) for seamless window switching.
4. Execute pacman/yay package management using configured zsh aliases (`ySyu`, `yS`, `po`, `pc`).
