#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

log() { printf "==> %s\n" "$1"; }

stow_it() {
  local pkg="$1"
  local conflicts
  conflicts=$(stow -nv "$pkg" 2>&1 | sed -n 's/.*existing target is neither a link nor a directory: //p')
  if [[ -n "$conflicts" ]]; then
    log "Removing conflicts for $pkg"
    printf "%s\n" "$conflicts" | xargs -I{} rm -rf "$HOME/{}"
  fi
  stow "$pkg"
}

restow() {
  local pkg="$1"
  stow -D "$pkg" 2>/dev/null || true
  stow_it "$pkg"
}

cd "$DOTFILES_ROOT"

# WSL/Ubuntu: link CLI-focused configs only. Excludes Hyprland + GUI configs.
STOW_PACKAGES=(
  bin
  nvim
  tmux
  yazi
  zsh
)

log "Restowing WSL Ubuntu packages"
for pkg in "${STOW_PACKAGES[@]}"; do
  restow "$pkg"
done

log "Done"
