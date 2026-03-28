{ ... }:

{
  system.stateVersion = "24.05";

  # nix-on-droid owns the mobile user environment directly.
  home-manager.config = {
    imports = [
      ../modules/core
      ../modules/programs
      ../modules/programs/yazi
      ../modules/android/packages.nix
    ];

  };
}
