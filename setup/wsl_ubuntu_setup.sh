#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PKGS_JSON="$DOTFILES_ROOT/pkgs.json"

log() { printf "==> %s\n" "$1"; }

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Oh My Zsh already installed"
    return
  fi

  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

apt_has() {
  apt-cache show "$1" >/dev/null 2>&1
}

install_apt_pkgs() {
  log "Updating apt metadata"
  sudo apt-get update -y

  # Ensure jq exists for reading pkgs.json.
  if ! command -v jq >/dev/null 2>&1; then
    log "Installing jq for pkgs.json parsing"
    sudo apt-get install -y jq
  fi

  # Load common + ubuntu.apt packages from pkgs.json.
  mapfile -t wanted_from_pkgs_json < <(jq -r '.common[].name, .ubuntu.apt[].name' "$PKGS_JSON")

  # Map Arch names to Ubuntu package names when they differ.
  declare -A map=(
    [fd]=fd-find
    [python-pip]=python3-pip
  )

  local apt_pkgs=()
  for name in "${wanted_from_pkgs_json[@]}"; do
    local pkg="${map[$name]:-$name}"
    if apt_has "$pkg"; then
      apt_pkgs+=("$pkg")
    else
      log "Skipping unavailable apt package: $pkg"
    fi
  done

  # Minimal tools needed to bootstrap (curl/git/zsh) even if not in pkgs.json.
  for pkg in curl git zsh; do
    if apt_has "$pkg"; then
      apt_pkgs+=("$pkg")
    fi
  done

  if [[ "${#apt_pkgs[@]}" -gt 0 ]]; then
    log "Installing Ubuntu packages"
    sudo apt-get install -y "${apt_pkgs[@]}"
  fi
}

install_npm_globals() {
  log "Installing npm globals"

  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found; installing nodejs + npm"
    sudo apt-get install -y nodejs npm
  fi

  local npm_prefix="$HOME/.npm-global"
  mkdir -p "$npm_prefix"
  npm config set prefix "$npm_prefix"

  mapfile -t NPM_PKGS < <(jq -r '.npm[].name' "$PKGS_JSON")
  if [[ "${#NPM_PKGS[@]}" -gt 0 ]]; then
    npm install -g "${NPM_PKGS[@]}"
  fi
}

main() {
  install_apt_pkgs
  install_oh_my_zsh
  install_npm_globals

  log "Linking dotfiles"
  "$DOTFILES_ROOT/stow/wsl_ubuntu_stow.sh"
}

main "$@"
