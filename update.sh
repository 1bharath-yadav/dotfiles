#!/usr/bin/env zsh
set -eo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
END4DOTS=~/linux/dots-hyprland
LOG="$DOTFILES/update.log"

source "$DOTFILES/setup/lib.sh"

log "Detecting OS"
OS=$(detect_os)
log "OS: $OS"

# Pull + rebase from upstream (correct way)
if [[ "$OS" == arch ]] && [[ -d "$END4DOTS" ]]; then
  log "Updating end4dots (rebase)"

  cd "$END4DOTS"

  # stash local changes safely
  git stash -q || true

  # ensure upstream exists
  git remote get-url upstream >/dev/null 2>&1 || \
    git remote add upstream https://github.com/end-4/dots-hyprland.git

  # fetch everything
  git fetch upstream

  # rebase current branch onto upstream
  git rebase upstream/main || {
    log "Rebase conflict — manual fix required"
    exit 1
  }

  # optional: update your fork as well
  git push origin HEAD --force -q || true

  # restore stash
  git stash pop -q || true

  # run setup
  "$END4DOTS/setup" install
fi

log "Restowing for $OS"
source "$DOTFILES/stow/${OS}.sh"
install_yazi_pkgs

echo "[$(date '+%F %T')] updated ($OS)" >> "$LOG"
log "Done"
