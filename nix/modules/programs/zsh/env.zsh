export DOTFILES_DIR="$HOME/.dotfiles"
export EDITOR=nvim
export SUDO_EDITOR=nvim
export MANPAGER="nvim +Man!"

path=(
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.bun/bin"
  $path
)
