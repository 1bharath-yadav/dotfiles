#!/usr/bin/env bash

################################################################################
# 🅳🅾🆃🅵🅸🅻🅴🆂 - Python Development Environment Configuration (uv version)
# Made with ♥ in London, UK by Sebastien Rousseau
# Modified for uv package manager by Bharath
# License: MIT
#
# Description:
#   Configuration file for Python development environment using uv.
#   Includes aliases, environment variables, and utility functions for common
#   Python + uv tasks.
################################################################################

# Environment Variables
export PYTHONIOENCODING='UTF-8'
export PYTHONUTF8=1
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

if command -v 'python3' >/dev/null; then
    # Python wrapper
    python() {
        command python3 "$@"
    }

    # Basic Python Commands
    alias py='python'
    alias ipy='ipython'
    alias pyv='python --version'
    alias pydoc='python -m pydoc'

    # Package Management via uv
    alias uvi='uv add'                    # Install dependencies (like pip install)
    alias uvr='uv run'                    # Run with uv (isolated env)
    alias uvx='uvx'                       # Run ephemeral tools (like npx)
    alias uvl='uv pip list'               # List installed packages
    alias uvup='uv lock --upgrade'        # Upgrade dependencies in pyproject.toml
    alias uvun='uv remove'                # Uninstall dependency
    alias uvf='uv pip freeze'             # Show frozen requirements
    alias uvout='uv pip freeze > requirements.txt'  # Export requirements
    alias uvin='uv sync'                  # Sync project deps (from lock)

    # Development Tools (run inside uv environments)
    alias black='uv run black'
    alias ruff='uv run ruff'
    alias mypy='uv run mypy'
    alias lint='uv run pylint'
    alias pytest='uv run pytest'
    alias pytestv='uv run pytest -v'
    alias pytestc='uv run pytest --cov'

    # Virtual Environment Management (uv handles isolation, but keep some helpers)
    alias mkvenv='uv venv ./venv'         # Create venv in current dir
    alias venva='source ./venv/bin/activate'
    alias deact='deactivate'
    alias rmvenv='rm -rf ./venv'

    # Cleanup
    alias rmpyc="find . -type f -name '*.pyc' -delete"
    alias rmpyo="find . -type f -name '*.pyo' -delete"
    alias rmpyall="find . -type f -name '*.py[cod]' -delete && find . -type d -name __pycache__ -delete"

    # Utility Functions
    python_speed() {
        if [ $# -eq 0 ]; then
            echo "Usage: python_speed 'Python code here'"
            return 1
        fi
        uv run python -m timeit -s "$1"
    }

    python_profile() {
        if [ $# -eq 0 ]; then
            echo "Usage: python_profile script.py"
            return 1
        fi
        uv run python -m cProfile "$1"
    }

    python_debug() {
        if [ $# -eq 0 ]; then
            echo "Usage: python_debug script.py"
            return 1
        fi
        uv run python -m pdb "$1"
    }

    python_serve() {
        local port="${1:-8000}"
        uv run python -m http.server "$port"
    }

    # Environment Information
    python_info() {
        echo "Python Version:"
        uv run python --version
        echo -e "\nuv Version:"
        uv --version
        echo -e "\nVirtual Environment:"
        if [ -n "$VIRTUAL_ENV" ]; then
            echo "Active: $VIRTUAL_ENV"
        else
            echo "None active"
        fi
        echo -e "\nInstalled Packages:"
        uv pip list
    }
fi
