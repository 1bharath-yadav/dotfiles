#!/usr/bin/env bash
# ==============================================================================
# Claude Dispatcher — Automated Multi-Profile Claude Desktop Orchestrator
# Supports:
#   - Direct Profile Targeting (e.g. "claude-dispatch.sh byadhav" or "byadhav36")
#   - Auto Curriculum Queue Mode (dynamic subject/module progress via content-catalog.py)
#   - Repeat / Broadcast Mode (-r, --repeat across all or specific accounts)
#   - Folder Dispatch Mode (coder, content-adder, etc.)
#   - Inline Custom Text Prompt Mode (-t, --text "prompt...")
#   - Single-Task Execution Mode (-1, --one)
#   - Dry-Run Preview Mode (-n, --dry-run)
# ==============================================================================

set -eo pipefail

# ANSI Colors
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
MAGENTA="\033[0;35m"
NC="\033[0m"

PROJECT_ROOT="/home/archer/projects/hisual"
PROMPTS_BASE="${PROJECT_ROOT}/hisuality/prompts/claude-desktop"
ACTIVE_QUEUE_DIR="${PROMPTS_BASE}/active-queue"
CATALOG_TOOL="${PROJECT_ROOT}/tools/content-adder/bin/content-catalog.py"

declare -a PROFILES=(
  "iitm"
  "bat"
  "bharath9014"
  "bharathy723"
  "bharathy798"
  "byadhav"
)

# Helper: normalize profile alias
normalize_profile() {
  local p="$1"
  p="$(echo "$p" | tr "[:upper:]" "[:lower:]" | xargs)"
  case "$p" in
    1|iitm|iit)
      echo "iitm" ;;
    2|bat|batman)
      echo "bat" ;;
    3|bharath9014|9014|bharath)
      echo "bharath9014" ;;
    4|bharathy723|723)
      echo "bharathy723" ;;
    5|bharathy798|798)
      echo "bharathy798" ;;
    6|byadhav|byadhav36|byad|yadav|yadhav|byadhav_36)
      echo "byadhav" ;;
    *)
      for prof in "${PROFILES[@]}"; do
        if [ "$prof" = "$p" ]; then
          echo "$prof"
          return 0
        fi
      done
      echo "$p"
      ;;
  esac
}

show_help() {
  cat << 'HELP_EOF'
Claude Dispatcher — Multi-Profile Claude Desktop Automation

USAGE:
  claude-dispatch.sh [mode|profile|folder] [target] [options]

QUICK PROFILE INVOCATION:
  claude-dispatch.sh byadhav36             Dispatch next pending task to profile 'byadhav'
  claude-dispatch.sh iitm 2                Dispatch task #2 to profile 'iitm'
  claude-dispatch.sh bat -t "Custom text"  Dispatch custom prompt to profile 'bat'

PRIMARY MODES:
  auto [subject]        Auto-detect active pending module & dispatch (1 concept per account)
  status | catalog      Display visual curriculum progress & pending queue
  queue | tasks         View current prompt queue in active-queue/
  coder [all|1..N]      Dispatch codebase engineering prompts (01-docs..05-fullstack)
  content-adder [1..N]  Dispatch curriculum templates (01-plan-subject..06-assets)

REPEAT / BROADCAST MODE (-r, --repeat):
  -r, --repeat <prompt>      Repeat a specific prompt across multiple accounts/profiles.
                             <prompt> can be a 1-based index (e.g. 3), filename, or file path.
  -p, --profiles <list|all>  Target profiles (e.g. byadhav, iitm,bat, or 1,3,6). Default: all.

CUSTOM INLINE PROMPTS (-t, --text):
  -t, --text "prompt..."     Paste custom text directly to target profile(s).

OPTIONS:
  -1, --one                  Dispatch only 1 task / prompt and exit immediately (no interval wait).
  -i, --interval <sec>       Delay in seconds between profile dispatches (default: 600 / 10 min).
  -k, --timeout <sec>        Auto-terminate each launched profile instance after <sec> (default: 1200 / 20 min).
  --delay <sec>              Initial UI load wait time before pasting (default: 5).
  -n, --dry-run              Preview actions without launching apps or sending keystrokes.
  -h, --help                 Display this help menu.

PROFILES CONFIGURED:
  1. iitm          2. bat          3. bharath9014
  4. bharathy723   5. bharathy798  6. byadhav (aliases: byadhav36)

HELP_EOF
}

