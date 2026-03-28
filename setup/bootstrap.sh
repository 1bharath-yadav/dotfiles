#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

install_nix_if_missing() {
  if has_cmd nix; then
    log "Nix already installed"
    return
  fi

  require_cmd curl
  log "Installing Nix"
  bash -lc 'curl -L https://nixos.org/nix/install | sh -s -- --daemon'
}

bootstrap_android() {
  if ! has_cmd nix-on-droid; then
    die "nix-on-droid is not installed. Install the app first, then rerun this script inside the app environment."
  fi

  log "Applying nix-on-droid configuration"
  exec nix-on-droid switch --flake "$DOTFILES#archer-phone"
}

main() {
  local os="${1:?usage: $0 <arch|wsl|android>}"

  case "$os" in
    arch|wsl)
      install_nix_if_missing
      exec "$DOTFILES/setup/main.sh" "$os"
      ;;
    android)
      bootstrap_android
      ;;
    *)
      die "Usage: $0 <arch|wsl|android>"
      ;;
  esac
}

main "$@"
