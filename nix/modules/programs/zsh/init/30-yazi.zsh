y() {
  local tmp="$(mktemp)" cwd
  yazi "$@" --cwd-file="$tmp"
  read -r cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
  rm -f "$tmp"
}
