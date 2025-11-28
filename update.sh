#!/usr/bin/env zsh

set -e

cd ~/.dotfiles/
stow -D -v */
cd ~/linux/end4dots && git stash && git pull && ./setup install
cd ~/.dotfiles/
stow -v */

echo "$(date): Dotfiles update completed successfully" >> ~/.dotfiles/update.log


