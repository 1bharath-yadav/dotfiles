# Load shell-sources with caching for faster startup
_SHELL_SOURCES_DIR="$ZDOTDIR/shell-sources"
_SHELL_SOURCES_CACHE="$ZDOTDIR/.shell-sources-cache"

if [[ -d "$_SHELL_SOURCES_DIR" ]]; then
  # Check if cache exists and is current (compare mtime of cache vs shell-sources dir)
  local regenerate=1
  if [[ -f "$_SHELL_SOURCES_CACHE" ]]; then
    # Get modification time of cache and shell-sources folder
    local cache_mtime=$(stat -c %Y "$_SHELL_SOURCES_CACHE" 2>/dev/null || stat -f %m "$_SHELL_SOURCES_CACHE" 2>/dev/null || echo 0)
    local sources_mtime=$(stat -c %Y "$_SHELL_SOURCES_DIR" 2>/dev/null || stat -f %m "$_SHELL_SOURCES_DIR" 2>/dev/null || echo 0)
    
    # If cache is newer, don't regenerate
    [[ $cache_mtime -ge $sources_mtime ]] && regenerate=0
  fi
  
  # Regenerate cache if needed
  if (( regenerate )); then
    { echo "# ⚡ shell-sources cache — regenerated $(date)"
      for f in "$_SHELL_SOURCES_DIR"/**/*.sh(.N); do
        [[ -f "$f" ]] && cat "$f"
        echo
      done
    } > "$_SHELL_SOURCES_CACHE"
  fi
  
  # Source the cache
  [[ -f "$_SHELL_SOURCES_CACHE" ]] && source "$_SHELL_SOURCES_CACHE"
fi
