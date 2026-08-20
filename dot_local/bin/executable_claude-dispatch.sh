#!/usr/bin/env bash
# claude-dispatch.sh
# Dispatches Claude Desktop profiles sequentially for hisual tasks.
#
# Modes:
#   1. Sequential 1-to-1 (Default):
#      Scans prompt directory (e.g. coder/ or content-adder/) and assigns
#      each prompt file one-by-one to available Claude profiles.
#   2. Repeat / Broadcast Mode (-r, --repeat):
#      Dispatches a single prompt file repeatedly across all or selected profiles.
#
# Available Profiles:
#   1. iitm
#   2. bat
#   3. bharath9014
#   4. bharathy723
#   5. bharathy798
#   6. byadhav

set -euo pipefail

PROJECT_DIR="${HOME}/projects/hisual"
PROMPTS_BASE="${PROJECT_DIR}/hisuality/prompts/claude-desktop"

declare -a PROFILES=(
  "iitm"
  "bat"
  "bharath9014"
  "bharathy723"
  "bharathy798"
  "byadhav"
)

show_help() {
  cat << 'HELP_EOF'
Usage: claude-dispatch.sh [folder] [target] [options]

Folders (located in hisuality/prompts/claude-desktop/):
  coder          Engineering & codebase optimization prompts (default)
  content-adder  Curriculum planning, concepts, questions & exams prompts
  <custom_path>  Any custom directory containing .md prompt files

Targets (Sequential Mode):
  all            Dispatch all prompt files sequentially (1 every 10 min, default)
  1..N           Dispatch only the Nth prompt file with its assigned profile

Repeat / Broadcast Mode (-r, --repeat):
  -r, --repeat <prompt>      Repeat a specific prompt across multiple accounts/profiles.
                             <prompt> can be a 1-based index (e.g. 3), filename, or file path.
  -p, --profiles <list|all>  Target profile indices (e.g. 1,2,3) or names (e.g. bat,iitm).
                             Default: all profiles (1..6).

Options:
  -i, --interval <sec>       Delay in seconds between profile dispatches (default: 600).
  --delay <sec>              Initial UI load wait time before pasting (default: 5).
  -n, --dry-run              Preview dispatch actions without launching apps or keystrokes.
  -h, --help                 Display this help menu.

Examples:
  # Sequential 1-to-1 mode:
  claude-dispatch.sh coder all
  claude-dispatch.sh content-adder 1

  # Repeat the same prompt across all accounts:
  claude-dispatch.sh content-adder -r 3
  claude-dispatch.sh coder -r 2

  # Repeat a prompt on specific accounts with custom interval:
  claude-dispatch.sh content-adder -r 3 --profiles 1,2,3 --interval 300
  claude-dispatch.sh -r 01-docs-pipeline-and-infra.md -p iitm,bat

  # Dry-run preview:
  claude-dispatch.sh --dry-run content-adder -r 3
HELP_EOF
}

# Defaults
TARGET_FOLDER=""
TARGET_ACTION=""
REPEAT_PROMPT=""
TARGET_PROFILES="all"
INTERVAL=600
UI_DELAY=5
DRY_RUN=false

# Argument Parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help|help)
      show_help
      exit 0
      ;;
    -r|--repeat)
      REPEAT_PROMPT="$2"
      shift 2
      ;;
    --repeat=*)
      REPEAT_PROMPT="${1#*=}"
      shift 1
      ;;
    -p|--profiles|--profile|--accounts|--account)
      TARGET_PROFILES="$2"
      shift 2
      ;;
    --profiles=*|--profile=*|--accounts=*|--account=*)
      TARGET_PROFILES="${1#*=}"
      shift 1
      ;;
    -i|--interval)
      INTERVAL="$2"
      shift 2
      ;;
    --interval=*)
      INTERVAL="${1#*=}"
      shift 1
      ;;
    --delay)
      UI_DELAY="$2"
      shift 2
      ;;
    --delay=*)
      UI_DELAY="${1#*=}"
      shift 1
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift 1
      ;;
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      show_help
      exit 1
      ;;
    *)
      if [ -z "$TARGET_FOLDER" ]; then
        TARGET_FOLDER="$1"
      elif [ -z "$TARGET_ACTION" ]; then
        TARGET_ACTION="$1"
      else
        echo "[ERROR] Unexpected positional argument: $1" >&2
        show_help
        exit 1
      fi
      shift 1
      ;;
  esac
done

