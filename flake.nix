{
  description = "Unified dotfiles: Home Manager (arch + wsl) with declarative system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      forLinux     = lib.genAttrs linuxSystems;

      user = "archer";

      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # ── Home Manager hosts ───────────────────────────────────────────────
      # Add a new machine: one entry here, a host file in nix/hosts/.
      homeHosts = {
        archer-arch = {
          system        = "x86_64-linux";
          module        = ./nix/hosts/archer-arch.nix;
          homeDirectory = "/home/${user}";
        };
        archer-wsl = {
          system        = "x86_64-linux";
          module        = ./nix/hosts/archer-wsl.nix;
          homeDirectory = "/home/${user}";
        };
      };

      mkHome = _: { system, module, homeDirectory }:
        home-manager.lib.homeManagerConfiguration {
          pkgs    = pkgsFor system;
          modules = [
            module
            { home = { username = user; inherit homeDirectory; }; }
          ];
          extraSpecialArgs = { inherit inputs user homeDirectory; };
        };

      standaloneHomes = lib.mapAttrs mkHome homeHosts;

      # ── System packages (Arch root profile) ─────────────────────────────
      # Applied by: sudo nix/system/apply.sh  (or alias: sys-nix-apply)
      # These are NOT Home Manager packages; they live in /nix/var/nix/profiles/system.
      systemPackages = pkgs: import ./nix/system/arch-system.nix { inherit pkgs; };

    in
    {
      # nix fmt
      formatter = forLinux (system: (pkgsFor system).nixfmt-rfc-style);

      # nix develop (for working on flake itself)
      devShells = forLinux (system: {
        default = (pkgsFor system).mkShell {
          packages = with (pkgsFor system); [ git nixfmt-rfc-style ];
        };
      });

      # User environments: nh home switch / home-manager switch --flake .#archer-arch
      homeConfigurations = standaloneHomes // {
        # Convenience aliases (same config, alternate lookup keys)
        "archer@arch"      = standaloneHomes.archer-arch;
        "archer@zero-book" = standaloneHomes.archer-arch;
        "archer@wsl"       = standaloneHomes.archer-wsl;
      };

      # System package set — inspectable via: nix eval .#systemPackages.x86_64-linux
      # Applied imperatively to root profile by nix/system/apply.sh
      systemPackages = forLinux (system:
        systemPackages (pkgsFor system)
      );
    };
}
