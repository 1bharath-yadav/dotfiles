{ config, lib, pkgs, ... }:

let
  yaziConfigDir = "${config.xdg.configHome}/yazi";
in {
  home.packages = with pkgs; [ yazi ];

  xdg.configFile."yazi/init.lua".source = ./config/init.lua;
  xdg.configFile."yazi/keymap.toml".source = ./config/keymap.toml;
  xdg.configFile."yazi/theme.toml".source = ./config/theme.toml;
  xdg.configFile."yazi/yazi.toml".source = ./config/yazi.toml;

  home.activation.prepareYaziConfigDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "${yaziConfigDir}" ]; then
      rm -f "${yaziConfigDir}"
    fi
    mkdir -p "${yaziConfigDir}"
  '';

  home.activation.initializeYaziPackageToml = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    package_dst="${yaziConfigDir}/package.toml"

    if [ ! -e "$package_dst" ] || [ -L "$package_dst" ]; then
      rm -f "$package_dst"
      cp "${./config/package.toml}" "$package_dst"
      chmod u+rw "$package_dst"
    fi
  '';
}
