#!/usr/bin/env bash
# claude-dispatch.sh
# Dispatches Claude profiles for daily hisual development & optimization.
#
# Profiles and Prompts (prewritten in hisuality/prompts/):
#   1. iitm:         Overview & Master Plan         -> hisuality/prompts/overview.md
#   2. bat:          Frontend Optimizer             -> hisuality/prompts/frontend-optimizer.md
#   3. bharath9014:  Backend & Database Optimizer   -> hisuality/prompts/backend-and-database-optimizer.md
#   4. bharathy723:  Code Compression & Research    -> hisuality/prompts/code-compression-and-research.md
#   5. bharathy798:  Production Hardening           -> hisuality/prompts/production-hardening.md
#
# Execution:
#   - Launches profile binary, waits 5s for full initial load
#   - Copies prewritten full prompt to clipboard via wl-copy
#   - Pastes prompt via Ctrl+V and submits with Enter
#   - "all" mode runs 1 profile every 10 minutes (600s interval)

set -euo pipefail

PROJECT_DIR="${HOME}/projects/hisual"
PROMPTS_DIR="${PROJECT_DIR}/hisuality/prompts"

declare -A PROFILES=(
  [1]="iitm"
  [2]="bat"
  [3]="bharath9014"
  [4]="bharathy723"
  [5]="bharathy798"
)

declare -A PROMPT_FILES=(
  [1]="${PROMPTS_DIR}/overview.md"
  [2]="${PROMPTS_DIR}/frontend-optimizer.md"
  [3]="${PROMPTS_DIR}/backend-and-database-optimizer.md"
  [4]="${PROMPTS_DIR}/code-compression-and-research.md"
  [5]="${PROMPTS_DIR}/production-hardening.md"
)

dispatch_account() {
  local idx="$1"
  local profile="${PROFILES[$idx]}"
  local prompt_file="${PROMPT_FILES[$idx]}"

  if [ ! -f "$prompt_file" ]; then
    echo "[ERROR] Prompt file not found: $prompt_file" >&2
    return 1
  fi

  local bin="claude-desktop"
  if command -v "claude-desktop-${profile}" >/dev/null 2>&1; then
    bin="claude-desktop-${profile}"
  elif command -v claude-desktop >/dev/null 2>&1; then
    bin="claude-desktop --profile ${profile}"
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launching profile: ${profile}..."
  nohup $bin >/dev/null 2>&1 &
  disown

  # Wait 5 seconds for full initial load
  sleep 5

  # Copy full prewritten prompt text to clipboard
  wl-copy < "$prompt_file"

  # Paste full prompt (Ctrl+V) and submit (Enter)
  ydotool key 29:1 47:1 47:0 29:0
  sleep 1
  ydotool key 28:1 28:0

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile ${profile} dispatched."
}

show_help() {
  echo "Usage: claude-dispatch.sh [1|2|3|4|5|all]"
  echo "  1     Overview & Master Plan (iitm)"
  echo "  2     Frontend Optimizer (bat)"
  echo "  3     Backend & Database Optimizer (bharath9014)"
  echo "  4     Code Compression & Research (bharathy723)"
  echo "  5     Production Hardening (bharathy798)"
  echo "  all   Dispatch all 5 profiles sequentially (1 every 10 minutes, default)"
}

TARGET="${1:-all}"

case "$TARGET" in
  1|2|3|4|5)
    dispatch_account "$TARGET"
    ;;
  all|"")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting hisual 5-profile sequence (1 profile every 10 minutes)..."
    for acc in 1 2 3 4 5; do
      dispatch_account "$acc"
      if [ "$acc" -lt 5 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile ${acc} launched. Waiting 10 minutes (600s) before dispatching Profile $((acc + 1))..."
        sleep 600
      fi
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All 5 profiles dispatched successfully."
    ;;
  -h|--help|help)
    show_help
    ;;
  *)
    echo "Unknown argument: $TARGET" >&2
    show_help
    exit 1
    ;;
esac
