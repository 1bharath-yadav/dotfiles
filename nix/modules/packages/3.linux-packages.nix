# Linux desktop packages (Arch Home Manager host)
{ pkgs, ... }:

{
  imports = [
    ../programs/hyprland
    ../programs/kitty
    ../programs/lazygit
    ../programs/yazi
  ];

  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    lazygit
    yazi

    alsa-utils
    pamixer
    ueberzugpp
    nvtopPackages.intel
    slirp4netns
    pyprland
    scrcpy
    systemctl-tui
    desktop-file-utils
    nh
    nix-output-monitor
    nix-index
    pay-respects
    ethtool
    btop
    htop
    lazydocker
    lazysql
    android-tools

    antigravity
    anki
    feh
    foliate
    koodo-reader
    google-chrome
    gparted
    libreoffice-still
    mplayer
    mpv
    nchat
    obs-studio
    obsidian
    proton-vpn
    qgis
    rclone-browser
    vscode
    zed-editor
    whisper-cpp-vulkan
    gemini-cli
    zenity

    fira-code
    fira-mono
    fira-sans
    font-awesome
    jetbrains-mono
    lato
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-color-emoji
    roboto
    terminus_font
  ];
}
