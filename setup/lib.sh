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




# ── yazi plugins & flavors via ya pkg ──────────────────────────────────────
# When Home Manager owns Yazi plugins/flavors, auto-running `ya pkg install`
# will clash with the managed symlinked directories. In that case we skip the
# runtime install and let HM own the vendored plugin/flavor set.
install_yazi_pkgs() {
  local yazi_dir="$HOME/.config/yazi"
  local pkg_toml="$HOME/.config/yazi/package.toml"
  if ! has_cmd ya; then
    warn "ya not found — skipping yazi plugin install"
    return
  fi
  if [[ -L "$yazi_dir" || -L "$pkg_toml" || ! -w "$yazi_dir" || ! -w "$pkg_toml" ]]; then
    warn "Yazi config is read-only — skipping yazi plugin install"
    return
  fi
  if [[ ! -f "$pkg_toml" ]]; then
    warn "No package.toml at $pkg_toml — skipping yazi plugin install"
    return
  fi
  if find "$yazi_dir/plugins" "$yazi_dir/flavors" -mindepth 1 -maxdepth 1 -type l 2>/dev/null | grep -q .; then
    warn "Yazi plugins/flavors are Home Manager-managed — skipping ya pkg install"
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
      sudo pacman -Syu --needed --noconfirm base-devel curl git zsh xz
      ;;
    wsl|ubuntu)
      require_cmd sudo
      log "Updating apt"
      sudo apt-get update -y
      log "Installing Ubuntu-in-WSL bootstrap packages"
      sudo apt-get install -y curl git xz-utils zsh
      ;;
    *)
      die "Unsupported OS for bootstrap: $1"
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
  if has_cmd nh; then
    nh home switch "$DOTFILES" -c "$host"
  else
    nix run github:nix-community/home-manager -- switch --flake "$DOTFILES#$host"
  fi
  install_yazi_pkgs
}
