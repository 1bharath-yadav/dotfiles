#!/usr/bin/env zsh
set -eo pipefail

DOTFILES=~/.dotfiles
END4DOTS=~/linux/end4dots
LOG="$DOTFILES/update.log"

log() { echo "\e[32m==>\e[0m $1"; }

cd "$DOTFILES"
log "Unstowing packages..."
stow -D */

log "Updating end4dots..."
cd "$END4DOTS" && git stash -q && git pull -q && ./setup install

log "Cleaning conflicting configs..."
rm -rf ~/.config/{hypr/custom,starship,kitty}

log "Restowing packages..."
cd "$DOTFILES" && stow --restow */ && stow -D shell-sources

echo "[$(date '+%F %T')] updated" >> "$LOG"
log "Done!"


