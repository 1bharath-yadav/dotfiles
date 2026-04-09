# Load shell-sources from ZDOTDIR
for f in "$ZDOTDIR"/shell-sources/**/*.sh(.N); do
  [[ -f "$f" ]] && source "$f"
done
