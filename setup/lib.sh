#!/usr/bin/env bash
# setup/lib.sh — shared helpers for all OS setup scripts
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
ARCH_PACKAGES_DIR="$DOTFILES/setup/arch/packages"
END4DOTS="${END4DOTS:-$HOME/.local/share/end4dots}"

# ── logging ────────────────────────────────────────────────────────────────
log()  { printf "\033[32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[33m!!>\033[0m %s\n" "$*"; }
die()  { printf "\033[31m!!!\033[0m %s\n" "$*" >&2; exit 1; }

# ── guards ─────────────────────────────────────────────────────────────────
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }
has_cmd()     { command -v "$1" >/dev/null 2>&1; }

# ── OS detection ───────────────────────────────────────────────────────────
is_termux() { [[ -d /data/data/com.termux ]]; }
is_wsl()    { grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; }
is_arch()   { [[ -f /etc/arch-release ]]; }
is_ubuntu() { grep -qi ubuntu /etc/os-release 2>/dev/null; }

detect_os() {
  if   is_termux; then echo termux
  elif is_wsl;    then echo wsl
  elif is_arch;   then echo arch
  elif is_ubuntu; then echo ubuntu
  else die "Unsupported OS"; fi
}

normalize_os() {
  local os="${1:-auto}"
  if [[ "$os" == auto || -z "$os" ]]; then
    detect_os
  else
    printf '%s\n' "$os"
  fi
}

nix_files_changed() {
  local last_gen_commit
  last_gen_commit=$(cat "$HOME/.local/state/home-manager/last-switch" 2>/dev/null || echo "")
  if [[ -z "$last_gen_commit" ]]; then return 0; fi
  git -C "$DOTFILES" diff --name-only HEAD "$last_gen_commit" -- '*.nix' flake.lock \
    | grep -q . 2>/dev/null && return 0 || return 1
}

stamp_hm_switch() {
  mkdir -p "$HOME/.local/state/home-manager"
  git -C "$DOTFILES" rev-parse HEAD > "$HOME/.local/state/home-manager/last-switch" 2>/dev/null || true
}

manifest_lines() {
  local file="$1"
  grep -v '^#' "$file" 2>/dev/null | grep -v '^$' | awk '{print $1}' || true
}

arch_native_package_files() {
  printf '%s\n' \
    "$ARCH_PACKAGES_DIR/native-core.txt" \
    "$ARCH_PACKAGES_DIR/native-desktop.txt" \
    "$ARCH_PACKAGES_DIR/native-services.txt"
}

arch_aur_package_file() {
  printf '%s\n' "$ARCH_PACKAGES_DIR/aur.txt"
}

install_nix_if_missing() {
  if has_cmd nix; then
    log "Nix already installed"
    return
  fi
  require_cmd curl
  log "Installing Nix"
  bash -lc 'curl -L https://nixos.org/nix/install | sh -s -- --daemon'
}


# ── yazi plugins & flavors via ya pkg ──────────────────────────────────────
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
    arch)        echo archer-arch ;;
    wsl|ubuntu)  echo archer-wsl  ;;
    *) die "Unsupported OS for Home Manager: $1" ;;
  esac
}


install_bootstrap_packages() {
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
      sudo apt-get install -y curl git xz-utils zsh
      ;;
    termux)
      log "Updating pkg"
      pkg update -y && pkg upgrade -y
      pkg install -y git zsh curl
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
  { echo "experimental-features = nix-command flakes"
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
    nix run github:nix-community/home-manager -- switch --flake "$DOTFILES#$host" 2>&1 \
      | grep -E '^(=>|activating|error|warning)' || true
  fi
  stamp_hm_switch
  install_yazi_pkgs
}

