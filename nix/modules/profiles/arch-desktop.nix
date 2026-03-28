# profiles/arch-desktop.nix — Arch Linux desktop packages (Nix Home Manager)
#
# ┌─────────────────────────────────────────────────────────────────────────┐
# │  PACKAGE OWNERSHIP BOUNDARY                                             │
# │                                                                         │
# │  PACMAN owns (do NOT add here):                                         │
# │    kernel, linux-headers, mesa, vulkan drivers, pipewire, wireplumber   │
# │    hyprland, wayland, xdg-desktop-portal-hyprland, sddm                 │
# │    bluetooth (bluez), networkmanager, grub, systemd                     │
# │    AUR-only packages (chaotic-aur): e.g. zen-browser, hyprshot          │
# │    anything requiring /etc integration or a systemd service              │
# │                                                                         │
# │  NIX HOME MANAGER owns (this file + imports):                           │
# │    all user-level GUI apps, CLI tools, fonts, dev tools                 │
# └─────────────────────────────────────────────────────────────────────────┘
{ pkgs, ... }:

{
  imports = [ ./common-linux.nix ];

  home.packages = with pkgs; [
    # ── Arch/desktop-specific CLI (NOT in core — needs audio/display) ────────────
    alsa-utils          # amixer, aplay
    pamixer             # pulseaudio/pipewire volume control
    ueberzugpp          # image preview in terminal (needs Wayland/X)
    nvtopPackages.intel # GPU monitor (Intel)
    slirp4netns         # rootless container networking
    pyprland            # hyprland plugin daemon
    scrcpy              # Android screen mirror
    systemctl-tui       # systemd TUI
    desktop-file-utils  # update-desktop-database for Nix .desktop files
    nix-index           # nix-locate (needed by pay-respects)
    pay-respects        # suggest correct command when you typo
    ethtool             # network card settings
    btop
    htop
    lazydocker
    lazysql
    android-tools

    # ── GUI apps ─────────────────────────────────────────────────────────────────
    anki
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.filelight
    kdePackages.gwenview
    kdePackages.kamoso
    kdePackages.kdeconnect-kde
    kdePackages.konsole
    kdePackages.partitionmanager
    feh
    foliate
    google-chrome
    gparted
    libreoffice-still
    mplayer
    mpv
    obs-studio
    obsidian
    proton-vpn
    qgis
    rclone-browser
    vscode
    zed-editor

    # ── Fonts ─────────────────────────────────────────────────────────────────────
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
