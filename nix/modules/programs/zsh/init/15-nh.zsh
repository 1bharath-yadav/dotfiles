dotfiles-host() {
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
    echo archer-wsl
  elif [[ -f /etc/arch-release ]]; then
    echo archer-arch
  else
    echo archer-wsl
  fi
}

dotfiles-switch() {
  local host
  host="$(dotfiles-host)"
  if command -v nh >/dev/null 2>&1; then
    nh home switch "$NH_HOME_FLAKE" -c "$host" "$@"
  else
    home-manager switch --flake "$HOME/.dotfiles#$host" "$@"
  fi
}

dotfiles-test() {
  local host
  host="$(dotfiles-host)"
  if command -v nh >/dev/null 2>&1; then
    nh home test "$NH_HOME_FLAKE" -c "$host" "$@"
  else
    home-manager build --flake "$HOME/.dotfiles#$host" "$@"
  fi
}

dotfiles-build() {
  local host
  host="$(dotfiles-host)"
  if command -v nh >/dev/null 2>&1; then
    nh home build "$NH_HOME_FLAKE" -c "$host" "$@"
  else
    home-manager build --flake "$HOME/.dotfiles#$host" "$@"
  fi
}
