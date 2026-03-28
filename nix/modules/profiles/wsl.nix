# profiles/wsl.nix — WSL2 Ubuntu packages (Nix Home Manager, no GUI/audio)
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PACKAGE OWNERSHIP BOUNDARY                                             │
# │                                                                         │
# │  APT owns: kernel, WSL integration, systemd, network stack              │
# │  NIX HOME MANAGER owns (this file): user-level CLI tools               │
# └─────────────────────────────────────────────────────────────────────────┘
{ pkgs, ... }:

{
  imports = [ ./common-linux.nix ];

  home.packages = with pkgs; [
    btop
    htop
    nix-index
    pay-respects
    yt-dlp
  ];
}
