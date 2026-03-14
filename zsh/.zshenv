#!/usr/bin/env zsh
# ~/.zshenv — sourced for ALL zsh sessions (login, interactive, scripts)
# Keep minimal: only env vars & PATH that must be available everywhere.
# Managed by stow: zsh package

export DOTFILES_DIR="$HOME/.dotfiles"
export EDITOR=nvim
export SUDO_EDITOR=nvim
export MANPAGER="nvim +Man!"

# PATH — deduplicated by zsh automatically with typeset -U
typeset -U path
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  /usr/local/bin
  /usr/local/sbin
  /usr/bin
  /bin
  /sbin
  $path
)
export PATH