# Defaults
MODE="auto"
TARGET_FOLDER=""
TARGET_ACTION="all"
TARGET_SUBJECT=""
TARGET_PROFILES="all"
REPEAT_PROMPT=""
CUSTOM_TEXT=""
INTERVAL=600
KILL_TIMEOUT=1200
UI_DELAY=5
DRY_RUN=false
SINGLE_ONLY=false

# First pass: check if positional argument is a profile alias, mode, or folder
if [ "$#" -gt 0 ]; then
  first_arg="$1"
  normalized_first="$(normalize_profile "$first_arg")"

  # Check if first arg is a known profile
  is_profile=false
  for prof in "${PROFILES[@]}"; do
    if [ "$prof" = "$normalized_first" ]; then
      is_profile=true
      break
    fi
  done

  if [ "$is_profile" = true ]; then
    TARGET_PROFILES="$normalized_first"
    shift 1
    # Check next positional arg
    if [ "$#" -gt 0 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
      TARGET_ACTION="$1"
      shift 1
    fi
  elif [ "$first_arg" = "status" ] || [ "$first_arg" = "catalog" ] || [ "$first_arg" = "ls" ]; then
    MODE="status"
    shift 1
  elif [ "$first_arg" = "queue" ] || [ "$first_arg" = "tasks" ]; then
    MODE="queue"
    shift 1
  elif [ "$first_arg" = "auto" ]; then
    MODE="auto"
    shift 1
    if [ "$#" -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
      TARGET_SUBJECT="$1"
      shift 1
    fi
  elif [ "$first_arg" = "coder" ] || [ "$first_arg" = "content-adder" ] || [ -d "${PROMPTS_BASE}/${first_arg}" ]; then
    MODE="folder"
    TARGET_FOLDER="$first_arg"
    shift 1
    if [ "$#" -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
      TARGET_ACTION="$1"
      shift 1
    fi
  fi
fi

# Parse remaining flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift 1
      ;;
    -1|--one)
      SINGLE_ONLY=true
      shift 1
      ;;
    -i|--interval)
      INTERVAL="$2"
      shift 2
      ;;
    -k|--timeout|--kill-timeout)
      KILL_TIMEOUT="$2"
      shift 2
      ;;
    --timeout=*|--kill-timeout=*)
      KILL_TIMEOUT="${1#*=}"
      shift 1
      ;;
    --delay)
      UI_DELAY="$2"
      shift 2
      ;;
    -p|--profiles|--profile)
      TARGET_PROFILES="$2"
      shift 2
      ;;
    --profiles=*|--profile=*)
      TARGET_PROFILES="${1#*=}"
      shift 1
      ;;
    -r|--repeat)
      MODE="repeat"
      REPEAT_PROMPT="$2"
      shift 2
      ;;
    --repeat=*)
      MODE="repeat"
      REPEAT_PROMPT="${1#*=}"
      shift 1
      ;;
    -t|--text|--prompt)
      MODE="custom"
      CUSTOM_TEXT="$2"
      shift 2
      ;;
    --text=*|--prompt=*)
      MODE="custom"
      CUSTOM_TEXT="${1#*=}"
      shift 1
      ;;
    status|catalog|ls)
      MODE="status"
      shift 1
      ;;
    queue|tasks)
      MODE="queue"
      shift 1
      ;;
    auto)
      MODE="auto"
      shift 1
      ;;
    coder|content-adder)
      MODE="folder"
      TARGET_FOLDER="$1"
      shift 1
      ;;
    *)
      # Check if argument is a subject ID
      if [ -d "${PROJECT_ROOT}/content/subjects/$1" ]; then
        TARGET_SUBJECT="$1"
      elif [[ "$1" =~ ^[0-9]+$ ]] && [ -z "$REPEAT_PROMPT" ]; then
        TARGET_ACTION="$1"
      else
        echo -e "${RED}[ERROR]${NC} Unknown argument: $1" >&2
        show_help
        exit 1
      fi
      shift 1
      ;;
  esac
