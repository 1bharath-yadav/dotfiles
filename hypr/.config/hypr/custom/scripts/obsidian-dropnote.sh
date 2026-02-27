#!/usr/bin/env bash
set -euo pipefail

special="obsidian-note"
obsidian_class="obsidian"

launch_obsidian() {
  xdg-open "obsidian://" >/dev/null 2>&1 &
}

is_running() {
  hyprctl clients | grep -q "class: ${obsidian_class}$"
}

apply_rules() {
  hyprctl dispatch movetoworkspacesilent "special:${special},class:${obsidian_class}"
  hyprctl dispatch setfloating "class:${obsidian_class}"
  hyprctl dispatch resizewindowpixel "exact 70% 40%,class:${obsidian_class}"
  hyprctl dispatch movewindowpixel "exact 15% 5%,class:${obsidian_class}"
}

toggle_show() {
  hyprctl dispatch togglespecialworkspace "${special}"
  hyprctl dispatch focuswindow "class:${obsidian_class}"
}

if is_running; then
  apply_rules
  toggle_show
else
  launch_obsidian
  for _ in {1..20}; do
    sleep 0.15
    if is_running; then
      apply_rules
      toggle_show
      break
    fi
  done
fi
