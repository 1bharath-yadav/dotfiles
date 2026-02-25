#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PKGS_JSON="$DOTFILES_ROOT/pkgs.json"

log() { printf "==> %s\n" "$1"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_pacman_base() {
  log "Updating system and installing base tools"
  sudo pacman -Syu --needed \
    base-devel \
    curl \
    git \
    jq \
    stow \
    zsh
}

install_pacman_pkgs() {
  require_cmd jq

  log "Installing Arch official packages from pkgs.json"
  mapfile -t OFFICIAL_PKGS < <(jq -r '.official[].name' "$PKGS_JSON")
  if [[ "${#OFFICIAL_PKGS[@]}" -gt 0 ]]; then
    printf '%s\0' "${OFFICIAL_PKGS[@]}" | xargs -0 -r sudo pacman -S --needed
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  log "Installing yay (AUR helper)"
  local tmpdir
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --needed)
}

install_aur_pkgs() {
  require_cmd jq
  ensure_yay

  log "Installing AUR packages from pkgs.json"
  mapfile -t AUR_PKGS < <(jq -r '.aur[].name' "$PKGS_JSON")
  if [[ "${#AUR_PKGS[@]}" -gt 0 ]]; then
    printf '%s\0' "${AUR_PKGS[@]}" | xargs -0 -r yay -S --needed
  fi
}

install_npm_globals() {
  log "Installing npm globals"

  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found; installing nodejs + npm"
    sudo pacman -S --needed nodejs npm
  fi

  local npm_prefix="$HOME/.npm-global"
  mkdir -p "$npm_prefix"
  npm config set prefix "$npm_prefix"

  npm install -g \
    @bitwarden/cli \
    @marp-team/marp-cli \
    @openai/codex \
    htmlhint \
    openclaw \
    promptfoo \
    reveal.js \
    vercel
}

main() {
  require_cmd sudo
  install_pacman_base
  install_oh_my_zsh
  install_pacman_pkgs
  install_aur_pkgs
  install_npm_globals

  log "Linking dotfiles"
  "$DOTFILES_ROOT/stow/arch_linux_stow.sh"
}

main "$@"
