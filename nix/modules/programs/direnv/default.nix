# nix/modules/programs/direnv/default.nix
# nix-direnv: fast direnv integration — auto-activates .envrc on cd
# Usage in any project dir:
#   echo "use flake" > .envrc && direnv allow
#   echo "use devenv" > .envrc && direnv allow   (with devenv.nix in the dir)
{ config, lib, ... }:

let
  direnvConfigDir = "${config.xdg.configHome}/direnv";
  direnvToml = "${direnvConfigDir}/direnv.toml";
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # faster cached nix shell loading; replaces bare direnv package
    silent = true;            # suppress "direnv: loading .envrc" on every cd
  };

  home.activation.prepareDirenvConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -e "${direnvToml}" ] && [ ! -L "${direnvToml}" ]; then
      backup="${direnvToml}.pre-home-manager"
      if [ -e "$backup" ] || [ -L "$backup" ]; then
        backup="${direnvToml}.pre-home-manager.$(date +%s)"
      fi
      mv "${direnvToml}" "$backup"
    fi
  '';
}
