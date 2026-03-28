DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
CACHE="$HOME/.zsh_dotfiles_cache"
TTL=86400

if [[ ! -f "$CACHE" || $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE") )) -gt $TTL ]]; then
  {
    for f in "$DOTFILES_DIR"/shell-sources/**/*.sh; do
      [[ -f "$f" ]] && cat "$f"
    done
  } > "$CACHE"
fi

source "$CACHE"
