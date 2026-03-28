{ config, ... }:
{
  programs.starship.enable = true;

  # mkOutOfStoreSymlink: edits to starship.toml take effect instantly, no rebuild
  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/nix/modules/programs/starship/starship.toml";
}
