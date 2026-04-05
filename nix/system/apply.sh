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

log "System packages applied. Add $PROFILE/bin to root PATH if needed:"
log "  echo 'export PATH=$PROFILE/bin:\$PATH' | sudo tee /etc/profile.d/nix-system.sh"
