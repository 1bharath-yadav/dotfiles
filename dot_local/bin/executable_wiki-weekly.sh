#!/usr/bin/env bash
set -euo pipefail

VAULT="/home/archer/Sync/obsidian_vault/til"
DAILY_DIR="$VAULT/wiki/journals/daily"

# Get current Year and Week (e.g. 2026-W15)
WEEK_STR=$(date +%Y-W%V)

# Gather notes modified or created in the last 7 days
TEMP_FILE="/tmp/weekly_raw_$WEEK_STR.md"
find "$DAILY_DIR" -type f -name "*.md" -mtime -7 -exec cat {} + > "$TEMP_FILE"

# Run OpenCode with the Synthesis Agent
opencode run --yes --quiet --cwd "$VAULT" --file "$TEMP_FILE" "$(cat /home/archer/.config/nanobot/prompts/weekly_synthesis_agent.md)"

rm "$TEMP_FILE"

# Log the action
echo "## [$(date '+%Y-%m-%d %H:%M')] ingest | Generated Weekly Synthesis for $WEEK_STR" >> "$VAULT/wiki/log.md"

# Commit
bash /home/archer/dotfiles/dot_local/bin/executable_wiki-commit.sh "Weekly Synthesis Rollup: $WEEK_STR"
