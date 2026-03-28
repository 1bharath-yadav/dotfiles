{ pkgs, ... }:
{
  home.packages = with pkgs; [ yazi ];
  xdg.configFile."yazi".source = ./config;
}
