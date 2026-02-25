#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

log() { printf "==> %s\n" "$1"; }

is_wsl() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || \
    grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null
}

main() {
  if [[ ! -f /etc/os-release ]]; then
    log "Cannot detect OS: /etc/os-release not found"
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release

  if is_wsl; then
    log "Detected WSL"
    exec "$DOTFILES_ROOT/setup/wsl_ubuntu_setup.sh"
  fi

  case "${ID:-}" in
    arch)
      log "Detected Arch Linux"
      exec "$DOTFILES_ROOT/setup/arch_linux_setup.sh"
      ;;
    ubuntu|debian)
      log "Detected Ubuntu/Debian"
      exec "$DOTFILES_ROOT/setup/wsl_ubuntu_setup.sh"
      ;;
    *)
      log "Unsupported OS: ${ID:-unknown}"
      exit 1
      ;;
  esac
}

main "$@"
