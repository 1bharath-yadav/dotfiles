{ pkgs, ... }:

{
  imports = [
    ../programs/lazygit
    ../programs/yazi
  ];

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    android-tools
    anki
    btop
    google-chrome
    htop
    lazydocker
    lazysql
    neomutt
    obs-studio
    obsidian
    pay-respects
    scrcpy
    systemctl-tui
    yt-dlp
    zed-editor
  ];
}
