{ ... }:

{
  imports = [
    ../modules/core
    ../modules/programs
    ../modules/profiles/wsl.nix
  ];

  home.username = "archer";
  home.homeDirectory = "/home/archer";
}
