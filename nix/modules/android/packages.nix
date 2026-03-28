{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Android specific packages can be added here
    # (e.g. termux specific tools)
  ];
}
