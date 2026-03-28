{ ... }:

{
  imports = [
    ../modules/core
    ../modules/programs
    ../modules/profiles/arch-desktop.nix
  ];

  home.username = "archer";
  home.homeDirectory = "/home/archer";
}
