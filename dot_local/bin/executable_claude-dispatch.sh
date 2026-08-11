#!/usr/bin/env bash
# claude-dispatch.sh
# Dispatches 5 Claude Desktop accounts for daily hisual development & optimization.
#
# Account Mapping (excludes byadhav):
#   1. iitm:         Analyser (Reads repo, writes master plan & prompts) -> hisual-analyser.prompt.md
#   2. bat:          Worker 1 (First 1/3 Implementation)               -> hisual-worker-1.prompt.md
#   3. bharath9014:  Worker 2 (Second 1/3 Implementation)              -> hisual-worker-2.prompt.md
#   4. bharathy723:  Worker 3 (Third 1/3 Implementation)               -> hisual-worker-3.prompt.md
#   5. bharathy798:  Worker 4 (Code Compression & Redundancy Removal)  -> hisual-worker-4.prompt.md
#
# Execution:
#   - Launches profile binary, waits 5s for full initial load
#   - Injects pointer prompt via ydotool, presses Enter
#   - "all" mode runs 1 account every 10 minutes (600s interval) across all 5 accounts

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

declare -A ROLES=(
  [1]="Analyser"
  [2]="Worker 1 (First 1/3)"
  [3]="Worker 2 (Second 1/3)"
  [4]="Worker 3 (Third 1/3)"
  [5]="Worker 4 (Compressor & Optimizer)"
)

declare -A PROMPT_FILES=(
  [1]="${PROMPTS_DIR}/hisual-analyser.prompt.md"
  [2]="${PROMPTS_DIR}/hisual-worker-1.prompt.md"
  [3]="${PROMPTS_DIR}/hisual-worker-2.prompt.md"
  [4]="${PROMPTS_DIR}/hisual-worker-3.prompt.md"
  [5]="${PROMPTS_DIR}/hisual-worker-4.prompt.md"
)

