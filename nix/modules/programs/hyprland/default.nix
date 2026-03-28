{ config, lib, ... }:

{
  xdg.configFile."hypr/custom".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/nix/modules/programs/hyprland/config/custom";

  home.activation.prepareHyprlandCustomDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -d "${config.xdg.configHome}/hypr/custom" ] && [ ! -L "${config.xdg.configHome}/hypr/custom" ]; then
      rm -rf "${config.xdg.configHome}/hypr/custom"
    fi
  '';
}
