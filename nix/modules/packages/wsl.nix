{ pkgs, ... }:

{
  imports = [
    ../programs/lazygit
    ../programs/yazi
  ];

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    lazygit yazi nh nix-index nix-output-monitor pay-respects htop
  ];
}