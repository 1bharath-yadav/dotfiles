#!/usr/bin/env bash
# Python / uv configuration
# Strategy:
#   Global CLI tools  → uv tool install <pkg>   (lives in ~/.local/bin, always in PATH)
#   Project dev tools → uv run <tool>            (uses the project's own .venv)
#   Ephemeral tools   → uvx <pkg>               (one-shot, no install)
#   Services          → systemd user units       (see service aliases below)

# ── Core env ─────────────────────────────────────────────────────────────────
export PYTHONIOENCODING='UTF-8'
export PYTHONUTF8=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
# export UV_TORCH_BACKEND=cpu
# uv tool installs land in ~/.local/bin (already in PATH via home.sessionPath / paths.sh)
export UV_TOOL_BIN_DIR="$HOME/.local/bin"
export UV_TORCH_BACKEND=auto


# ── uv project management ─────────────────────────────────────────────────────
alias uvi='uv add'              # add dep to current project
alias uvr='uv run'              # run cmd in project venv
alias uvx='uvx'                 # ephemeral one-shot tool run (like npx)
alias uvl='uv pip list'
alias uvup='uv lock --upgrade'
alias uvun='uv remove'
alias uvs='uv sync'             # sync deps from lock file
alias uvf='uv pip freeze'

# ── uv tool (global CLI tools, isolated, in ~/.local/bin) ────────────────────
alias uvti='uv tool install'    # install a global tool
alias uvtu='uv tool upgrade'    # upgrade a global tool
alias uvtl='uv tool list'       # list installed global tools
alias uvtun='uv tool uninstall'

# ── venv helpers (for project-local use only) ────────────────────────────────
alias mkvenv='uv venv .venv'
alias venva='source .venv/bin/activate'
alias deact='deactivate'
alias rmvenv='rm -rf .venv'

# ── Code quality (project-scoped, not global) ────────────────────────────────
alias black='uv run black'
alias ruff='uv run ruff'
alias mypy='uv run mypy'
alias pytest='uv run pytest'
alias pytestv='uv run pytest -v'
alias pytestc='uv run pytest --cov'

# ── Cleanup ───────────────────────────────────────────────────────────────────
alias rmpyc="find . -type f -name '*.pyc' -delete"
alias rmpyall="find . -type f -name '*.py[cod]' -delete && find . -type d -name __pycache__ -delete"

# ── Service control (systemd user units) ─────────────────────────────────────
# Usage: svc-start open-webui / svc-stop open-webui / svc-log open-webui
alias svc-start='systemctl --user start'
alias svc-stop='systemctl --user stop'
alias svc-restart='systemctl --user restart'
alias svc-status='systemctl --user status'
alias svc-log='journalctl --user -u'
alias svc-enable='systemctl --user enable'
alias svc-list='systemctl --user list-units --type=service --state=running'

# quick shortcuts for your specific services
alias webui-start='systemctl --user start open-webui'
alias webui-stop='systemctl --user stop open-webui'
alias webui-log='journalctl --user -u open-webui -f'

# ── Utility functions ─────────────────────────────────────────────────────────
python_info() {
  echo "python:  $(python3 --version 2>/dev/null)"
  echo "uv:      $(uv --version 2>/dev/null)"
  echo "tools:   $(uv tool list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ' ')"
  echo "venv:    ${VIRTUAL_ENV:-none}"
}

python_new() {
  # Scaffold a new uv project: python_new myproject [3.12]
  local name="${1:?Usage: python_new <name> [python-version]}"
  local pyver="${2:-3.12}"
  uv init "$name" --python "$pyver"
  echo "Created: $name  (python $pyver)"
}