done

# Resolve list of selected profiles
get_selected_profiles() {
  declare -a selected=()
  if [ "$TARGET_PROFILES" = "all" ] || [ -z "$TARGET_PROFILES" ]; then
    selected=("${PROFILES[@]}")
  else
    local cleaned="${TARGET_PROFILES//,/ }"
    for item in $cleaned; do
      local norm
      norm="$(normalize_profile "$item")"
      for prof in "${PROFILES[@]}"; do
        if [ "$prof" = "$norm" ]; then
          selected+=("$prof")
          break
        fi
      done
    done
  fi

  if [ "${#selected[@]}" -eq 0 ]; then
    selected=("${PROFILES[@]}")
  fi
  echo "${selected[@]}"
}

# Core Single-Profile Dispatcher
dispatch_single() {
  local profile="$1"
  local prompt_file="$2"
  local step_num="${3:-1}"
  local total_steps="${4:-1}"

  local prompt_name
  prompt_name="$(basename "$prompt_file")"

  if [ ! -f "$prompt_file" ]; then
    echo -e "${RED}[ERROR]${NC} Prompt file not found: $prompt_file" >&2
    return 1
  fi

  local bin="claude-desktop"
  if command -v "claude-desktop-${profile}" >/dev/null 2>&1; then
    bin="claude-desktop-${profile}"
  elif command -v claude-desktop >/dev/null 2>&1; then
    bin="claude-desktop --profile ${profile}"
  fi

  if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN]${NC} [${step_num}/${total_steps}] Would launch profile '${BOLD}${profile}${NC}' ($bin)"
    echo -e "          Prompt file: ${CYAN}${prompt_file}${NC}"
    echo -e "          Actions    : sleep ${UI_DELAY}s -> wl-copy -> ydotool Ctrl+V + Enter"
    if [ "$KILL_TIMEOUT" -gt 0 ]; then
      echo -e "          Auto-Kill  : Kill process after ${KILL_TIMEOUT}s ($((KILL_TIMEOUT / 60)) min)"
    fi
    return 0
  fi

  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${step_num}/${total_steps}] Launching profile '${BOLD}${GREEN}${profile}${NC}' with '${CYAN}${prompt_name}${NC}'..."
  nohup $bin >/dev/null 2>&1 &
  local app_pid=$!

  # Auto-kill after KILL_TIMEOUT (default: 1200s / 20 min)
  if [ "$KILL_TIMEOUT" -gt 0 ]; then
    (
      sleep "$KILL_TIMEOUT"
      if kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        sleep 2
        kill -9 "$app_pid" 2>/dev/null || true
      fi
      pkill -f "claude-desktop-${profile}" 2>/dev/null || true
      pkill -f "claude-desktop.*${profile}" 2>/dev/null || true
    ) >/dev/null 2>&1 &
  fi
  disown

  sleep "$UI_DELAY"

  # Copy to clipboard (with fallbacks)
  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$prompt_file"
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$prompt_file"
  elif command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$prompt_file"
  fi

  # Paste keystroke (ydotool -> wtype -> xdotool)
  if command -v ydotool >/dev/null 2>&1; then
    ydotool key 29:1 47:1 47:0 29:0
    sleep 1
    ydotool key 28:1 28:0
  elif command -v wtype >/dev/null 2>&1; then
    wtype -M ctrl -k v -m ctrl
    sleep 1
    wtype -k Return
  elif command -v xdotool >/dev/null 2>&1; then
    xdotool key ctrl+v
    sleep 1
    xdotool key Return
  fi

  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Profile '${BOLD}${GREEN}${profile}${NC}' dispatched with '${CYAN}${prompt_name}${NC}'."
}

# ------------------------------------------------------------------------------
# MODE HANDLERS
# ------------------------------------------------------------------------------

