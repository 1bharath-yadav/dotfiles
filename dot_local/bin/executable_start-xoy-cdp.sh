#!/usr/bin/env bash
set -euo pipefail

BROWSER="/usr/bin/google-chrome-stable"
PROFILE="${CDP_CHROME_PROFILE:-$HOME/.config/xoy}"
PORT="${CDP_CHROME_PORT:-9222}"

[[ -x "$BROWSER" ]] || exit 1
mkdir -p "$PROFILE"

if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  exit 0
fi

FLAGS=(
  --user-data-dir="$PROFILE"
  --remote-debugging-port="$PORT"
  --no-first-run
  --no-default-browser-check
)

if [[ "${CDP_HEADLESS:-0}" == "1" || "${XOY_HEADLESS:-0}" == "1" || "${1:-}" == "--headless" ]]; then
  FLAGS+=(
    --headless=new
    --use-fake-ui-for-media-stream
    --window-size=1920,1080
    --disable-blink-features=AutomationControlled
    --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36"
  )
fi

exec "$BROWSER" "${FLAGS[@]}"
