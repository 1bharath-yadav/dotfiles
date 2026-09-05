#!/usr/bin/env bash
set -euo pipefail

BROWSER="/usr/bin/google-chrome-stable"
PROFILE="$HOME/.config/xoy"
PORT="9222"

[[ -x "$BROWSER" ]] || exit 1
mkdir -p "$PROFILE"

if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  exit 0
fi

exec "$BROWSER" \
  --user-data-dir="$PROFILE" \
  --remote-debugging-port="$PORT" \
  --no-first-run \
  --no-default-browser-check
