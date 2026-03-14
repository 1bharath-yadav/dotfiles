#!/usr/bin/env bash
# stow/termux.sh — stow packages for Termux
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/setup/lib.sh"

# zsh-termux overrides/extends shared zsh config with termux-specific settings
# termux package stows ~/.termux/ (colors, font, properties)
PACKAGES=(bin nvim starship tmux zsh-termux termux)

log "Stowing Termux packages"
for pkg in "${PACKAGES[@]}"; do
  restow_pkg "$pkg"
done
log "Done"
