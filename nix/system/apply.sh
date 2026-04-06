#!/usr/bin/env bash
# nix/system/apply.sh — apply declarative system Nix packages on Arch Linux
# Reads nix/system/arch-system.nix and installs packages into the root profile.
# Idempotent: safe to re-run; only installs what changed.
#
# Usage:
#   sudo bash nix/system/apply.sh          # from dotfiles root
#   sys-nix-apply                           # alias from ~/.local/bin
set -euo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SYSTEM_NIX="$DOTFILES/nix/system/arch-system.nix"
PROFILE="/nix/var/nix/profiles/system"

log()  { printf "\033[32m==>\033[0m %s\n" "$*"; }
die()  { printf "\033[31m!!!\033[0m %s\n" "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo $0"
[[ -f "$SYSTEM_NIX" ]] || die "Not found: $SYSTEM_NIX"

command -v nix >/dev/null 2>&1 || die "nix not found"

# Build the package list expression inline from the .nix file
# arch-system.nix returns a list [ pkgs.x pkgs.y ... ]
log "Evaluating $SYSTEM_NIX"
PKGS_JSON=$(nix eval --json --impure --expr "
  let pkgs = import <nixpkgs> { config.allowUnfree = true; };
  in map (p: p.name) (import \"$SYSTEM_NIX\" { inherit pkgs; })
")

readarray -t PKG_NAMES < <(echo "$PKGS_JSON" | tr -d '[]"' | tr ',' '\n' | xargs -n1)

log "Installing ${#PKG_NAMES[@]} system packages into $PROFILE"

# Build store paths first (single nix build pass)
STORE_PATHS=$(nix build --no-link --print-out-paths --impure --expr "
  let pkgs = import <nixpkgs> { config.allowUnfree = true; };
  in pkgs.buildEnv {
    name = \"archer-system\";
    paths = import \"$SYSTEM_NIX\" { inherit pkgs; };
  }
")

log "Linking profile: $PROFILE -> $STORE_PATHS"
nix-env -p "$PROFILE" --set "$STORE_PATHS"

# ── Wire system profile into global PATH + XDG_DATA_DIRS ──────────────────
# /etc/profile.d/nix-system.sh  → login shells (zsh, bash, sh)
# /etc/environment               → pam_env (SDDM, greeters — pre-session)
PROFILE_D="/etc/profile.d/nix-system.sh"
ENV_FILE="/etc/environment"

log "Writing $PROFILE_D"
cat > "$PROFILE_D" <<'PROFILE_D_EOF'
# Managed by dotfiles: nix/system/apply.sh — do not edit manually.
export PATH="/nix/var/nix/profiles/system/bin:$PATH"
export XDG_DATA_DIRS="/nix/var/nix/profiles/system/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
PROFILE_D_EOF
chmod 644 "$PROFILE_D"

# Wire root's sudo secure_path so `sudo btop` etc. resolve without full path
SUDOERS_D="/etc/sudoers.d/nix-system-path"
if [[ ! -f "$SUDOERS_D" ]]; then
  log "Writing $SUDOERS_D (adds system profile to sudo secure_path)"
  echo 'Defaults secure_path="/nix/var/nix/profiles/system/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' > "$SUDOERS_D"
  chmod 440 "$SUDOERS_D"
  visudo -c -f "$SUDOERS_D" || { rm "$SUDOERS_D"; die "sudoers syntax error — removed $SUDOERS_D"; }
else
  log "$SUDOERS_D already exists — skipping"
fi

if ! grep -q "nix/var/nix/profiles/system/share" "$ENV_FILE" 2>/dev/null; then
  log "Patching $ENV_FILE for pam_env / SDDM"
  if grep -q "^XDG_DATA_DIRS=" "$ENV_FILE" 2>/dev/null; then
    sed -i 's|^XDG_DATA_DIRS=.*|XDG_DATA_DIRS=/nix/var/nix/profiles/system/share:/nix/var/nix/profiles/default/share:/home/archer/.nix-profile/share:/usr/local/share:/usr/share|' "$ENV_FILE"
  else
    echo "XDG_DATA_DIRS=/nix/var/nix/profiles/system/share:/nix/var/nix/profiles/default/share:/home/archer/.nix-profile/share:/usr/local/share:/usr/share" >> "$ENV_FILE"
  fi
else
  log "$ENV_FILE already has system profile — skipping"
fi

log "Done. To use tools immediately (no re-login): source /etc/profile.d/nix-system.sh"
