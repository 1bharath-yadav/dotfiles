#!/usr/bin/env bash
# setup/ubuntu.sh — Ubuntu / WSL setup
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

# Map Arch package names → Ubuntu apt names where they differ
declare -A APT_MAP=(
  [fd]=fd-find
  [python-pip]=python3-pip
  [man-db]=man-db          # same
  [ripgrep]=ripgrep        # same in ubuntu 20.04+
  [zsh-autosuggestions]=zsh-autosuggestions
  [zsh-syntax-highlighting]=zsh-syntax-highlighting
  [fnm-bin]=''             # install via curl below
  [pay-respects]=''        # not in apt, skip
  [intelli-shell]=''       # not in apt, skip
  [yazi]=''                # not in apt, skip (use cargo or binary)
)

apt_has() { apt-cache show "$1" >/dev/null 2>&1; }

install_apt_pkgs() {
  log "Updating apt"
  sudo apt-get update -y
  has_cmd jq || sudo apt-get install -y jq

  mapfile -t wanted < <(jq -r '.common[].name, .ubuntu.apt[].name' "$PKGS_JSON")

  local pkgs=(curl git zsh)  # always ensure bootstrap tools
  for name in "${wanted[@]}"; do
    local mapped="${APT_MAP[$name]:-$name}"
    [[ -z "$mapped" ]] && { warn "Skipping (no apt equiv): $name"; continue; }
    apt_has "$mapped" && pkgs+=("$mapped") || warn "Not in apt: $mapped"
  done

  # dedup
  local deduped
  deduped=$(printf '%s\n' "${pkgs[@]}" | awk '!seen[$0]++')
  log "Installing apt packages"
  printf '%s\0' $deduped | xargs -0 sudo apt-get install -y
}

install_fnm() {
  has_cmd fnm && return
  log "Installing fnm"
  curl -fsSL https://fnm.vercel.app/install | bash
}

# Install tools not in apt via alternative methods
install_extras() {
  # starship
  has_cmd starship || { log "Installing starship"; curl -sS https://starship.rs/install.sh | sh -s -- -y; }
  # zoxide
  has_cmd zoxide   || { log "Installing zoxide"; curl -sSfL https://setup.zoxide.dev | sh -s - --bin-dir ~/.local/bin; }
  # yazi (prebuilt binary)
  has_cmd yazi     || {
    log "Installing yazi"
    local tmp; tmp=$(mktemp -d)
    curl -sSLo "$tmp/yazi.zip" \
      "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip"
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    install -m755 "$tmp"/yazi-*/yazi "$HOME/.local/bin/yazi"
    rm -rf "$tmp"
  }
}

main() {
  install_apt_pkgs
  install_fnm
  install_omz
  install_extras
  install_npm_globals
  install_lazy
  set_zsh_default
  log "Stowing dotfiles"
  source "$DOTFILES/stow/ubuntu.sh"
  install_yazi_pkgs
  log "Ubuntu/WSL setup complete!"
}

main "$@"
