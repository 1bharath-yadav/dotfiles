#!/usr/bin/env bash
set -euo pipefail

# Helper CLI for managing and querying the local OpenCode persistent server
PORT="4096"
BASE_URL="http://127.0.0.1:${PORT}"
ENV_FILE="${HOME}/.config/opencode/server.env"

get_password() {
  if [[ -f "$ENV_FILE" ]]; then
    grep -E '^OPENCODE_SERVER_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'"
  else
    echo ""
  fi
}

auth_curl() {
  local pass
  pass="$(get_password)"
  if [[ -n "$pass" ]]; then
    curl -s -u "opencode:${pass}" "$@"
  else
    curl -s "$@"
  fi
}

cmd_status() {
  echo "=== systemd service status ==="
  systemctl --user status opencode-serve.service --no-pager || true
  echo ""
  echo "=== HTTP API check (${BASE_URL}/api/info) ==="
  local res
  res="$(auth_curl -s "${BASE_URL}/api/info" 2>&1 || true)"
  echo "$res"
}

cmd_restart() {
  echo "Restarting opencode-serve.service..."
  systemctl --user restart opencode-serve.service
  sleep 2
  cmd_status
}

cmd_logs() {
  local lines="${1:-50}"
  echo "=== journalctl logs (-n $lines) ==="
  journalctl --user -u opencode-serve.service -n "$lines" --no-pager
}

cmd_api() {
  local method="${1:-GET}"
  local endpoint="${2:-/api/info}"
  shift 2 || true
  local data="${1:-}"

  if [[ -n "$data" ]]; then
    auth_curl -X "$method" "${BASE_URL}${endpoint}" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    auth_curl -X "$method" "${BASE_URL}${endpoint}"
  fi
  echo ""
}

cmd_generate() {
  local prompt="${1:-Hi}"
  local model_id="${2:-antigravity-gemini-3.8-flash-low}"
  local provider="${3:-google}"

  local payload
  payload=$(cat <<EOF
{
  "prompt": $(printf '%s' "$prompt" | jq -R .),
  "model": {
    "providerID": "$provider",
    "id": "$model_id"
  }
}
EOF
)
  auth_curl -X POST "${BASE_URL}/api/experimental/generate/text" \
    -H "Content-Type: application/json" \
    -d "$payload" | jq -r '.data.text // .'
}

usage() {
  cat <<EOF
Usage: opencode-server.sh <command> [args]

Commands:
  status                   Check systemd status and /api/info
  restart                  Restart opencode-serve.service and verify
  logs [lines]             Show recent journalctl logs (default: 50)
  api <METHOD> <PATH> [JSON] Make authenticated call to local API
  generate <prompt> [model] [provider] Run quick stateless text generation
EOF
}

case "${1:-}" in
  status)
    cmd_status
    ;;
  restart)
    cmd_restart
    ;;
  logs)
    shift
    cmd_logs "${1:-50}"
    ;;
  api)
    shift
    cmd_api "$@"
    ;;
  generate)
    shift
    cmd_generate "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
