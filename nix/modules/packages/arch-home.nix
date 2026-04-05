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
    lazygit yazi nh nix-index nix-output-monitor pay-respects lazydocker lazysql systemctl-tui
    alsa-utils android-tools pamixer pyprland slirp4netns socat ueberzugpp
    antigravity codex codex-acp gemini-cli obsidian vscode zed-editor
    fira-code fira-mono fira-sans font-awesome jetbrains-mono lato
    nerd-fonts.droid-sans-mono nerd-fonts.fira-code nerd-fonts.meslo-lg nerd-fonts.symbols-only
    noto-fonts noto-fonts-color-emoji roboto terminus_font
  ];
}