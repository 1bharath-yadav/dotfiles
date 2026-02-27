#!/usr/bin/env bash
set -euo pipefail

special="obsidian-note"
obsidian_class="obsidian"

launch_obsidian() {
  xdg-open "obsidian://" >/dev/null 2>&1 &
}

detect_class() {
  local cls
  cls="$(hyprctl clients | awk -F'class: ' '/class: /{print $2}' | sed 's/[[:space:]]*$//' | awk 'tolower($0)=="obsidian"{print $0; exit}')"
  if [[ -n "$cls" ]]; then
    obsidian_class="$cls"
    return 0
  fi
  return 1
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

if detect_class; then
  apply_rules
  toggle_show
else
  launch_obsidian
  for _ in {1..20}; do
    sleep 0.15
    if detect_class; then
      apply_rules
      toggle_show
      break
    fi
  done
fi
