# nix/system/arch-system.nix
# Declarative list of system-level Nix packages on Arch Linux.
#
# These are NOT Home Manager packages. They live in the root Nix profile:
#   /nix/var/nix/profiles/system -> /nix/store/...
#
# WHY a package belongs here instead of Home Manager:
#   - needs GPU / hardware access at the driver level (btop, nvtop)
#   - must be available before user session loads (e.g. in TTY / display manager)
#   - used by root or system services
#   - you explicitly want a system-wide binary all users share
#
# Apply with:
#   sudo nix/system/apply.sh          (from dotfiles root)
#   alias: sys-nix-apply              (installed by Home Manager to ~/.local/bin)
#
# Audit drift (system profile vs this file):
#   sys-nix-diff
#
{ pkgs }:

[
  # ── Monitoring / GPU ──────────────────────────────────────────────────────
  # Shared hardware-facing / heavy runtime tools belong in the system profile.
  pkgs.btop
  pkgs.clinfo
  pkgs.libva-utils
  pkgs.nvtopPackages.intel
  pkgs.vulkan-tools
  pkgs.whisper-cpp-vulkan

  # ── System-wide shells ────────────────────────────────────────────────────
  pkgs.zsh          # login shell — must be available before HM profile loads
  pkgs.bash

  # ── Core system tools (supplements pacman base) ───────────────────────────
  pkgs.git          # needed during bootstrap before HM is applied
  pkgs.curl
  pkgs.wget
  pkgs.htop
  pkgs.lsof
  pkgs.strace
  pkgs.pciutils
  pkgs.usbutils
]