apply_arch_packages() {
  require_cmd sudo

  local native_pkgs=()
  local aur_file file

  while read -r file; do
    [[ -f "$file" ]] || continue
    while read -r pkg; do
      [[ -n "$pkg" ]] || continue
      native_pkgs+=("$pkg")
    done < <(manifest_lines "$file")
  done < <(arch_native_package_files)

  if [[ ${#native_pkgs[@]} -gt 0 ]]; then
    log "Applying Arch native packages"
    sudo pacman -Syu --needed --noconfirm "${native_pkgs[@]}"
  fi

  aur_file="$(arch_aur_package_file)"
  if [[ -f "$aur_file" ]] && has_cmd yay; then
    mapfile -t aur_pkgs < <(manifest_lines "$aur_file")
    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
      log "Applying AUR packages"
      yay -S --needed --noconfirm "${aur_pkgs[@]}"
    fi
  elif [[ -f "$aur_file" ]]; then
    warn "yay not found — skipping AUR manifest $aur_file"
  fi
}

apply_system_nix() {
  local os="$1"
  [[ "$os" == arch ]] || { warn "system nix apply is Arch-only"; return 0; }
  require_cmd sudo
  sudo bash "$DOTFILES/nix/system/apply.sh"
}

sync_external_tools() {
  bash "$DOTFILES/nix/modules/programs/bin/scripts/sync-external-tools"
}

sync_end4dots() {
  local os="$1"
  [[ "$os" == arch ]] || return 0
  [[ -d "$END4DOTS" ]] || return 0

  log "Syncing end4dots (two-branch: main=upstream mirror, archer=your changes)"

  cd "$END4DOTS"
  git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/end-4/dots-hyprland.git

  local stashed=false
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git stash push -q -m "update.sh auto-stash $(date +%s)"
    stashed=true
  fi

  git checkout main -q
  git fetch upstream -q
  if ! git rebase upstream/main -q; then
    warn "Rebase conflict on end4dots main — aborting"
    git rebase --abort 2>/dev/null || true
    git checkout archer -q
    $stashed && git stash pop -q || true
    return 1
  fi
  git push origin main --force -q 2>/dev/null || true

  git checkout archer -q
  if ! git rebase main -q; then
    warn "Rebase conflict on end4dots archer branch"
    return 1
  fi
  git push origin archer --force -q 2>/dev/null || true
  $stashed && git stash pop -q || true

  "$END4DOTS/setup" install

  local hconf="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$hconf" ]] && ! grep -q 'source=custom/env.conf' "$hconf"; then
    cp "$END4DOTS/dots/.config/hypr/hyprland.conf" "$hconf"
    log "Re-patched hyprland.conf with source=custom/env.conf"
  fi

  find "$HOME/.config/hypr" -maxdepth 1 -name '*.new' -delete 2>/dev/null || true
}

reload_user_session() {
  local os="$1"
  if [[ "$os" == arch ]] && has_cmd hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload -q
    log "Hyprland config reloaded"
    systemctl --user import-environment --all 2>/dev/null || true
    dbus-update-activation-environment --systemd --all 2>/dev/null || true
  fi
}

apply_component() {
  local target="$1"
  local os
  os="$(normalize_os "${2:-auto}")"

  case "$target" in
    pacman)
      case "$os" in
        arch) apply_arch_packages ;;
        wsl|ubuntu) install_bootstrap_packages "$os" ;;
        termux) install_bootstrap_packages termux ;;
      esac
      ;;
    home)
      case "$os" in
        termux) warn "Home Manager not used on Termux" ;;
        *) apply_home_manager "$os" ;;
      esac
      ;;
    system)
      apply_system_nix "$os"
      ;;
    external)
      sync_external_tools
      ;;
    all)
      case "$os" in
        arch)
          apply_arch_packages
          apply_home_manager "$os"
          apply_system_nix "$os"
          sync_external_tools
          reload_user_session "$os"
          ;;
        wsl|ubuntu)
          install_bootstrap_packages "$os"
          apply_home_manager "$os"
          sync_external_tools
          ;;
        termux)
          install_bootstrap_packages termux
          bash "$DOTFILES/setup/termux/bootstrap.sh"
          ;;
      esac
      ;;
    *) die "Unknown apply target: $target" ;;
  esac
}

overall_update() {
  local os
  os="$(normalize_os "${1:-auto}")"

  sync_end4dots "$os"

  case "$os" in
    arch)
      if [[ "${PACMAN_FORCE:-0}" == "1" ]]; then
        apply_arch_packages
      fi
      if [[ "${NIX_FORCE:-0}" == "1" ]] || nix_files_changed; then
        apply_home_manager "$os"
      else
        log "No .nix changes since last switch — skipping Home Manager rebuild (NIX_FORCE=1 to override)"
      fi
      if [[ "${SYSTEM_NIX_FORCE:-0}" == "1" ]]; then
        apply_system_nix "$os"
      fi
      if [[ "${EXTERNAL_FORCE:-0}" == "1" ]]; then
        sync_external_tools
      fi
      reload_user_session "$os"
      ;;
    wsl|ubuntu)
      if [[ "${NIX_FORCE:-0}" == "1" ]] || nix_files_changed; then
        apply_home_manager "$os"
      else
        log "No .nix changes since last switch — skipping Home Manager rebuild (NIX_FORCE=1 to override)"
      fi
      if [[ "${EXTERNAL_FORCE:-0}" == "1" ]]; then
        sync_external_tools
      fi
      ;;
    termux)
      bash "$DOTFILES/setup/termux/bootstrap.sh"
      ;;
  esac
}
