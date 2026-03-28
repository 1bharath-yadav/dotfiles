{ ... }:

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
}