# Resolve positional parameters
if [[ "$TARGET_FOLDER" =~ ^[0-9]+$ ]] || [ "$TARGET_FOLDER" = "all" ]; then
  TARGET_ACTION="$TARGET_FOLDER"
  TARGET_FOLDER="coder"
fi

if [ -z "$TARGET_FOLDER" ]; then
  TARGET_FOLDER="coder"
fi

if [ -z "$TARGET_ACTION" ]; then
  TARGET_ACTION="all"
fi

# Resolve Directory
if [ -d "$TARGET_FOLDER" ]; then
  TARGET_DIR="$(cd "$TARGET_FOLDER" && pwd)"
elif [ -d "${PROMPTS_BASE}/${TARGET_FOLDER}" ]; then
  TARGET_DIR="${PROMPTS_BASE}/${TARGET_FOLDER}"
else
  echo "[ERROR] Target folder not found: $TARGET_FOLDER" >&2
  echo "Looked in: ${PROMPTS_BASE}/${TARGET_FOLDER}" >&2
  exit 1
fi

# Discover prompt files
mapfile -t PROMPT_FILES < <(find "$TARGET_DIR" -maxdepth 1 -name "*.md" ! -name "*_bugs.md" ! -iname "AGENTS.md" ! -iname "README.md" | sort)
TOTAL_FILES="${#PROMPT_FILES[@]}"

if [ "$TOTAL_FILES" -eq 0 ] && [ -z "$REPEAT_PROMPT" ]; then
  echo "[ERROR] No prompt files (*.md) found in $TARGET_DIR" >&2
  exit 1
fi

# Helper: Parse target profile list
parse_selected_profiles() {
  local input="$1"
  local -a result=()

  if [ "$input" = "all" ] || [ -z "$input" ]; then
    result=("${PROFILES[@]}")
  else
    local cleaned="${input//,/ }"
    for item in $cleaned; do
      if [[ "$item" =~ ^[0-9]+$ ]]; then
        local p_idx=$((item - 1))
        if [ "$p_idx" -ge 0 ] && [ "$p_idx" -lt "${#PROFILES[@]}" ]; then
          result+=("${PROFILES[$p_idx]}")
        else
          echo "[ERROR] Profile index '$item' out of range (1..${#PROFILES[@]})" >&2
          return 1
        fi
      else
        local found=false
        for prof in "${PROFILES[@]}"; do
          if [ "$prof" = "$item" ]; then
            result+=("$prof")
            found=true
            break
          fi
        done
        if [ "$found" = false ]; then
          echo "[ERROR] Unknown profile name: '$item'" >&2
          echo "Available profiles: ${PROFILES[*]}" >&2
          return 1
        fi
      fi
    done
  fi

  printf '%s\n' "${result[@]}"
}

# Helper: Resolve prompt file path
resolve_prompt_path() {
  local target="$1"

  if [ -f "$target" ]; then
    echo "$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
    return 0
  fi

  if [[ "$target" =~ ^[0-9]+$ ]]; then
    local file_idx=$((target - 1))
    if [ "$file_idx" -ge 0 ] && [ "$file_idx" -lt "$TOTAL_FILES" ]; then
      echo "${PROMPT_FILES[$file_idx]}"
      return 0
    else
      echo "[ERROR] Prompt index '$target' out of range (1..$TOTAL_FILES in $(basename "$TARGET_DIR"))" >&2
      return 1
    fi
  fi

  if [ -f "${TARGET_DIR}/${target}" ]; then
    echo "${TARGET_DIR}/${target}"
    return 0
  elif [ -f "${TARGET_DIR}/${target}.md" ]; then
    echo "${TARGET_DIR}/${target}.md"
    return 0
  fi

  for pf in "${PROMPT_FILES[@]}"; do
    local bname
    bname="$(basename "$pf")"
    if [[ "$bname" == "$target"* ]]; then
      echo "$pf"
      return 0
    fi
  done

  echo "[ERROR] Could not resolve prompt file for '$target' in $TARGET_DIR" >&2
  return 1
}

# Launch and dispatch action
dispatch_single() {
  local profile="$1"
  local prompt_file="$2"
  local step_num="${3:-1}"
  local total_steps="${4:-1}"

  local prompt_name
  prompt_name="$(basename "$prompt_file")"

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

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] [${step_num}/${total_steps}] Would launch profile '${profile}' ($bin)"
    echo "          Prompt file: ${prompt_file}"
    echo "          Actions    : sleep ${UI_DELAY}s -> wl-copy -> ydotool Ctrl+V + Enter"
    return 0
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${step_num}/${total_steps}] Launching profile '${profile}' with '${prompt_name}'..."
  nohup $bin >/dev/null 2>&1 &
  disown

  sleep "$UI_DELAY"

  wl-copy < "$prompt_file"

  ydotool key 29:1 47:1 47:0 29:0
  sleep 1
  ydotool key 28:1 28:0

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile '${profile}' dispatched with '${prompt_name}'."
}

