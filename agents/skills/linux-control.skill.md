# linux-control.skill.md
# Stored at: ~/.dotfiles/agents/skills/linux-control.skill.md (public repo)
# Primary implementation: ~/.dotfiles/agents/skills/linux-control/SKILL.md

---
name: linux-control
description: OS-aware desktop and system control for Arch Linux + Hyprland + Wayland environment. Deterministically manage windows, workspaces, scratchpads, systemd services, pacman/yay packages, media, audio, brightness, clipboard, notifications, screenshots, and terminal commands using native compositor primitives (`hyprctl`), user zsh aliases, and Hyprland keybindings. Trigger whenever the user asks to move/focus/tile/close windows, switch workspaces, control system settings (volume/brightness/wifi/bluetooth/power), manage packages, take screenshots, toggle scratchpads, inspect desktop state, or run OS-level control tasks.
---

# Linux Control (Arch Linux + Hyprland + Wayland)

Native, OS-aware control skill leveraging deterministic Wayland compositor dispatches (`hyprctl`), system utilities, user Zsh aliases, and Hyprland keybindings over Vision-based GUI automation.

See full skill implementation reference at [`agents/skills/linux-control/SKILL.md`](./linux-control/SKILL.md).

## Quick Reference
- **Active Window**: `hyprctl activewindow -j`
- **Clients**: `hyprctl clients -j`
- **Workspaces**: `hyprctl workspaces -j`
- **Focus**: `hyprctl dispatch focuswindow class:<class>`
- **Move Workspace**: `hyprctl dispatch movetoworkspace <id>`
- **Scratchpads**:
  - Obsidian (`SUPER+ALT+O`): `hyprctl dispatch togglespecialworkspace obsidian`
  - Yazi (`SUPER+Y`): `hyprctl dispatch togglespecialworkspace yazi`
  - Kitty (`SUPER+Z`): `hyprctl dispatch togglespecialworkspace kitty`
  - Quicknote (`SUPER+Minus`): `hyprctl dispatch togglespecialworkspace quicknote`
- **Pacman/Yay Aliases**: `ySyu` (system update), `yS` (install), `po` (clean orphans), `pc` (clean cache)
