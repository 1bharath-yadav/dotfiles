DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
for f in "$DOTFILES_DIR"/shell-sources/**/*.sh(.N); do
  source "$f"
done
