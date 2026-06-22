# Load shell-sources with caching for faster startup
_SHELL_SOURCES_DIR="$ZDOTDIR/shell-sources"
_SHELL_SOURCES_CACHE="$ZDOTDIR/.shell-sources-cache"

if [[ -d "$_SHELL_SOURCES_DIR" ]]; then
  # Check if cache exists and is current.
  local regenerate=1
  if [[ -f "$_SHELL_SOURCES_CACHE" ]]; then
    regenerate=0
    grep -q '^# shell-sources cache v2$' "$_SHELL_SOURCES_CACHE" || regenerate=1

    for f in "$_SHELL_SOURCES_DIR"/**/*.sh(.N); do
      [[ "$f" -nt "$_SHELL_SOURCES_CACHE" ]] && regenerate=1
    done
  fi

  # Regenerate cache if needed
  if (( regenerate )); then
    { echo "# shell-sources cache v2"
      echo "# regenerated $(date)"
      for f in "$_SHELL_SOURCES_DIR"/**/*.sh(.N); do
        [[ -f "$f" ]] && printf 'source %q\n' "$f"
      done
    } > "$_SHELL_SOURCES_CACHE"
  fi

  # Source the cache
  [[ -f "$_SHELL_SOURCES_CACHE" ]] && source "$_SHELL_SOURCES_CACHE"
fi
