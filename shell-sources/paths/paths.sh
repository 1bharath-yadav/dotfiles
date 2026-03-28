#!/usr/bin/env bash

#***************   DEFAULT PATHS   ******************

# System paths
export PATH=/usr/local/bin:"${PATH}"
export PATH=/usr/local/sbin:"${PATH}"
export PATH=/usr/bin:"${PATH}"
export PATH=/bin:"${PATH}"
export PATH=/sbin:"${PATH}"


export GOG_ACCOUNT=bat1batttt4@gmail.com


#**************   CUSTOM PATHS   *********************

# NOTE: venv bins are NOT in PATH.
# - Services (open-webui, euphorie): managed by systemd user units → start/stop via aliases below
# - Dev tools (marimo, jupyter): use `uvx <tool>` or `uv run <tool>` inside a project
# - Global CLI tools (ruff, mypy): installed via `uv tool install` → live in ~/.local/bin (already in PATH)

# System paths
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/sbin:${PATH}"
# Add Cargo binaries to PATH
export PATH="${HOME}/.cargo/bin:${PATH}"
# Node.js global modules
export PATH="${HOME}/.node_modules/bin:${PATH}"
# uv tool installs land here (already covered by home.sessionPath but explicit for non-HM shells)
export PATH="${HOME}/.local/bin:${PATH}"

# # Deduplicate PATH entries
# deduplicate_path() {
#     PATH=$(echo "$PATH" | awk -v RS=':' '!seen[$0]++ {ORS=(NR>1?":":"")} {print}')
#     export PATH
# }

# # Call the deduplication function
# PATH=$(echo "$PATH" | awk -v RS=':' '!seen[$0]++ {ORS=(NR>1?":":"")} {print}')
# export PATH

# deduplicate_path



