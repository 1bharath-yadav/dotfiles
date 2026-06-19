#!/usr/bin/env bash
set -euo pipefail

MSG="${1:-agent: auto commit}"
VAULT="/home/archer/Sync/obsidian_vault/til"

cd "$VAULT" || exit 1
git add -A

# Check if there are changes
if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git commit -m "$MSG"
echo "Committed: $MSG"

# Ensure changes are pushed to remote backing to prevent data loss
git push origin current-state || true
