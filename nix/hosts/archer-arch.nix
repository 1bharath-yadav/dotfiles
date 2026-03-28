{ ... }:

{
  imports = [
    ../modules/core
    ../modules/programs
    ../modules/linux/packages.nix
  ];

  home.username = "archer";
  home.homeDirectory = "/home/archer";
}
