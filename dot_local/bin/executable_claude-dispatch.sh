#!/usr/bin/env bash
# claude-dispatch.sh
# Dispatches Claude Desktop profiles with pointer prompts for hisual daily development.
#
# Profiles and Prompts:
#   Worker 1 (bat):         Analyser & 1st 1/3 Implementation -> hisual-worker-1.prompt.md
#   Worker 2 (bharath9014): 2nd 1/3 Implementation            -> hisual-worker-2.prompt.md
#   Worker 3 (bharathy723): 3rd 1/3 Implementation            -> hisual-worker-3.prompt.md
#   Worker 4 (bharathy798): Compression & Optimization        -> hisual-worker-4.prompt.md
#
# Usage:
#   claude-dispatch.sh        # Dispatches all 4 workers sequentially with stagger
#   claude-dispatch.sh all    # Dispatches all 4 workers sequentially
#   claude-dispatch.sh 1      # Dispatches only Worker 1
#   claude-dispatch.sh 2      # Dispatches only Worker 2
#   claude-dispatch.sh 3      # Dispatches only Worker 3
#   claude-dispatch.sh 4      # Dispatches only Worker 4

set -euo pipefail

PROMPTS_DIR="${HOME}/til/spaces/prompts"
PROJECT_DIR="${HOME}/projects/hisual"

# Worker mapping: index -> profile:prompt_file
declare -A WORKER_PROFILES=(
  [1]="bat"
  [2]="bharath9014"
  [3]="bharathy723"
  [4]="bharathy798"
)

declare -A WORKER_PROMPTS=(
  [1]="${PROMPTS_DIR}/hisual-worker-1.prompt.md"
  [2]="${PROMPTS_DIR}/hisual-worker-2.prompt.md"
  [3]="${PROMPTS_DIR}/hisual-worker-3.prompt.md"
  [4]="${PROMPTS_DIR}/hisual-worker-4.prompt.md"
)

dispatch_worker() {
  local idx="$1"
  local profile="${WORKER_PROFILES[$idx]}"
  local prompt_file="${WORKER_PROMPTS[$idx]}"

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

  local pointer_text="You are hisual Developer Worker ${idx}. Project: ${PROJECT_DIR}. Read ${prompt_file} and execute all instructions."

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launching Worker ${idx} (profile: ${profile})..."
  nohup $bin >/dev/null 2>&1 &
  disown

  sleep 6
  ydotool type -- "$pointer_text"
  ydotool key 28:1 28:0
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Worker ${idx} dispatched successfully."
}

show_help() {
  echo "Usage: claude-dispatch.sh [1|2|3|4|all]"
  echo "  1-4   Dispatch a specific worker"
  echo "  all   Dispatch all 4 workers sequentially (default)"
}

TARGET="${1:-all}"

case "$TARGET" in
  1|2|3|4)
    dispatch_worker "$TARGET"
    ;;
  all|"")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting hisual 4-worker daily dispatch sequence..."
    for w in 1 2 3 4; do
      dispatch_worker "$w"
      if [ "$w" -lt 4 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Waiting 10s before dispatching next worker..."
        sleep 10
      fi
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All 4 workers dispatched."
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
