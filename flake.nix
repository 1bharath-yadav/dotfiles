{
  description = "Unified dotfiles: Home Manager for arch linux,wsl-linux and nix-on-droid";

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
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = lib.genAttrs systems;

      user = "archer";
      homeDirectory = "/home/${user}";

      pkgsFor = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      homeHosts = {
        archer-arch = {
          system = "x86_64-linux";
          module = ./nix/hosts/archer-arch.nix;
        };

        archer-wsl = {
          system = "x86_64-linux";
          module = ./nix/hosts/archer-wsl.nix;
        };
      };

      mkHome = _: { system, module }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            module
            {
              home = {
                username = user;
                inherit homeDirectory;
              };
            }
          ];
          extraSpecialArgs = { inherit inputs user homeDirectory; };
        };

      standaloneHomeConfigurations = lib.mapAttrs mkHome homeHosts;

    in
    {
      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [ git nixfmt ];
        };
      });

      homeConfigurations = standaloneHomeConfigurations // {
        "archer@arch" = standaloneHomeConfigurations.archer-arch;
        "archer@wsl" = standaloneHomeConfigurations.archer-wsl;
        "archer@zero-book" = standaloneHomeConfigurations.archer-arch;
      };

      nixOnDroidConfigurations = {
        archer-phone = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsFor "aarch64-linux";
          modules = [ ./nix/hosts/archer-phone.nix ];
          extraSpecialArgs = { inherit inputs user homeDirectory; };
        };
      };
    };
}
