{ config, ... }:
{
  # mkOutOfStoreSymlink: ~/.config/nvim → live dotfiles path (edits = instant, no rebuild)
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/nix/modules/programs/nvim/config";
}
