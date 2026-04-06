{ pkgs, ... }:

{
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/bin"
    "$HOME/.local/bin"
    "/nix/var/nix/profiles/system/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nix = {
    package = pkgs.nix;
    settings = { };
  };

  home.packages = with pkgs; [
    bat eza fd file fzf ripgrep trash-cli tree unzip zip zoxide
    cmark fx jq jqp pandoc
    delta direnv gh git-lfs gitui nix-direnv shellcheck
    neovim opencode
    ffmpegthumbnailer mediainfo yt-dlp
    aria2 httpie nmap rclone xh
    comma deadnix nix-tree statix
    asciinema chafa distrobox eget fastfetch fdupes glow parallel pngquant resvg starship tealdeer
  ];
}