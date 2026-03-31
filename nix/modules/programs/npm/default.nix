{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_25
    nodePackages.pnpm

  ];

  programs.npm = {
    enable = true;
    package = pkgs.nodejs_latest;
  };
}
