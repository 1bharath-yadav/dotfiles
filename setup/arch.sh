#!/usr/bin/env bash
# setup/arch.sh — Arch Linux full setup
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

# ── pacman base bootstrap ──────────────────────────────────────────────────
install_base() {
  log "Bootstrapping base packages"
  sudo pacman -Syu --needed --noconfirm base-devel curl git jq stow zsh
}

# ── pacman packages from pkgs.json ────────────────────────────────────────
install_pacman_pkgs() {
  require_cmd jq
  log "Installing official packages"
  # Merge common + arch.official, skip anything also in arch.aur
  mapfile -t official < <(jq -r '.common[].name, .arch.official[].name' "$PKGS_JSON")
  mapfile -t aur      < <(jq -r '.arch.aur[].name' "$PKGS_JSON")

  local pkgs=()
  for p in "${official[@]}"; do
    printf '%s\n' "${aur[@]}" | grep -qx "$p" || pkgs+=("$p")
  done

  # dedup and install
  local deduped
  deduped=$(printf '%s\n' "${pkgs[@]}" | awk '!seen[$0]++')
  [[ -n "$deduped" ]] && printf '%s\0' $deduped | \
    xargs -0 sudo pacman -S --needed --noconfirm
}

# ── yay ───────────────────────────────────────────────────────────────────
ensure_yay() {
  has_cmd yay && return
  log "Installing yay"
  local tmp; tmp=$(mktemp -d)
  git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm --needed)
  rm -rf "$tmp"
}

# ── AUR packages ──────────────────────────────────────────────────────────
install_aur_pkgs() {
  require_cmd jq; ensure_yay
  log "Installing AUR packages"
  mapfile -t pkgs < <(jq -r '.arch.aur[].name' "$PKGS_JSON")
  [[ ${#pkgs[@]} -gt 0 ]] && \
    printf '%s\0' "${pkgs[@]}" | xargs -0 yay -S --needed --noconfirm
}

# ── fnm (node version manager) ────────────────────────────────────────────
install_fnm() {
  has_cmd fnm && return
  log "Installing fnm"
  curl -fsSL https://fnm.vercel.app/install | bash
}

main() {
  require_cmd sudo
  install_base
  install_omz
  install_pacman_pkgs
  install_aur_pkgs
  install_fnm
  install_npm_globals
  set_zsh_default
  log "Stowing dotfiles"
  source "$DOTFILES/stow/arch.sh"
  install_yazi_pkgs
  log "Arch setup complete!"
}

main "$@"
