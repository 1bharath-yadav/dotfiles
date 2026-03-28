# WSL2 Ubuntu packages (Nix Home Manager, no GUI/audio)
{ pkgs, ... }:

{
  imports = [
    ../programs/lazygit
    ../programs/yazi
  ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    lazygit
    yazi
    btop
    htop
    nh
    nix-output-monitor
    nix-index
    pay-respects
  ];
}
