#!/usr/bin/env bash
set -euo pipefail
VAULT="/home/archer/Sync/obsidian_vault/til"
NOW=$(date +%s)
HOUR=$(date +%H)
TODAY=$(date +%Y-%m-%d)

alert() {
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN:-}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID:-}" \
    -d "parse_mode=Markdown" \
    -d "text=🚨 *HEALTH*: $1" > /dev/null 2>&1 || true
}

source /home/archer/.config/nanobot/.env 2>/dev/null || true

# 1. Services alive?
systemctl --user is-active --quiet nanobot \
  || alert "nanobot.service DOWN — run: systemctl --user start nanobot"

# 2. Heartbeat: output in last 3h? (skip 22:00-07:00)
if [[ "$HOUR" -ge 7 && "$HOUR" -lt 22 ]]; then
  LAST_HEARTBEAT=$(find "$VAULT/wiki/heartbeat" -name "*.md" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -f1 -d".")
  if [[ -n "$LAST_HEARTBEAT" ]]; then
    DIFF=$((NOW - LAST_HEARTBEAT))
    if [[ $DIFF -gt 10800 ]]; then
      alert "No heartbeat in > 3h! Check logs."
    fi
  else
    alert "No heartbeat files found."
  fi
fi

echo "Health check completed."
