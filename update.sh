#!/usr/bin/env zsh
set -eo pipefail

DOTFILES=~/.dotfiles
END4DOTS=~/linux/end4dots
LOG="$DOTFILES/update.log"

log() { echo "\e[32m==>\e[0m $1"; }

# Stow package, auto-removing conflicts
stow.it() {
  local pkg="$1"
  local conflicts=$(stow -nv "$pkg" 2>&1 | grep -oP '(?<=existing target is neither a link nor a directory: ).*')
  [[ -n "$conflicts" ]] && echo "$conflicts" | xargs -I{} rm -rf ~/{} 
  stow "$pkg"
}

# Restow package (unlink then relink), auto-removing conflicts
restow() {
  local pkg="$1"
  stow -D "$pkg" 2>/dev/null || true
  stow.it "$pkg"
}

cd "$DOTFILES"

log "Updating end4dots..."
cd "$END4DOTS" && git stash -q && git pull -q && ./setup install

log "Restowing packages..."
cd "$DOTFILES"
for pkg in */; do
  [[ "$pkg" == "shell-sources/" ]] && continue
  restow "${pkg%/}"
done

echo "[$(date '+%F %T')] updated" >> "$LOG"
log "Done!"


