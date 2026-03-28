{
  description = "Dotfiles with Home Manager for Linux userland and nix-on-droid for Android";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, nix-on-droid, ... }:
    let
      mkHome = system: module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [ module ];
          extraSpecialArgs = { inherit inputs; };
        };
    in {
      homeConfigurations = {
        archer-arch = mkHome "x86_64-linux" ./nix/hosts/archer-arch.nix;
        archer-wsl = mkHome "x86_64-linux" ./nix/hosts/archer-wsl.nix;
      };

      nixOnDroidConfigurations = {
        archer-phone = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            config.allowUnfree = true;
          };
          modules = [ ./nix/hosts/archer-phone.nix ];
        };
      };
    };
}
