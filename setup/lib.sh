#!/usr/bin/env bash
# setup/lib.sh — shared helpers for all OS setup scripts
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
PKGS_JSON="$DOTFILES/pkgs.json"

# ── logging ────────────────────────────────────────────────────────────────
log()  { printf "\033[32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[33m!!>\033[0m %s\n" "$*"; }
die()  { printf "\033[31m!!!\033[0m %s\n" "$*" >&2; exit 1; }

# ── guards ─────────────────────────────────────────────────────────────────
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
has_cmd()     { command -v "$1" >/dev/null 2>&1; }

# ── OS detection ───────────────────────────────────────────────────────────
is_termux() { [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d /data/data/com.termux ]]; }
is_wsl()    { grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; }
is_arch()   { [[ -f /etc/arch-release ]]; }
is_ubuntu() { grep -qi ubuntu /etc/os-release 2>/dev/null; }

detect_os() {
  if is_termux; then echo termux
  elif is_wsl;  then echo wsl
  elif is_arch; then echo arch
  elif is_ubuntu; then echo ubuntu
  else die "Unsupported OS"; fi
}

# ── stow helpers ───────────────────────────────────────────────────────────
# Dirs that must never be stowed — not config packages
_STOW_BLOCKLIST=(setup stow shell-sources .git .spaces)

_stow_blocked() {
  local pkg="$1"
  local blocked
  for blocked in "${_STOW_BLOCKLIST[@]}"; do
    [[ "$pkg" == "$blocked" ]] && return 0
  done
  return 1
}

stow_pkg() {
  local pkg="$1" target="${2:-$HOME}"
  if _stow_blocked "$pkg"; then
    die "Refusing to stow non-package dir: $pkg"
  fi
  if [[ ! -d "$DOTFILES/$pkg" ]]; then
    die "Package dir not found: $DOTFILES/$pkg"
  fi
  local conflicts
  cd "$DOTFILES"
  # dry-run to find conflicts
  conflicts=$(stow --no-folding -nv -t "$target" "$pkg" 2>&1 \
    | awk '/existing target is neither a link nor a directory:/{print $NF}')
  if [[ -n "$conflicts" ]]; then
    warn "Removing conflicts for $pkg"
    while IFS= read -r f; do rm -rf "$target/$f"; done <<< "$conflicts"
  fi
  stow --no-folding -t "$target" "$pkg"
  log "Stowed: $pkg → $target"
}

restow_pkg() {
  local pkg="$1" target="${2:-$HOME}"
  if _stow_blocked "$pkg"; then
    die "Refusing to restow non-package dir: $pkg"
  fi
  cd "$DOTFILES"
  stow --no-folding -D -t "$target" "$pkg" 2>/dev/null || true
  stow_pkg "$pkg" "$target"
}

# ── zsh plugins via git ────────────────────────────────────────────────────
install_zsh_plugin() {
  local repo="$1" name="${2:-$(basename "$1")}"
  local dest="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"
  if [[ -d "$dest" ]]; then
    log "Plugin already present: $name"
    git -C "$dest" pull -q
  else
    git clone --depth=1 "https://github.com/$repo" "$dest"
  fi
}

# ── Oh My Zsh ─────────────────────────────────────────────────────────────
install_omz() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then log "OMZ already installed"; return; fi
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  install_zsh_plugin zsh-users/zsh-autosuggestions
  install_zsh_plugin zsh-users/zsh-syntax-highlighting
}

# ── set default shell ──────────────────────────────────────────────────────
set_zsh_default() {
  local zsh_path
  zsh_path=$(command -v zsh) || die "zsh not found"
  if [[ "$SHELL" != "$zsh_path" ]]; then
    log "Setting zsh as default shell"
    if is_termux; then chsh -s zsh
    else chsh -s "$zsh_path" "$USER"
    fi
  fi
}

# ── npm globals ────────────────────────────────────────────────────────────
install_npm_globals() {
  has_cmd jq || die "jq required"
  local npm_prefix="$HOME/.npm-global"
  mkdir -p "$npm_prefix"
  npm config set prefix "$npm_prefix"
  mapfile -t pkgs < <(jq -r '.npm[].name' "$PKGS_JSON")
  [[ ${#pkgs[@]} -gt 0 ]] && npm install -g "${pkgs[@]}"
}

# ── yazi plugins & flavors via ya pkg ──────────────────────────────────────
# Plugins/flavors are declared in ~/.config/yazi/package.toml and installed
# at runtime into ~/.config/yazi/plugins/ and ~/.config/yazi/flavors/.
# They are NOT stowed — .stowrc ignores those dirs.
install_yazi_pkgs() {
  local pkg_toml="$HOME/.config/yazi/package.toml"
  if ! has_cmd ya; then
    warn "ya not found — skipping yazi plugin install"
    return
  fi
  if [[ ! -f "$pkg_toml" ]]; then
    warn "No package.toml at $pkg_toml — skipping yazi plugin install"
    return
  fi
  log "Installing yazi plugins & flavors via ya pkg"
  ya pkg install
}
