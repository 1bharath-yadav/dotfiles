#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$DOTFILES/setup/main.sh" bootstrap "$@"
