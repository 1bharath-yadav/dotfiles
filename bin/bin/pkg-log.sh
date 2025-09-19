#!/bin/bash

PKGS_JSON="$HOME/.dotfiles/pkgs.json"

# Ensure JSON exists
[[ -f "$PKGS_JSON" ]] || echo '{"official": [], "aur": []}' > "$PKGS_JSON"

install_pkg() {
    local pkg="$1" repo desc
    if pacman -Si "$pkg" &>/dev/null; then
        repo="official"
        desc=$(pacman -Si "$pkg" | awk -F': ' '/^Description/ {print $2; exit}')
        sudo pacman -S "$pkg"
    elif yay -Si "$pkg" &>/dev/null; then
        repo="aur"
        desc=$(yay -Si "$pkg" | awk -F': ' '/^Description/ {print $2; exit}')
        yay -S "$pkg"
    else
        echo "❌ $pkg not found in official or AUR repos"
        return
    fi

    # Update JSON
    jq --arg name "$pkg" --arg desc "$desc" --arg repo "$repo" \
       '.[$repo] += [{"name": $name, "description": $desc}] | .[$repo] |= unique' \
       "$PKGS_JSON" > "${PKGS_JSON}.tmp" && mv "${PKGS_JSON}.tmp" "$PKGS_JSON"

    echo "✅ Installed: $pkg — $desc"
}

remove_pkg() {
    local pkg="$1"
    if pacman -Qi "$pkg" &>/dev/null; then
        sudo pacman -Rns "$pkg"
    elif yay -Qi "$pkg" &>/dev/null; then
        yay -Rns "$pkg"
    else
        echo "⚠️ $pkg not installed (removing only from JSON)"
    fi

    jq --arg name "$pkg" '
        .official |= map(select(.name != $name)) |
        .aur      |= map(select(.name != $name))' \
        "$PKGS_JSON" > "${PKGS_JSON}.tmp" && mv "${PKGS_JSON}.tmp" "$PKGS_JSON"

    echo "🗑 Removed: $pkg"
}

case "$1" in
    i)  shift; for pkg in "$@"; do install_pkg "$pkg"; done ;;
    rp) shift; for pkg in "$@"; do remove_pkg "$pkg"; done ;;
    *)  echo "Usage: $0 {i|rp} pkg1 [pkg2 ...]"; exit 1 ;;
esac
