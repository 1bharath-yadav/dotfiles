#!/usr/bin/env bash
# setup/auto.sh — detect OS and run the unified setup entry
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DOTFILES/setup/main.sh" auto "$@"
