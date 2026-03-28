{ config, lib, ... }:

let
  yaziConfigDir = "${config.xdg.configHome}/yazi";
  mkYaziEntries = dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.listToAttrs (builtins.map (name: {
      name = lib.removeSuffix ".yazi" name;
      value = dir + "/${name}";
    }) (builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries)));
  pluginNames = builtins.attrNames (mkYaziEntries ./config/plugins);
  flavorNames = builtins.attrNames (mkYaziEntries ./config/flavors);
in {
  programs.yazi = {
    enable = true;
    package = null;
    enableZshIntegration = true;
    shellWrapperName = "y";
    initLua = ./config/init.lua;
    keymap = builtins.fromTOML (builtins.readFile ./config/keymap.toml);
    settings = builtins.fromTOML (builtins.readFile ./config/yazi.toml);
    theme = builtins.fromTOML (builtins.readFile ./config/theme.toml);
    plugins = mkYaziEntries ./config/plugins;
    flavors = mkYaziEntries ./config/flavors;
  };

  home.activation.prepareYaziConfigDir = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "${yaziConfigDir}" ]; then
      rm -f "${yaziConfigDir}"
    fi
    mkdir -p "${yaziConfigDir}"
    mkdir -p "${yaziConfigDir}/plugins" "${yaziConfigDir}/flavors"
  '';

  home.activation.prepareYaziManagedEntries = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
${lib.concatMapStringsSep "\n" (name: ''
    if [ -e "${yaziConfigDir}/plugins/${name}.yazi" ] && [ ! -L "${yaziConfigDir}/plugins/${name}.yazi" ]; then
      rm -rf "${yaziConfigDir}/plugins/${name}.yazi"
    fi
'') pluginNames}
${lib.concatMapStringsSep "\n" (name: ''
    if [ -e "${yaziConfigDir}/flavors/${name}.yazi" ] && [ ! -L "${yaziConfigDir}/flavors/${name}.yazi" ]; then
      rm -rf "${yaziConfigDir}/flavors/${name}.yazi"
    fi
'') flavorNames}
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
