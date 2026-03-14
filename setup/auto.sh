#!/usr/bin/env bash
# setup/auto.sh — detect OS and delegate to the right setup script
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

main() {
  local os; os=$(detect_os)
  log "Detected OS: $os"
  exec "$DOTFILES/setup/${os}.sh"
}

main "$@"
