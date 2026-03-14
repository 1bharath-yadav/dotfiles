#!/usr/bin/env zsh
# update.sh — restow all packages for current OS, pull end4dots
set -eo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
END4DOTS=~/linux/dots-hyprland
LOG="$DOTFILES/update.log"

source "$DOTFILES/setup/lib.sh"

log "Detecting OS"
OS=$(detect_os)
log "OS: $OS"

# Pull end4dots only on Arch (has Hyprland)
if [[ "$OS" == arch ]] && [[ -d "$END4DOTS" ]]; then
  log "Updating end4dots"
  git -C "$END4DOTS" stash -q && git -C "$END4DOTS" pull -q && \
    "$END4DOTS/setup" install
fi

log "Restowing for $OS"
source "$DOTFILES/stow/${OS}.sh"
install_yazi_pkgs

echo "[$(date '+%F %T')] updated ($OS)" >> "$LOG"
log "Done"
