#!/usr/bin/env bash
# Region screenshot -> satty annotation -> clipboard + file.
# Additive alternative to the built-in Quickshell screenshot flow
# (SUPER+SHIFT+S / Print / Ctrl+Print), for when you want to draw arrows
# or boxes on it before it lands in the clipboard. Idea borrowed from
# Omarchy's screenshot->satty flow (basecamp/omarchy); this end-4/dots-hyprland
# foundation already covers region/OCR/translate/record natively, so this
# only fills the one real gap: pre-save annotation.
# Requires: satty, grim, slurp  (pacman -S satty grim slurp)
set -euo pipefail

if ! command -v satty >/dev/null 2>&1; then
  notify-send "Screenshot" "satty is not installed (pacman -S satty)"
  exit 1
fi

dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png"

grim -g "$(slurp)" - | satty --filename -
