#!/usr/bin/env bash
# update.sh — idempotent dotfiles refresh
#   • syncs end4dots upstream (Arch only, two-branch strategy)
#   • restows Hyprland/kitty overlays (Arch only)
#   • runs Home Manager switch only when .nix files changed
#   • skips steps safely when dependencies are missing
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
END4DOTS=~/linux/dots-hyprland

source "$DOTFILES/setup/lib.sh"

OS=$(detect_os)
log "OS: $OS"

# ── helpers ────────────────────────────────────────────────────────────────

nix_files_changed() {
  # true when staged/unstaged .nix or flake.lock changes exist vs last HM gen
  local last_gen_commit
  last_gen_commit=$(cat "$HOME/.local/state/home-manager/last-switch" 2>/dev/null || echo "")
  if [[ -z "$last_gen_commit" ]]; then return 0; fi  # no record → rebuild
  git -C "$DOTFILES" diff --name-only HEAD "$last_gen_commit" -- '*.nix' flake.lock \
    | grep -q . 2>/dev/null && return 0 || return 1
}

stamp_hm_switch() {
  mkdir -p "$HOME/.local/state/home-manager"
  git -C "$DOTFILES" rev-parse HEAD > "$HOME/.local/state/home-manager/last-switch" 2>/dev/null || true
}

# ── Phase 1: sync end4dots upstream ────────────────────────────────────────

if [[ "$OS" == arch ]] && [[ -d "$END4DOTS" ]]; then
  log "Syncing end4dots (two-branch: main=upstream mirror, archer=your changes)"

  cd "$END4DOTS"

  git remote get-url upstream >/dev/null 2>&1 || \
    git remote add upstream https://github.com/end-4/dots-hyprland.git

  STASHED=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git stash push -q -m "update.sh auto-stash $(date +%s)"
    STASHED=true
  fi

  # 1a. fast-forward main to upstream
  git checkout main -q
  git fetch upstream -q
  if git rebase upstream/main -q; then
    git push origin main --force -q 2>/dev/null || true
    log "main → upstream synced"
  else
    warn "Rebase conflict on main — aborting; fix manually then re-run"
    git rebase --abort 2>/dev/null || true
    git checkout archer -q
    $STASHED && git stash pop -q || true
    exit 1
  fi

  # 1b. rebase archer onto updated main
  git checkout archer -q
  if git rebase main -q; then
    git push origin archer --force -q 2>/dev/null || true
    log "archer rebased onto main"
  else
    warn "Rebase conflict on archer — resolve then run: git rebase --continue"
    $STASHED && warn "  Stash also pending: git stash pop"
    exit 1
  fi

  $STASHED && git stash pop -q || true

  # 1c. run end4dots setup from your archer branch
  "$END4DOTS/setup" install

  # 1d. end4dots setup cp -f overwrites hyprland.conf, stripping source=custom/env.conf.
  #     Re-copy from archer branch (which has the line) immediately after.
  _hconf="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$_hconf" ]] && ! grep -q 'source=custom/env.conf' "$_hconf"; then
    cp "$END4DOTS/dots/.config/hypr/hyprland.conf" "$_hconf"
    log "Re-patched hyprland.conf with source=custom/env.conf"
  fi

  # 1e. end4dots leaves behind *.new files — clean them up silently
  find "$HOME/.config/hypr" -maxdepth 1 -name '*.new' -delete 2>/dev/null || true
  log "Cleaned up .new files from end4dots install"
fi

# ── Phase 2: restow overlays ───────────────────────────────────────────────
log "Restowing overlays for $OS"
apply_stow_overlays "$OS"

# ── Phase 3: Home Manager — only rebuild when .nix files changed ───────────
if ! has_cmd nix; then
  warn "nix not found — skipping Home Manager switch"
  exit 0
fi

HM_HOST="$(host_name_for_os "$OS")"
if [[ "${NIX_FORCE:-0}" == "1" ]] || nix_files_changed; then
  log "Nix config changed — running home-manager switch"
  enable_nix_flakes
  home-manager switch --flake "$DOTFILES#$HM_HOST" 2>&1 \
    | grep -E '^(=>|activating|error|warning)' || true
  stamp_hm_switch
  log "Home Manager switch complete"
else
  log "No .nix changes since last switch — skipping rebuild (NIX_FORCE=1 to override)"
fi

# ── Phase 4: reload Hyprland config (Arch only, after everything is settled) ──
# end4dots setup install writes hyprland.conf, triggering an inotify reload mid-flight
# before stow has re-linked custom/. Issuing a final explicit reload here ensures
# Hyprland reads the fully settled state (stowed custom/ + patched hyprland.conf).
if [[ "$OS" == arch ]] && has_cmd hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
  hyprctl reload -q
  log "Hyprland config reloaded"
fi

log "Done ✓"
