{ config, lib, ... }:

{
  xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/nix/modules/programs/kitty/config";

  home.activation.prepareKittyCustomDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -d "${config.xdg.configHome}/kitty" ] && [ ! -L "${config.xdg.configHome}/kitty" ]; then
      rm -rf "${config.xdg.configHome}/kitty"
    fi
  '';
}
