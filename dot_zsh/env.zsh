export DOTFILES_DIR="$HOME/.dotfiles"
export EDITOR="nvim"
export SUDO_EDITOR="nvim"
export MANPAGER="nvim +Man!"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$HOME/.local/share/mise/shims:$PATH"
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  $path
)
