#!/usr/bin/env bash
# setup/termux.sh — Termux (Android) setup
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
source "$DOTFILES/setup/lib.sh"

install_pkg_pkgs() {
  require_cmd jq
  log "Updating Termux packages"
  pkg update -y && pkg upgrade -y
  log "Installing packages from pkgs.json"
  mapfile -t pkgs < <(jq -r '.termux[].name' "$PKGS_JSON")
  [[ ${#pkgs[@]} -gt 0 ]] && pkg install -y "${pkgs[@]}"
}

install_pip_extras() {
  log "Installing pip packages"
  pip install --quiet trash-cli
}

install_npm_globals_termux() {
  local npm_prefix="$HOME/.npm-global"
  mkdir -p "$npm_prefix"
  npm config set prefix "$npm_prefix"
  has_cmd jq || { warn "jq missing, skipping npm globals"; return; }
  mapfile -t pkgs < <(jq -r '.npm[].name' "$PKGS_JSON" 2>/dev/null || true)
  [[ ${#pkgs[@]} -gt 0 ]] && npm install -g "${pkgs[@]}" || true
}

reload_termux_style() {
  has_cmd am && \
    am broadcast --user 0 -a com.termux.app.reload_style com.termux 2>/dev/null || true
}

main() {
  install_pkg_pkgs
  install_pip_extras
  install_omz
  install_npm_globals_termux
  set_zsh_default
  reload_termux_style
  log "Stowing Termux dotfiles"
  source "$DOTFILES/stow/termux.sh"
  install_yazi_pkgs
  log "Termux setup complete!"
}

main "$@"
