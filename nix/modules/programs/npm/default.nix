{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_25
    pnpm
  ];

  programs.npm = {
    enable = true;
    package = pkgs.nodejs_25;
  };
}