#!/usr/bin/env zsh

set -e

cd ~/.dotfiles/
stow -D -v */
cd ~/linux/end4dots && git stash && git pull && ./setup install
cd ~/.dotfiles/
stow -v --adopt --restow */
stow -D shell-sources
echo "$(date)" >> ~/.dotfiles/update.log


