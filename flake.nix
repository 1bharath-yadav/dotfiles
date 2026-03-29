{
  description = "Unified dotfiles: Home Manager + nix-on-droid";

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

    # optional but recommended for scaling
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-on-droid, flake-utils, ... }:
    let
      lib = nixpkgs.lib;

      # supported systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # helper: generate pkgs
      pkgsFor = system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # helper: home-manager builder
      mkHome = { system, user, module }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [ module ];
          extraSpecialArgs = { inherit inputs user; };
        };

    in
    flake-utils.lib.eachSystem systems (system: {
      # this fixes `nix flake show`
      packages.default = (pkgsFor system).hello;

      devShells.default = (pkgsFor system).mkShell {
        buildInputs = with (pkgsFor system); [ git nixfmt ];
      };
    })
    //
    {
      # -------------------------
      # HOME MANAGER CONFIGS
      # -------------------------
      homeConfigurations = rec {
        archer-arch = mkHome {
          system = "x86_64-linux";
          user = "archer";
          module = ./nix/hosts/archer-arch.nix;
        };

        archer-wsl = mkHome {
          system = "x86_64-linux";
          user = "archer";
          module = ./nix/hosts/archer-wsl.nix;
        };

        "archer@arch" = archer-arch;
        "archer@wsl" = archer-wsl;
      };

      # -------------------------
      # NIX-ON-DROID
      # -------------------------
      nixOnDroidConfigurations = {
        archer-phone = nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = pkgsFor "aarch64-linux";

          modules = [
            ./nix/hosts/archer-phone.nix
          ];

          # important for HM integration
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
