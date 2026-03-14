#!/usr/bin/env bash
# stow/ubuntu.sh — stow packages for Ubuntu / WSL (CLI only, no GUI/Hyprland)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/setup/lib.sh"

PACKAGES=(bin git lazygit nvim starship tmux yazi zsh)

log "Stowing Ubuntu/WSL packages"
for pkg in "${PACKAGES[@]}"; do
  restow_pkg "$pkg"
done
log "Done"
