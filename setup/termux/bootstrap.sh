#!/data/data/com.termux/files/usr/bin/env bash
# setup/termux/bootstrap.sh — one-shot Termux (Android) dotfiles bootstrap
# Run inside Termux after installing from F-Droid. No nix-on-droid.
# Usage: bash bootstrap.sh [dotfiles-git-url]
set -euo pipefail

log()  { printf "\033[32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[33m!!>\033[0m %s\n" "$*"; }
die()  { printf "\033[31m!!!\033[0m %s\n" "$*" >&2; exit 1; }

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
DOTFILES_REPO="${1:-https://github.com/YOUR_USER/dotfiles}"

# ── 1. storage permission ──────────────────────────────────────────────────
if [[ ! -d /storage/emulated/0 ]]; then
  log "Requesting storage permission"
  termux-setup-storage && sleep 2
fi

# ── 2. core packages ───────────────────────────────────────────────────────
log "Updating repos and installing core packages"
pkg update -y && pkg upgrade -y
pkg install -y \
  git zsh curl wget openssh gnupg \
  neovim python rust nodejs-lts \
  fzf ripgrep fd bat eza zoxide \
  tree unzip zip ffmpeg termux-api

# ── 3. clone dotfiles ──────────────────────────────────────────────────────
if [[ ! -d "$DOTFILES" ]]; then
  log "Cloning dotfiles from $DOTFILES_REPO"
  git clone "$DOTFILES_REPO" "$DOTFILES"
fi

# ── 4. zsh as default shell ────────────────────────────────────────────────
if [[ "$SHELL" != *zsh ]]; then
  chsh -s zsh 2>/dev/null || warn "Set shell manually: chsh -s zsh"
fi

# ── 5. link zshrc ─────────────────────────────────────────────────────────
ZSH_SRC="$DOTFILES/nix/modules/programs/zsh"
if [[ -f "$ZSH_SRC/.zshrc" && ! -e "$HOME/.zshrc" ]]; then
  ln -sf "$ZSH_SRC/.zshrc" "$HOME/.zshrc"
  log "Linked .zshrc"
fi

# ── 6. uv (Python tool manager) ───────────────────────────────────────────
if ! command -v uv >/dev/null 2>&1; then
  log "Installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ── 7. starship prompt ────────────────────────────────────────────────────
if ! command -v starship >/dev/null 2>&1; then
  pkg install starship 2>/dev/null \
    || (command -v cargo >/dev/null && cargo install starship) \
    || warn "Install starship manually: pkg install starship"
fi

log "Termux bootstrap done — restart Termux or: exec zsh"
