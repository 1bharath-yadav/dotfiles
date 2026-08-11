#!/usr/bin/env bash
# claude-dispatch.sh
# Dispatches Claude profiles for daily hisual development & optimization.
#
# Account Mapping (excludes byadhav):
#   1. iitm:         Analysis & Planning             -> hisual-1.prompt.md
#   2. bat:          Phase 1 Implementation (1/3)    -> hisual-2.prompt.md
#   3. bharath9014:  Phase 2 Implementation (2/3)    -> hisual-3.prompt.md
#   4. bharathy723:  Phase 3 Implementation (3/3)    -> hisual-4.prompt.md
#   5. bharathy798:  Compression & Quality Refactor  -> hisual-5.prompt.md
#
# Execution:
#   - Launches profile binary, waits 5s for initial load
#   - Copies full prompt to clipboard via wl-copy
#   - Pastes full prompt via Ctrl+V and submits with Enter
#   - "all" mode runs 1 account every 10 minutes (600s interval)

set -euo pipefail

PROMPTS_DIR="${HOME}/til/spaces/prompts"
PROJECT_DIR="${HOME}/projects/hisual"

declare -A PROFILES=(
  [1]="iitm"
  [2]="bat"
  [3]="bharath9014"
  [4]="bharathy723"
  [5]="bharathy798"
)

declare -A PROMPT_FILES=(
  [1]="${PROMPTS_DIR}/hisual-1.prompt.md"
  [2]="${PROMPTS_DIR}/hisual-2.prompt.md"
  [3]="${PROMPTS_DIR}/hisual-3.prompt.md"
  [4]="${PROMPTS_DIR}/hisual-4.prompt.md"
  [5]="${PROMPTS_DIR}/hisual-5.prompt.md"
)