init_prompts() {
  mkdir -p "$PROMPTS_DIR"

  # 1. Analyser Prompt
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-analyser.prompt.md"
# hisual — Analyser Prompt

You are **Analyser** for `hisual`.
You run as an autonomous Claude session.
Project Root: `/home/archer/projects/hisual`

---

## Operating Protocol & Rules

**CRITICAL**: Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Before starting, review:
1. `CLAUDE.md` — operating protocol, tool rules, and production-grade bar.
2. `AGENTS.md` — architecture, schema contracts, KaTeX rules, and verification commands.
3. `hisuality/vision.md` — product vision and architectural pillars.
4. `hisuality/plan.md` — active planning staging area and open ideas.

---

## Execution Workflow

### Step 1: Deep Codebase & System Analysis
1. Read `CLAUDE.md`, `AGENTS.md`, `hisuality/vision.md`, `hisuality/plan.md`, and all active plans in `hisuality/implementations_plans/`.
2. Inspect both codebases thoroughly:
   - Backend (`apps/api`): models, routers, services, execution runtimes, test coverage.
   - Frontend (`apps/web`): components, pages, hooks, state, styles, KaTeX integration.
   - Schemas & Tools (`packages/schemas`, `tools/`).
3. Formulate high-impact, concise, effective, and correct improvements, fixes, and feature steps.

### Step 2: Write Master Analysis & Split Plan
Create `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md` in the project root.
Structure the file with clear, concrete, and unambiguous tasks divided into 3 equal implementation slices plus an optimization pass:
- **`# Architecture & Analysis Summary`**: concise breakdown of current codebase health, opportunities, and priorities.
- **`## Part 1 of 3: Core Foundation & Feature Implementation (First 1/3)`**: concrete tasks for Worker 1.
- **`## Part 2 of 3: Feature Expansion & Integration (Second 1/3)`**: concrete tasks for Worker 2.
- **`## Part 3 of 3: Advanced Capabilities & Polish (Third 1/3)`**: concrete tasks for Worker 3.
- **`## Part 4: Code Compression, Deduplication & Optimization Targets`**: targets and guidelines for Worker 4.

### Step 3: Write 4 Worker Prompts using `cat >`
Directly write/update the 4 worker prompts into `/home/archer/til/spaces/prompts/` using `cat >` commands:
1. `/home/archer/til/spaces/prompts/hisual-worker-1.prompt.md`:
   - Instructs Worker 1 to read `brainstorm-concise-effective-code-correct.md` and implement first 1/3 (`## Part 1 of 3`).
   - Must explicitly state: "Use desktop-commander and filesystem tools only."
   - Verifies tests, commits locally with git (NEVER push), and brainstorms ideas/plans to `hisuality/plan.md`.
2. `/home/archer/til/spaces/prompts/hisual-worker-2.prompt.md`:
   - Instructs Worker 2 to read `brainstorm-concise-effective-code-correct.md` and implement second 1/3 (`## Part 2 of 3`).
   - Must explicitly state: "Use desktop-commander and filesystem tools only."
   - Verifies tests, commits locally with git (NEVER push), and brainstorms ideas/plans to `hisuality/plan.md`.
3. `/home/archer/til/spaces/prompts/hisual-worker-3.prompt.md`:
   - Instructs Worker 3 to read `brainstorm-concise-effective-code-correct.md` and implement third 1/3 (`## Part 3 of 3`).
   - Must explicitly state: "Use desktop-commander and filesystem tools only."
   - Verifies tests, commits locally with git (NEVER push), and brainstorms ideas/plans to `hisuality/plan.md`.
4. `/home/archer/til/spaces/prompts/hisual-worker-4.prompt.md`:
   - Instructs Worker 4 to read `brainstorm-concise-effective-code-correct.md` and compress code without losing effectiveness, quality, or features, and remove redundant code/imports/boilerplate across frontend & backend.
   - Must explicitly state: "Use desktop-commander and filesystem tools only."
   - Verifies tests, commits locally with git (NEVER push), and consolidates final plans in `hisuality/plan.md`.

### Step 4: Brainstorm & Update `hisuality/plan.md`
Append your initial brainstormed ideas, discoveries, and next-day suggestions under `## 2. Open Ideas & Brainstorming Staging` in `hisuality/plan.md`.
EOF

  # 2. Worker 1 Prompt (First 1/3)
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-worker-1.prompt.md"
# hisual — Worker 1 (First 1/3 Implementation)

You are **Worker 1 (First 1/3 Implementation)** for `hisual`.
You run as an autonomous Claude session.
Project Root: `/home/archer/projects/hisual`

---

## Operating Protocol & Rules

**CRITICAL**: Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Before starting, review:
1. `CLAUDE.md` — operating protocol and production-grade bar.
2. `AGENTS.md` — architecture, schema contracts, KaTeX rules, and verification commands.
3. `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md` — master roadmap generated by Analyser.
4. `hisuality/plan.md` — active staging area and open ideas.

### Core Working Rules:
- **Filesystem MCP**: use file operations for all reading, writing, and editing.
- **Desktop Commander**: process execution only (running tests, linters, git).
- **Strict Quality**: no fabricated or hard-coded progress numbers; use `lib/progress.ts`. KaTeX for all math rendering.
- **Commit locally**: commit completed work with `git commit -m "feat/fix(worker-1): ..."`. **NEVER push.**

---

## Execution Workflow

### Step 1: Read Master Roadmap
1. Read `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md`.
2. Focus on **`## Part 1 of 3: Core Foundation & Feature Implementation (First 1/3)`**.

### Step 2: Implement Part 1 (First 1/3)
1. Execute all tasks in `## Part 1 of 3` across `apps/api` and `apps/web`.
2. Write concise, effective, modular, and strictly-typed code.

### Step 3: Verification & Local Commit
Run verification commands per `AGENTS.md` §5:
- Backend: `apps/api/.venv/bin/pytest apps/api/tests` (if backend touched)
- Frontend: `pnpm --filter @hisual/web build` (if frontend touched)
- Content: `python3 tools/content-linter/bin/content-linter.py` (if content touched)
Once green, commit locally with git. **Do not push.**

### Step 4: Brainstorm & Update `hisuality/plan.md`
Append new ideas, edge cases, and future plans under `## 2. Open Ideas & Brainstorming Staging` in `hisuality/plan.md`.
EOF

  # 3. Worker 2 Prompt (Second 1/3)
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-worker-2.prompt.md"
# hisual — Worker 2 (Second 1/3 Implementation)

You are **Worker 2 (Second 1/3 Implementation)** for `hisual`.
You run as an autonomous Claude session.
Project Root: `/home/archer/projects/hisual`

---

## Operating Protocol & Rules

**CRITICAL**: Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Before starting, review:
1. `CLAUDE.md` — operating protocol and production-grade bar.
2. `AGENTS.md` — architecture, schema contracts, KaTeX rules, and verification commands.
3. `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md` — master roadmap generated by Analyser.
4. `hisuality/plan.md` — active staging area and open ideas.

### Core Working Rules:
- **Filesystem MCP**: use file operations for all reading, writing, and editing.
- **Desktop Commander**: process execution only (running tests, linters, git).
- **Strict Quality**: no fabricated or hard-coded progress numbers; use `lib/progress.ts`. KaTeX for all math rendering.
- **Commit locally**: commit completed work with `git commit -m "feat/fix(worker-2): ..."`. **NEVER push.**

---

## Execution Workflow

### Step 1: Read Master Roadmap & Prior Commits
1. Read `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md`.
2. Inspect recent commits (`git log -n 3`) to align with Worker 1's work.
3. Focus on **`## Part 2 of 3: Feature Expansion & Integration (Second 1/3)`**.

### Step 2: Implement Part 2 (Second 1/3)
1. Execute all tasks in `## Part 2 of 3`.
2. Ensure clean modularity, strict error handling, and robust integration.

### Step 3: Verification & Local Commit
Run verification commands per `AGENTS.md` §5:
- Backend: `apps/api/.venv/bin/pytest apps/api/tests` (if backend touched)
- Frontend: `pnpm --filter @hisual/web build` (if frontend touched)
- Content: `python3 tools/content-linter/bin/content-linter.py` (if content touched)
Once green, commit locally with git. **Do not push.**

### Step 4: Brainstorm & Update `hisuality/plan.md`
Append new ideas, insights, and next-day suggestions under `## 2. Open Ideas & Brainstorming Staging` in `hisuality/plan.md`.
EOF

  # 4. Worker 3 Prompt (Third 1/3)
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-worker-3.prompt.md"
# hisual — Worker 3 (Third 1/3 Implementation)

You are **Worker 3 (Third 1/3 Implementation)** for `hisual`.
You run as an autonomous Claude session.
Project Root: `/home/archer/projects/hisual`

---

## Operating Protocol & Rules

**CRITICAL**: Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Before starting, review:
1. `CLAUDE.md` — operating protocol and production-grade bar.
2. `AGENTS.md` — architecture, schema contracts, KaTeX rules, and verification commands.
3. `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md` — master roadmap generated by Analyser.
4. `hisuality/plan.md` — active staging area and open ideas.

### Core Working Rules:
- **Filesystem MCP**: use file operations for all reading, writing, and editing.
- **Desktop Commander**: process execution only (running tests, linters, git).
- **Strict Quality**: no fabricated or hard-coded progress numbers; use `lib/progress.ts`. KaTeX for all math rendering.
- **Commit locally**: commit completed work with `git commit -m "feat/fix(worker-3): ..."`. **NEVER push.**

---

## Execution Workflow

### Step 1: Read Master Roadmap & Prior Commits
1. Read `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md`.
2. Inspect recent commits (`git log -n 4`) to align with Workers 1 & 2.
3. Focus on **`## Part 3 of 3: Advanced Capabilities & Polish (Third 1/3)`**.

### Step 2: Implement Part 3 (Third 1/3)
1. Execute all tasks in `## Part 3 of 3`.
2. Complete end-to-end polish, interactive widgets, styling, and data flows.

### Step 3: Verification & Local Commit
Run verification commands per `AGENTS.md` §5:
- Backend: `apps/api/.venv/bin/pytest apps/api/tests` (if backend touched)
- Frontend: `pnpm --filter @hisual/web build` (if frontend touched)
- Content: `python3 tools/content-linter/bin/content-linter.py` (if content touched)
Once green, commit locally with git. **Do not push.**

### Step 4: Brainstorm & Update `hisuality/plan.md`
Append new ideas, edge cases, and future plans under `## 2. Open Ideas & Brainstorming Staging` in `hisuality/plan.md`.
EOF

  # 5. Worker 4 Prompt (Compressor & Optimizer)
  cat << 'EOF' > "${PROMPTS_DIR}/hisual-worker-4.prompt.md"
# hisual — Worker 4 (Code Compression & Redundancy Optimizer)

You are **Worker 4 (Code Compressor & Quality Optimizer)** for `hisual`.
You run as an autonomous Claude session.
Project Root: `/home/archer/projects/hisual`

---

## Operating Protocol & Rules

**CRITICAL**: Use desktop-commander and filesystem tools only. Never cross tool boundaries.

Before starting, review:
1. `CLAUDE.md` — operating protocol and production-grade bar.
2. `AGENTS.md` — architecture, schema contracts, KaTeX rules, and the **Code Optimization Rule**:
   > **CRITICAL**: For every iteration, try to reduce the code without losing performance, effectiveness, or efficiency. Always seek to refactor and simplify.
3. `/home/archer/projects/hisual/brainstorm-concise-effective-code-correct.md` — master roadmap (specifically `## Part 4`).
4. `hisuality/plan.md` — active staging area and open ideas.

### Core Working Rules:
- **Filesystem MCP**: use file operations for all reading, writing, and editing.
- **Desktop Commander**: process execution only (running tests, linters, git).
- **Zero Loss**: do NOT remove features, break contracts, degrade performance, or harm UX. Only remove redundant, duplicated, verbose, or inefficient code.
- **Commit locally**: commit completed work with `git commit -m "refactor/optimize(worker-4): ..."`. **NEVER push.**

---

## Execution Workflow

### Step 1: Code Audit & Redundancy Detection
1. Review all commits and changes introduced today (`git log -n 6`).
2. Read `## Part 4: Code Compression, Deduplication & Optimization Targets` in `brainstorm-concise-effective-code-correct.md`.
3. Scan both `apps/web` and `apps/api`:
   - Detect duplicate helpers, redundant functions, unused imports, dead variables, repeated inline styles/logic.
   - Look for opportunities to consolidate boilerplate while keeping code lean and maintainable.

### Step 2: Perform Code Compression & Refactoring
1. Simplify bloated components and backend routes.
2. Extract common patterns into concise, reusable helpers.
3. Ensure 100% preservation of features, performance, and functionality.

### Step 3: Full Verification & Local Commit
Run the complete test suite to ensure zero regressions:
- Backend: `apps/api/.venv/bin/pytest apps/api/tests`
- Frontend: `pnpm --filter @hisual/web build`
- Content: `python3 tools/content-linter/bin/content-linter.py`
Once verified green, commit locally with git. **Do not push.**

### Step 4: Final Brainstorm & Plan Consolidation in `hisuality/plan.md`
1. Review the full day's work across all workers.
2. Consolidate new brainstormed ideas and clear next-day implementation items under `## 2. Open Ideas & Brainstorming Staging` in `hisuality/plan.md`.
EOF
}

