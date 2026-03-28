{ pkgs, ... }:

{
  imports = [ ../programs/yazi ];

  home.packages = with pkgs; [
    yazi
  ];
}
