{ config, lib, ... }:
let
  dotfilesDir = config.home.homeDirectory + "/.dotfiles";
  scriptsDir = dotfilesDir + "/nix/modules/programs/bin/scripts";
  lettaPkgDir = dotfilesDir + "/libs/letta_assistant";
in
{
  # All scripts: copy to ~/.local/bin
  home.file.".local/bin" = {
    source     = ./scripts;
    executable = true;
    recursive  = true;
  };

  # Letta package source: symlink for live-editing (development)
  home.file.".cache/letta_assistant_src" = {
    source = config.lib.file.mkOutOfStoreSymlink lettaPkgDir;
  };
}