dispatch_account() {
  local idx="$1"
  local profile="${PROFILES[$idx]}"
  local role="${ROLES[$idx]}"
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

  local pointer_text="You are ${role} for hisual. Project: ${PROJECT_DIR}. Use desktop-commander and filesystem tools only. Read ${prompt_file} and execute all instructions."

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launching Account ${idx} (${role} on profile: ${profile})..."
  nohup $bin >/dev/null 2>&1 &
  disown

  # Wait 5 seconds to load fully in initial state
  sleep 5

  ydotool type -- "$pointer_text"
  ydotool key 28:1 28:0
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Account ${idx} (${profile}) dispatched successfully."
}

show_help() {
  echo "Usage: claude-dispatch.sh [1|2|3|4|5|all|init]"
  echo "  1-5   Dispatch a specific account (1=Analyser, 2=Worker1, 3=Worker2, 4=Worker3, 5=Worker4)"
  echo "  all   Dispatch all 5 accounts sequentially, 1 every 10 minutes (default)"
  echo "  init  Initialize/refresh all 5 prompt files in ${PROMPTS_DIR}"
}

# Ensure prompts are initialized
init_prompts

TARGET="${1:-all}"

case "$TARGET" in
  1|2|3|4|5)
    dispatch_account "$TARGET"
    ;;
  analyser|analysis)
    dispatch_account 1
    ;;
  worker-1|w1)
    dispatch_account 2
    ;;
  worker-2|w2)
    dispatch_account 3
    ;;
  worker-3|w3)
    dispatch_account 4
    ;;
  worker-4|w4)
    dispatch_account 5
    ;;
  init)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All 5 prompt files refreshed in ${PROMPTS_DIR}."
    ;;
  all|"")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting hisual 5-account daily run (1 account every 10 minutes)..."
    for acc in 1 2 3 4 5; do
      dispatch_account "$acc"
      if [ "$acc" -lt 5 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Account ${acc} launched. Waiting 10 minutes (600s) before dispatching Account $((acc + 1))..."
        sleep 600
      fi
    done
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All 5 accounts dispatched successfully."
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
