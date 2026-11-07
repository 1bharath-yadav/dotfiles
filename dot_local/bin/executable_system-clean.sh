#!/usr/bin/env bash
# system-clean.sh — Integrated canonical system cleanup for Arch Linux + Omarchy
# Powered by linux-agent clean engine
set -euo pipefail

# Ensure linux-agent is discoverable
if command -v linux-agent >/dev/null 2>&1; then
  CLEANER="linux-agent"
elif [[ -x "$HOME/.local/bin/linux-agent" ]]; then
  CLEANER="$HOME/.local/bin/linux-agent"
else
  CLEANER="$HOME/.dotfiles/dot_local/bin/executable_linux-agent"
fi

# Detect execution context
if [[ $# -eq 0 ]]; then
  if [[ -t 0 ]]; then
    # Interactive terminal: prompt per category
    exec "$CLEANER" clean --interactive
  else
    # Non-interactive / AI agent caller: dry-run summary
    exec "$CLEANER" clean --summary
  fi
else
  # Forward explicit flags (--dry-run, --summary, --json, --interactive, etc.)
  exec "$CLEANER" clean "$@"
fi
