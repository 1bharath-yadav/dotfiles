{ config, ... }:
{
  # mkOutOfStoreSymlink: ~/.config/lazygit → live dotfiles path (edits = instant, no rebuild)
  xdg.configFile."lazygit".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/nix/modules/programs/lazygit/config";
}
