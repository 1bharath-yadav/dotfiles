# Omarchy System Rules

Omarchy is an opinionated Arch Linux distribution with Hyprland and Wayland.

## Golden Rules for Omarchy

1. **NEVER modify `/usr/share/omarchy/`**
   - This directory is owned and managed by the upstream `omarchy` package.
   - Any manual edits will be overwritten on the next `omarchy update`.
   - Always edit user configurations under `~/.config/` instead.

2. **Always Use Stock Omarchy Commands When Available**
   - System updates: `omarchy update` (updates system packages, omarchy assets, and flatpaks).
   - Package management: `omarchy pkg add <pkgs...>` (or `omarchy pkg aur add <pkgs...>`).
   - Debugging: `omarchy debug --no-sudo --print` (avoids hanging on interactive sudo prompts).
   - Theming: `omarchy theme set <name>` or create custom themes in `~/.config/omarchy/themes/<name>/`.
   - Reminders & notifications: `omarchy reminder <min> "<msg>"`.
   - Refresh defaults safely: `omarchy refresh shell` or `omarchy refresh hyprland` (automatically backs up existing configs).

3. **Desktop Configuration Locations**
   - Hyprland: `~/.config/hypr/` (e.g. `looknfeel.lua`, `bindings.lua`, `monitors.lua`). Auto-reloads on save, validate with `hyprctl reload`.
   - Omarchy Shell & Bar: `~/.config/omarchy/shell.json`.
   - Terminal: `~/.config/kitty/kitty.conf` (apply with `omarchy restart terminal`).
