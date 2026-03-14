#!/usr/bin/env bash
# cleanup_root_orphans.sh — remove old setup script orphans from $HOME
# Safe to run once; these are now in ~/.dotfiles/setup/ and ~/.dotfiles/stow/
set -euo pipefail

ORPHANS=(
  arch_linux_setup.sh
  arch_linux_stow.sh
  wsl_ubuntu_setup.sh
  wsl_ubuntu_stow.sh
  auto_setup.sh
)

for f in "${ORPHANS[@]}"; do
  if [[ -f "$HOME/$f" ]]; then
    echo "Removing: $HOME/$f"
    rm "$HOME/$f"
  fi
done
echo "Done. Old setup scripts removed from \$HOME."
