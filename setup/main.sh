#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

main() {
  local os="${1:-auto}"

  if [[ "$os" == auto ]]; then
    os=$(detect_os)
  fi

  case "$os" in
    arch|wsl|ubuntu) ;;
    *)
      die "Usage: $0 [auto|arch|wsl|ubuntu]"
      ;;
  esac

  install_system_pkgs "$os"
  apply_stow_overlays "$os"
  apply_home_manager "$os"
  hyprctl reload

  log "Setup complete for $os!"
}

main "$@"