if [ "$MODE" = "status" ]; then
  python3 "$CATALOG_TOOL" status
  exit 0

elif [ "$MODE" = "queue" ]; then
  echo -e "${BOLD}Current Active Prompt Queue (${ACTIVE_QUEUE_DIR}):${NC}"
  mapfile -t QUEUED < <(find "$ACTIVE_QUEUE_DIR" -maxdepth 1 -name "*.md" | sort)
  if [ "${#QUEUED[@]}" -eq 0 ]; then
    echo "  (Queue is currently empty. Run 'claude-dispatch.sh auto' to populate tasks.)"
  else
    for i in "${!QUEUED[@]}"; do
      echo -e "  [${BOLD}$((i+1))${NC}] $(basename "${QUEUED[$i]}")"
    done
  fi
  exit 0

elif [ "$MODE" = "custom" ]; then
  mkdir -p "$ACTIVE_QUEUE_DIR"
  TEMP_PROMPT="${ACTIVE_QUEUE_DIR}/temp-custom-prompt.md"
  echo "$CUSTOM_TEXT" > "$TEMP_PROMPT"

  read -r -a SELECTED < <(get_selected_profiles)
  TOTAL_SELECTED="${#SELECTED[@]}"

  if [ "$SINGLE_ONLY" = true ]; then
    TOTAL_SELECTED=1
  fi

  echo "===================================================================="
  echo -e " ${BOLD}Claude Dispatcher: Custom Text Prompt Mode${NC}"
  echo "===================================================================="
  echo -e "Profiles (${TOTAL_SELECTED}) : ${BOLD}${SELECTED[*]}${NC}"
  echo -e "Prompt Text          : ${CYAN}${CUSTOM_TEXT}${NC}"
  echo "===================================================================="
  echo ""

  for ((i=0; i<TOTAL_SELECTED; i++)); do
    step=$((i + 1))
    prof="${SELECTED[$i]}"
    dispatch_single "$prof" "$TEMP_PROMPT" "$step" "$TOTAL_SELECTED"

    if [ "$step" -lt "$TOTAL_SELECTED" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would wait ${INTERVAL}s before next profile..."
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile '$prof' launched. Waiting ${INTERVAL}s before dispatching next profile..."
        sleep "$INTERVAL"
      fi
    fi
  done

elif [ "$MODE" = "auto" ]; then
  echo "===================================================================="
  echo -e " ${BOLD}Claude Dispatcher: Auto Curriculum Queue Mode${NC}"
  echo "===================================================================="

  read -r -a SELECTED < <(get_selected_profiles)
  MAX_LIMIT="${#SELECTED[@]}"
  if [ "$SINGLE_ONLY" = true ]; then
    MAX_LIMIT=1
  fi

  NEXT_ARGS=()
  if [ -n "$TARGET_SUBJECT" ]; then
    NEXT_ARGS+=("--subject" "$TARGET_SUBJECT")
  fi
  NEXT_ARGS+=("--limit" "$MAX_LIMIT")
  NEXT_ARGS+=("--queue-dir" "$ACTIVE_QUEUE_DIR")

  python3 "$CATALOG_TOOL" next "${NEXT_ARGS[@]}"

  mapfile -t PROMPT_FILES < <(find "$ACTIVE_QUEUE_DIR" -maxdepth 1 -name "*.md" | sort)
  TOTAL_FILES="${#PROMPT_FILES[@]}"

  if [ "$TOTAL_FILES" -eq 0 ]; then
    echo -e "${GREEN}[INFO]${NC} No pending tasks found in the catalog queue. All content is up to date!"
    exit 0
  fi

  echo ""
  echo -e "${BOLD}Dispatching ${TOTAL_FILES} active task(s) across selected profiles:${NC}"
  for i in "${!PROMPT_FILES[@]}"; do
    p_idx=$((i + 1))
    f_name="$(basename "${PROMPT_FILES[$i]}")"
    prof="${SELECTED[$((i % ${#SELECTED[@]}))]}"
    echo -e "  [${BOLD}${p_idx}${NC}] ${CYAN}${f_name}${NC} -> profile: ${BOLD}${GREEN}${prof}${NC}"
  done
  echo ""

  # If user provided a specific single index (e.g. "claude-dispatch.sh byadhav 2")
  if [ "$TARGET_ACTION" != "all" ] && [[ "$TARGET_ACTION" =~ ^[0-9]+$ ]]; then
    file_idx=$((TARGET_ACTION - 1))
    if [ "$file_idx" -lt 0 ] || [ "$file_idx" -ge "$TOTAL_FILES" ]; then
      echo -e "${RED}[ERROR]${NC} Invalid task index $TARGET_ACTION. Available: 1..$TOTAL_FILES" >&2
      exit 1
    fi
    p_file="${PROMPT_FILES[$file_idx]}"
    prof="${SELECTED[0]}"
    dispatch_single "$prof" "$p_file" "1" "1"
    exit 0
  fi

  for ((idx=1; idx<=TOTAL_FILES; idx++)); do
    file_idx=$((idx - 1))
    p_file="${PROMPT_FILES[$file_idx]}"
    prof="${SELECTED[$((file_idx % ${#SELECTED[@]}))]}"

    dispatch_single "$prof" "$p_file" "$idx" "$TOTAL_FILES"

    if [ "$idx" -lt "$TOTAL_FILES" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would wait ${INTERVAL}s before next profile dispatch..."
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Task $idx dispatched. Waiting ${INTERVAL}s before dispatching next profile..."
        sleep "$INTERVAL"
      fi
    fi
  done

  echo ""
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] All $TOTAL_FILES active tasks dispatched successfully.${NC}"

elif [ "$MODE" = "repeat" ]; then
  TARGET_DIR="${PROMPTS_BASE}/content-adder"
  if [ -n "$TARGET_FOLDER" ] && [ -d "${PROMPTS_BASE}/${TARGET_FOLDER}" ]; then
    TARGET_DIR="${PROMPTS_BASE}/${TARGET_FOLDER}"
  fi

  CHOSEN_PROMPT_FILE=""
  if [ -f "$REPEAT_PROMPT" ]; then
    CHOSEN_PROMPT_FILE="$(cd "$(dirname "$REPEAT_PROMPT")" && pwd)/$(basename "$REPEAT_PROMPT")"
  elif [[ "$REPEAT_PROMPT" =~ ^[0-9]+$ ]]; then
    mapfile -t ALL_P_FILES < <(find "$TARGET_DIR" -maxdepth 1 -name "*.md" ! -name "*_bugs.md" ! -iname "AGENTS.md" ! -iname "README.md" | sort)
    f_idx=$((REPEAT_PROMPT - 1))
    if [ "$f_idx" -ge 0 ] && [ "$f_idx" -lt "${#ALL_P_FILES[@]}" ]; then
      CHOSEN_PROMPT_FILE="${ALL_P_FILES[$f_idx]}"
    fi
  elif [ -f "${TARGET_DIR}/${REPEAT_PROMPT}" ]; then
    CHOSEN_PROMPT_FILE="${TARGET_DIR}/${REPEAT_PROMPT}"
  elif [ -f "${ACTIVE_QUEUE_DIR}/${REPEAT_PROMPT}" ]; then
    CHOSEN_PROMPT_FILE="${ACTIVE_QUEUE_DIR}/${REPEAT_PROMPT}"
  fi

  if [ -z "$CHOSEN_PROMPT_FILE" ] || [ ! -f "$CHOSEN_PROMPT_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Could not resolve prompt file for '$REPEAT_PROMPT' in $TARGET_DIR" >&2
    exit 1
  fi

  read -r -a SELECTED < <(get_selected_profiles)
  TOTAL_SELECTED="${#SELECTED[@]}"
  if [ "$SINGLE_ONLY" = true ]; then
    TOTAL_SELECTED=1
  fi

  echo "===================================================================="
  echo -e " ${BOLD}Claude Dispatcher: Repeat Prompt Mode${NC}"
  echo "===================================================================="
  echo -e "Prompt File : ${CYAN}$(basename "$CHOSEN_PROMPT_FILE")${NC}"
  echo -e "Profiles (${TOTAL_SELECTED}) : ${BOLD}${SELECTED[*]}${NC}"
  echo -e "Interval    : ${INTERVAL}s between dispatches"
  echo -e "Dry Run     : $DRY_RUN"
  echo "===================================================================="
  echo ""

  for ((i=0; i<TOTAL_SELECTED; i++)); do
    step=$((i + 1))
    prof="${SELECTED[$i]}"
    dispatch_single "$prof" "$CHOSEN_PROMPT_FILE" "$step" "$TOTAL_SELECTED"

    if [ "$step" -lt "$TOTAL_SELECTED" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY RUN]${NC} Would wait ${INTERVAL}s before next profile..."
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Profile '$prof' launched. Waiting ${INTERVAL}s before dispatching next profile..."
        sleep "$INTERVAL"
      fi
    fi
  done

elif [ "$MODE" = "folder" ]; then
  if [ -d "$TARGET_FOLDER" ]; then
    TARGET_DIR="$(cd "$TARGET_FOLDER" && pwd)"
  elif [ -d "${PROMPTS_BASE}/${TARGET_FOLDER}" ]; then
    TARGET_DIR="${PROMPTS_BASE}/${TARGET_FOLDER}"
  else
    echo -e "${RED}[ERROR]${NC} Target directory not found: $TARGET_FOLDER" >&2
    exit 1
  fi

  mapfile -t PROMPT_FILES < <(find "$TARGET_DIR" -maxdepth 1 -name "*.md" ! -name "*_bugs.md" ! -iname "AGENTS.md" ! -iname "README.md" | sort)
  TOTAL_FILES="${#PROMPT_FILES[@]}"

  if [ "$TOTAL_FILES" -eq 0 ]; then
    echo -e "${RED}[ERROR]${NC} No prompt files (*.md) found in $TARGET_DIR" >&2
    exit 1
  fi

  read -r -a SELECTED < <(get_selected_profiles)

  echo -e "Target prompt directory: ${BOLD}${TARGET_DIR}${NC} ($TOTAL_FILES prompt files found)"
  for i in "${!PROMPT_FILES[@]}"; do
    p_idx=$((i + 1))
    f_name="$(basename "${PROMPT_FILES[$i]}")"
    prof="${SELECTED[$((i % ${#SELECTED[@]}))]}"
    echo -e "  [${BOLD}${p_idx}${NC}] ${CYAN}${f_name}${NC} -> profile: ${BOLD}${GREEN}${prof}${NC}"
  done
  echo ""

  case "$TARGET_ACTION" in
    all|"")
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sequential dispatch (1 prompt every ${INTERVAL}s)..."
      for ((idx=1; idx<=TOTAL_FILES; idx++)); do
        file_idx=$((idx - 1))
        p_file="${PROMPT_FILES[$file_idx]}"
        prof="${SELECTED[$((file_idx % ${#SELECTED[@]}))]}"

        dispatch_single "$prof" "$p_file" "$idx" "$TOTAL_FILES"

        if [ "$idx" -lt "$TOTAL_FILES" ]; then
          if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would wait ${INTERVAL}s before next prompt..."
          else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Prompt $idx dispatched. Waiting ${INTERVAL}s before dispatching next prompt..."
            sleep "$INTERVAL"
          fi
        fi
      done
      ;;
    [0-9]*)
      file_idx=$((TARGET_ACTION - 1))
      if [ "$file_idx" -lt 0 ] || [ "$file_idx" -ge "$TOTAL_FILES" ]; then
        echo -e "${RED}[ERROR]${NC} Invalid index $TARGET_ACTION. Available prompts in $(basename "$TARGET_DIR"): 1..$TOTAL_FILES" >&2
        exit 1
      fi
      p_file="${PROMPT_FILES[$file_idx]}"
      prof="${SELECTED[0]}"
      dispatch_single "$prof" "$p_file" "1" "1"
      ;;
  esac
fi