# ==============================================================================
# Execution Mode Branching
# ==============================================================================

if [ -n "$REPEAT_PROMPT" ]; then
  # ----------------------------------------------------------------------------
  # MODE 2: Repeat Same Prompt Across Profiles
  # ----------------------------------------------------------------------------
  CHOSEN_PROMPT_FILE="$(resolve_prompt_path "$REPEAT_PROMPT")"
  mapfile -t SELECTED_PROFILES < <(parse_selected_profiles "$TARGET_PROFILES")

  TOTAL_SELECTED="${#SELECTED_PROFILES[@]}"
  if [ "$TOTAL_SELECTED" -eq 0 ]; then
    echo "[ERROR] No profiles selected." >&2
    exit 1
  fi

  echo "===================================================================="
  echo "Claude Dispatcher: Repeat Prompt Mode"
  echo "===================================================================="
  echo "Prompt File : $(basename "$CHOSEN_PROMPT_FILE")"
  echo "Full Path   : $CHOSEN_PROMPT_FILE"
  echo "Profiles (${TOTAL_SELECTED}) : ${SELECTED_PROFILES[*]}"
  echo "Interval    : ${INTERVAL}s between dispatches"
  echo "Dry Run     : $DRY_RUN"
  echo "===================================================================="
  echo ""

  for ((i=0; i<TOTAL_SELECTED; i++)); do
    step=$((i + 1))
    prof="${SELECTED_PROFILES[$i]}"
    dispatch_single "$prof" "$CHOSEN_PROMPT_FILE" "$step" "$TOTAL_SELECTED"

    if [ "$step" -lt "$TOTAL_SELECTED" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would wait ${INTERVAL}s before next profile..."
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile '$prof' launched. Waiting ${INTERVAL}s before dispatching next profile..."
        sleep "$INTERVAL"
      fi
    fi
  done

  echo ""
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Repeat dispatch completed across all $TOTAL_SELECTED profiles."

else
  # ----------------------------------------------------------------------------
  # MODE 1: Sequential 1-to-1 Prompt Dispatch
  # ----------------------------------------------------------------------------
  echo "Target prompt directory: $TARGET_DIR ($TOTAL_FILES prompt files found)"
  for i in "${!PROMPT_FILES[@]}"; do
    p_idx=$((i + 1))
    f_name="$(basename "${PROMPT_FILES[$i]}")"
    prof="${PROFILES[$((i % ${#PROFILES[@]}))]}"
    echo "  [${p_idx}] ${f_name} -> profile: ${prof}"
  done
  echo ""

  case "$TARGET_ACTION" in
    all|"")
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sequential dispatch (1 prompt every ${INTERVAL}s)..."
      for ((idx=1; idx<=TOTAL_FILES; idx++)); do
        file_idx=$((idx - 1))
        p_file="${PROMPT_FILES[$file_idx]}"
        prof="${PROFILES[$((file_idx % ${#PROFILES[@]}))]}"

        dispatch_single "$prof" "$p_file" "$idx" "$TOTAL_FILES"

        if [ "$idx" -lt "$TOTAL_FILES" ]; then
          if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would wait ${INTERVAL}s before next prompt..."
          else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Prompt $idx dispatched. Waiting ${INTERVAL}s before dispatching next prompt..."
            sleep "$INTERVAL"
          fi
        fi
      done
      echo ""
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] All $TOTAL_FILES prompts dispatched successfully."
      ;;
    [0-9]*)
      file_idx=$((TARGET_ACTION - 1))
      if [ "$file_idx" -lt 0 ] || [ "$file_idx" -ge "$TOTAL_FILES" ]; then
        echo "[ERROR] Invalid index $TARGET_ACTION. Available prompts in $(basename "$TARGET_DIR"): 1..$TOTAL_FILES" >&2
        exit 1
      fi
      p_file="${PROMPT_FILES[$file_idx]}"
      prof="${PROFILES[$((file_idx % ${#PROFILES[@]}))]}"
      dispatch_single "$prof" "$p_file" "1" "1"
      ;;
    *)
      echo "Unknown target action: $TARGET_ACTION" >&2
      show_help
      exit 1
      ;;
  esac
fi
