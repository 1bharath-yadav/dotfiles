{ ... }:

{
  system.stateVersion = "24.05";

  # nix-on-droid owns the mobile user environment directly.
  home-manager.config = {
    imports = [
      ../modules/programs
      ../modules/packages/1.core-packages.nix
      ../modules/packages/2.droid-packages.nix
    ];

  };
}
