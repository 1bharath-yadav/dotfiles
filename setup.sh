#!/bin/bash

# Install necessary Termux packages
pkg update -y && pkg upgrade -y
pkg install -y zsh neovim git wget eza fzf bat python nodejs curl stow

# Install trash-cli (via pip) and fnm (via npm)
pip install trash-cli
npm install -g fnm

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set Zsh as the default shell
chsh -s zsh

# Reload Termux style
am broadcast --user 0 -a com.termux.app.reload_style com.termux

# IMPORTANT: After running this script, you need to manually stow your dotfiles.
# Navigate to your dotfiles directory:
# cd /data/data/com.termux/files/home/dotfiles
# Then, run the stow commands for each dotfile directory:
# stow zsh
# stow termux
