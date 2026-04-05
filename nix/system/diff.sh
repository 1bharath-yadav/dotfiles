#!/usr/bin/env bash
# nix/system/diff.sh — show drift between declared and actual system Nix profile
# Usage: bash nix/system/diff.sh
#        sys-nix-diff   (alias from ~/.local/bin)
set -euo pipefail

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SYSTEM_NIX="$DOTFILES/nix/system/arch-system.nix"
PROFILE="/nix/var/nix/profiles/system"

RED=$'\033[31m' GRN=$'\033[32m' YEL=$'\033[33m' RST=$'\033[0m'

build_declared() {
  nix build --no-link --print-out-paths --impure --expr "
    let pkgs = import <nixpkgs> { config.allowUnfree = true; };
    in pkgs.buildEnv {
      name = \"archer-system\";
      paths = import \"$SYSTEM_NIX\" { inherit pkgs; };
    }
  "
}

declared_path="$(build_declared)"

if [[ ! -e "$PROFILE" ]]; then
  echo "${YEL}No system profile found at $PROFILE${RST}"
  exit 1
fi

current_path="$(readlink -f "$PROFILE" 2>/dev/null || true)"

echo ""
echo "${YEL}==> System profile state:${RST}"
echo "  declared: $declared_path"
echo "  current : $current_path"

echo ""
if [[ "$declared_path" == "$current_path" ]]; then
  echo "${GRN}✓ system nix profile is in sync${RST}"
else
  echo "${RED}✗ system nix profile is out of sync${RST}"
  echo "${YEL}Run: sys-nix-apply${RST}"
fi
