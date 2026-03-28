#!/usr/bin/env bash
# setup/lib.sh — shared helpers for all OS setup scripts
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# ── logging ────────────────────────────────────────────────────────────────
log()  { printf "\033[32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[33m!!>\033[0m %s\n" "$*"; }
die()  { printf "\033[31m!!!\033[0m %s\n" "$*" >&2; exit 1; }

# ── guards ─────────────────────────────────────────────────────────────────
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
has_cmd()     { command -v "$1" >/dev/null 2>&1; }

# ── OS detection ───────────────────────────────────────────────────────────
is_wsl()    { grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; }
is_arch()   { [[ -f /etc/arch-release ]]; }
is_ubuntu() { grep -qi ubuntu /etc/os-release 2>/dev/null; }

detect_os() {
  if is_wsl;  then echo wsl
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
  conflicts=$(
    {
      stow --no-folding -nv -t "$target" "$pkg" 2>&1 || true
    } | awk '
          /existing target is neither a link nor a directory:/ { print $NF }
          /cannot stow .* over existing target / {
            target = $0
            sub(/^.* over existing target /, "", target)
            sub(/ since neither a link nor a directory.*$/, "", target)
            print target
          }
        '
  )
  if [[ -n "$conflicts" ]]; then
    warn "Removing conflicts for $pkg"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ "$f" = /* ]]; then
        rm -rf "$f"
      else
        rm -rf "$target/$f"
      fi
    done <<< "$conflicts"
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

unstow_pkg_if_present() {
  local pkg="$1" target="${2:-$HOME}"
  _stow_blocked "$pkg" && return 0
  [[ -d "$DOTFILES/$pkg" ]] || return 0
  (cd "$DOTFILES" && stow --no-folding -D -t "$target" "$pkg") 2>/dev/null || true
}

# ── yazi plugins & flavors via ya pkg ──────────────────────────────────────
# Plugins/flavors are declared in ~/.config/yazi/package.toml and installed
# at runtime into ~/.config/yazi/plugins/ and ~/.config/yazi/flavors/.
# They are NOT stowed.
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

host_name_for_os() {
  case "$1" in
    arch) echo archer-arch ;;
    wsl|ubuntu) echo archer-wsl ;;
    *) die "Unsupported OS for Home Manager: $1" ;;
  esac
}

install_system_pkgs() {
  case "$1" in
    arch)
      require_cmd sudo
      log "Installing Arch bootstrap packages"
      sudo pacman -Syu --needed --noconfirm base-devel curl git stow zsh xz
      ;;
    wsl|ubuntu)
      require_cmd sudo
      log "Updating apt"
      sudo apt-get update -y
      log "Installing Ubuntu-in-WSL bootstrap packages"
      sudo apt-get install -y curl git stow xz-utils zsh
      ;;
    *)
      die "Unsupported OS for bootstrap: $1"
      ;;
  esac
}



apply_stow_overlays() {
  case "$1" in
    arch)
      local pkg
      log "Stowing Arch overlays"
      for pkg in hypr kitty; do
        restow_pkg "$pkg"
      done
      ;;
    wsl|ubuntu)
      log "No stow overlays for Ubuntu in WSL"
      ;;
    *)
      die "Unsupported OS for stow overlays: $1"
      ;;
  esac
}

enable_nix_flakes() {
  local nix_conf="$HOME/.config/nix/nix.conf"
  mkdir -p "$(dirname "$nix_conf")"

  if [[ -f "$nix_conf" ]] && grep -q '^experimental-features = .*flakes' "$nix_conf"; then
    return
  fi

  {
    echo "experimental-features = nix-command flakes"
    echo "accept-flake-config = true"
  } >> "$nix_conf"
}

apply_home_manager() {
  local os="$1"
  local host
  host="$(host_name_for_os "$os")"

  if ! has_cmd nix; then
    warn "Nix not found — install Nix, then run: $DOTFILES/setup/main.sh $os"
    return
  fi

  enable_nix_flakes
  log "Applying Home Manager user environment"
  nix run github:nix-community/home-manager -- switch --flake "$DOTFILES#$host"
  install_yazi_pkgs
}
