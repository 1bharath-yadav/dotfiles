#!/usr/bin/env bash
# stow/arch.sh — stow packages for Arch Linux
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/setup/lib.sh"

PACKAGES=(bin git hypr kitty lazygit nvim starship tmux yazi zsh)

log "Stowing Arch packages"
for pkg in "${PACKAGES[@]}"; do
  restow_pkg "$pkg"
done
log "Done"
