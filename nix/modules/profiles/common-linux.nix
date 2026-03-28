{ ... }:

{
  imports = [
    ../programs/lazygit
    ../programs/yazi
  ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;
}
