#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  setup/main.sh bootstrap <arch|wsl|termux>
  setup/main.sh apply <pacman|home|system|external|all> [os]
  setup/main.sh update [os]
EOF
}

cmd_bootstrap() {
  local os="${1:-}"
  [[ -n "$os" ]] || { usage; exit 1; }

  case "$os" in
    termux)
      exec bash "$DOTFILES/setup/termux/bootstrap.sh"
      ;;
    arch|wsl|ubuntu)
      install_bootstrap_packages "$os"
      install_nix_if_missing
      apply_component home "$os"
      ;;
    *) die "Unsupported bootstrap target: $os" ;;
  esac
}

cmd_apply() {
  local target="${1:-all}"
  local os="${2:-auto}"
  apply_component "$target" "$os"
}

cmd_update() {
  local os="${1:-auto}"
  overall_update "$os"
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    bootstrap) cmd_bootstrap "$@" ;;
    apply)     cmd_apply "$@" ;;
    update)    cmd_update "$@" ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
