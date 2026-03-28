#!/usr/bin/env zsh
set -eo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
END4DOTS=~/linux/dots-hyprland
LOG="$DOTFILES/update.log"

source "$DOTFILES/setup/lib.sh"

log "Detecting OS"
OS=$(detect_os)
log "OS: $OS"

# Sync end4dots fork with upstream (two-branch strategy)
# main  → clean mirror of upstream/main (never commit here)
# archer → your changes, rebased on top of main
if [[ "$OS" == arch ]] && [[ -d "$END4DOTS" ]]; then
  log "Updating end4dots"

  cd "$END4DOTS"

  # ensure upstream remote exists
  git remote get-url upstream >/dev/null 2>&1 || \
    git remote add upstream https://github.com/end-4/dots-hyprland.git

  # stash any uncommitted work on archer
  STASHED=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git stash push -q -m "update.sh auto-stash"
    STASHED=true
  fi

  # 1. bring main up to upstream
  git checkout main -q
  git fetch upstream -q
  git rebase upstream/main || {
    log "Rebase conflict on main — manual fix required"
    git rebase --abort 2>/dev/null || true
    git checkout archer -q
    exit 1
  }
  git push origin main --force -q || true
  log "main synced to upstream"

  # 2. rebase archer onto updated main
  git checkout archer -q
  git rebase main || {
    log "Rebase conflict on archer — manual fix required (run: git rebase --continue after resolving)"
    exit 1
  }
  git push origin archer --force -q || true
  log "archer rebased onto main"

  # restore stash if we stashed anything
  $STASHED && git stash pop -q || true

  # run setup from archer (your working branch)
  "$END4DOTS/setup" install
fi

log "Restowing for $OS"
apply_stow_overlays "$OS"
apply_home_manager "$OS"
