#!/usr/bin/env bash
# Ensures ~/.agents points at ~/.dotfiles/agents, per the bootstrap step in
# setup/linux.md ("ln -s ~/.dotfiles/agents ~/.agents"). New machines that
# skipped/forgot that manual step get fixed up here instead.
# Idempotent: no-op if the symlink already exists and points at the right place.
set -euo pipefail

target="$HOME/.dotfiles/agents"
link="$HOME/.agents"

if [[ -L "$link" ]] && [[ "$(readlink -f "$link")" == "$(readlink -f "$target")" ]]; then
  exit 0
fi

if [[ -e "$link" && ! -L "$link" ]]; then
  echo "[migrate] $link exists and is not a symlink — skipping, resolve manually" >&2
  exit 0
fi

ln -sfn "$target" "$link"
echo "[migrate] linked $link -> $target"
