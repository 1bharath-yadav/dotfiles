#!/usr/bin/env bash

#***************   DEFAULT PATHS   ******************

# System paths
export PATH=/usr/local/bin:"${PATH}"
export PATH=/usr/local/sbin:"${PATH}"
export PATH=/usr/bin:"${PATH}"
export PATH=/bin:"${PATH}"
export PATH=/sbin:"${PATH}"



#**************   CUSTOM PATHS   *********************

# Add specific virtualenv paths
export PATH="$HOME/apps/global/.venv/bin:$PATH"
export PATH="$HOME/apps/euphorie_env/.venv/bin:$PATH"
export PATH="$HOME/apps/open-webui_env/.venv/bin:$PATH"

# System paths
# Adding essential system directories to PATH
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/sbin:${PATH}"
export PATH="/home/archer/.local/share/../bin:$PATH"
# Add Cargo binaries to PATH (check version with: cargo --version)
export PATH="${HOME}/.cargo/bin:${PATH}"


# Add Node.js global modules binaries to PATH (check version with: node --version)
export PATH="${HOME}/.node_modules/bin:${PATH}"

# # Deduplicate PATH entries
# deduplicate_path() {
#     PATH=$(echo "$PATH" | awk -v RS=':' '!seen[$0]++ {ORS=(NR>1?":":"")} {print}')
#     export PATH
# }

# # Call the deduplication function
# PATH=$(echo "$PATH" | awk -v RS=':' '!seen[$0]++ {ORS=(NR>1?":":"")} {print}')
# export PATH

# deduplicate_path



