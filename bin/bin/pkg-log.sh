#!/bin/bash

# pkg-log.sh
PKGS_JSON="$HOME/dotfiles/pkgs.json"

# Initialize JSON file if it doesn't exist
if [[ ! -f "$PKGS_JSON" ]]; then
    echo '{"official": [], "aur": []}' > "$PKGS_JSON"
fi

for pkg in "$@"; do
    # Check if package exists in official repos
    if pacman -Si "$pkg" &>/dev/null; then
        repo="official"
        desc=$(pacman -Si "$pkg" | awk -F': ' '/^Description/ {print $2; exit}')
        sudo pacman -S "$pkg"
    elif yay -Si "$pkg" &>/dev/null; then
        repo="aur"
        desc=$(yay -Si "$pkg" | awk -F': ' '/^Description/ {print $2; exit}')
        echo "Installing $pkg from AUR..."
        yay -S "$pkg"
    else
        echo "Package $pkg not found in official or AUR repos"
        continue
    fi

    # Add package to JSON using jq
    jq --arg name "$pkg" --arg desc "$desc" --arg repo "$repo" \
        '. + {($repo): (.[$repo] + [{"name": $name, "description": $desc}]) | unique}' \
        "$PKGS_JSON" > "${PKGS_JSON}.tmp" && mv "${PKGS_JSON}.tmp" "$PKGS_JSON"
    
    echo "Installed and added $pkg to $repo"
done