init_prompts() {
  mkdir -p "$PROMPTS_DIR"

  # 1. Analysis & Planning Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-1.prompt.md"
Project: /home/archer/projects/hisual.
Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Review:
1. CLAUDE.md — operating protocol and production standards.
2. AGENTS.md — architecture, schema contracts, and verification commands.
3. hisuality/vision.md — product vision and roadmap.
4. hisuality/plan.md — active staging area and open ideas.

Task:
1. Deeply analyze both backend (apps/api) and frontend (apps/web) codebases.
2. Formulate concise, effective, and correct improvements, fixes, and feature developments.
3. Create /home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md in the project root with 3 clear implementation sections and optimization goals:
   - Part 1 of 3: Core Foundation & Feature Implementation (First 1/3)
   - Part 2 of 3: Feature Expansion & Integration (Second 1/3)
   - Part 3 of 3: Advanced Polish & Capabilities (Third 1/3)
   - Part 4: Code Compression, Deduplication & Optimization Targets
4. Write/refresh the implementation prompts in /home/archer/til/spaces/prompts/ (hisual-2.prompt.md, hisual-3.prompt.md, hisual-4.prompt.md, hisual-5.prompt.md) using cat > commands, ensuring each prompt contains "Use desktop-commander and filesystem tools only."
5. Execute Part 1 of 3, run verification commands (pytest apps/api/tests, pnpm --filter @hisual/web build, content-linter), commit changes locally with git (never push).
6. Brainstorm new ideas and append next-day plans to ## 2. Open Ideas & Brainstorming Staging in hisuality/plan.md.
EOF

  # 2. Phase 1 Implementation Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-2.prompt.md"
Project: /home/archer/projects/hisual.
Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Review:
1. CLAUDE.md — operating protocol and production standards.
2. AGENTS.md — architecture, schema contracts, and verification commands.
3. /home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md — master plan.
4. hisuality/plan.md — active staging area and open ideas.

Task:
1. Read ## Part 1 of 3: Core Foundation & Feature Implementation (First 1/3) in brainstorm-concise-effective-code-correct.md.
2. Implement all tasks in Part 1 across apps/api and apps/web with clean, concise, strictly-typed code.
3. Ensure no fabricated data (lib/progress.ts for progress, KaTeX for math).
4. Run verification commands:
   - Backend: apps/api/.venv/bin/pytest apps/api/tests
   - Frontend: pnpm --filter @hisual/web build
   - Content: python3 tools/content-linter/bin/content-linter.py (if content modified)
5. Commit locally with git (never push).
6. Append brainstormed ideas and next-day suggestions to ## 2. Open Ideas & Brainstorming Staging in hisuality/plan.md.
EOF

  # 3. Phase 2 Implementation Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-3.prompt.md"
Project: /home/archer/projects/hisual.
Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Review:
1. CLAUDE.md — operating protocol and production standards.
2. AGENTS.md — architecture, schema contracts, and verification commands.
3. /home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md — master plan.
4. hisuality/plan.md — active staging area and open ideas.

Task:
1. Read ## Part 2 of 3: Feature Expansion & Integration (Second 1/3) in brainstorm-concise-effective-code-correct.md and review recent git commits.
2. Implement all tasks in Part 2 across apps/api and apps/web with high quality and robust error handling.
3. Ensure no fabricated data (lib/progress.ts for progress, KaTeX for math).
4. Run verification commands:
   - Backend: apps/api/.venv/bin/pytest apps/api/tests
   - Frontend: pnpm --filter @hisual/web build
   - Content: python3 tools/content-linter/bin/content-linter.py (if content modified)
5. Commit locally with git (never push).
6. Append brainstormed ideas and next-day suggestions to ## 2. Open Ideas & Brainstorming Staging in hisuality/plan.md.
EOF

  # 4. Phase 3 Implementation Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-4.prompt.md"
Project: /home/archer/projects/hisual.
Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Review:
1. CLAUDE.md — operating protocol and production standards.
2. AGENTS.md — architecture, schema contracts, and verification commands.
3. /home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md — master plan.
4. hisuality/plan.md — active staging area and open ideas.

Task:
1. Read ## Part 3 of 3: Advanced Polish & Capabilities (Third 1/3) in brainstorm-concise-effective-code-correct.md and review recent git commits.
2. Implement all tasks in Part 3 across apps/api and apps/web to complete the feature slice.
3. Ensure full end-to-end functionality, responsive styling, and strict types.
4. Run verification commands:
   - Backend: apps/api/.venv/bin/pytest apps/api/tests
   - Frontend: pnpm --filter @hisual/web build
   - Content: python3 tools/content-linter/bin/content-linter.py (if content modified)
5. Commit locally with git (never push).
6. Append brainstormed ideas and next-day suggestions to ## 2. Open Ideas & Brainstorming Staging in hisuality/plan.md.
EOF

  # 5. Compression & Quality Refactor Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-5.prompt.md"
Project: /home/archer/projects/hisual.
Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Review:
1. CLAUDE.md — operating protocol and production standards.
2. AGENTS.md — architecture, verification commands, and Code Optimization Rule:
   "For every iteration, try to reduce the code without losing performance, effectiveness, or efficiency. Always seek to refactor and simplify."
3. /home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md — master plan (Part 4).
4. hisuality/plan.md — active staging area and open ideas.

Task:
1. Review all recent commits and code changes across apps/web and apps/api.
2. Audit codebase for duplicate helper functions, redundant imports, unused variables, verbose abstractions, and repeated inline styles.
3. Refactor and compress code to be cleaner, tighter, and simpler while strictly preserving 100% of functionality, UX, and test coverage.
4. Run complete verification:
   - Backend: apps/api/.venv/bin/pytest apps/api/tests
   - Frontend: pnpm --filter @hisual/web build
   - Content: python3 tools/content-linter/bin/content-linter.py
5. Commit locally with git (never push).
6. Consolidate final brainstormed notes and clear next-day plans under ## 2. Open Ideas & Brainstorming Staging in hisuality/plan.md.
EOF
}

dispatch_account() {
  local idx="$1"
  local profile="${PROFILES[$idx]}"
  local prompt_file="${PROMPT_FILES[$idx]}"

  if [ ! -f "$prompt_file" ]; then
    init_prompts
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

  # Copy full prompt text to clipboard
  wl-copy < "$prompt_file"

  # Paste full prompt (Ctrl+V) and submit (Enter)
  ydotool key 29:1 47:1 47:0 29:0
  sleep 1
  ydotool key 28:1 28:0

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile ${profile} dispatched."
}

show_help() {
  echo "Usage: claude-dispatch.sh [1|2|3|4|5|all|init]"
  echo "  1-5   Dispatch a specific profile (1=iitm, 2=bat, 3=bharath9014, 4=bharathy723, 5=bharathy798)"
  echo "  all   Dispatch all 5 profiles sequentially (1 every 10 minutes, default)"
  echo "  init  Initialize/refresh all prompt files in ${PROMPTS_DIR}"
}

# Ensure prompts are initialized
init_prompts

TARGET="${1:-all}"

case "$TARGET" in
  1|2|3|4|5)
    dispatch_account "$TARGET"
    ;;
  init)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All 5 prompt files refreshed in ${PROMPTS_DIR}."
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
