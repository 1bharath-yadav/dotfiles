{ pkgs, ... }:
{
  home.packages = with pkgs; [ lazygit ];
  xdg.configFile."lazygit".source = ./config;
}
