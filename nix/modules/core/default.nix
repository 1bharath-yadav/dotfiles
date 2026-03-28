{ pkgs, ... }:

{
  imports = [ ./packages.nix ];
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nix = {
    package = pkgs.nix;
    settings = {
      # Keep user-level Nix settings minimal; restricted cache trust settings
      # belong in the system daemon config on non-NixOS.
    };
  };
}
