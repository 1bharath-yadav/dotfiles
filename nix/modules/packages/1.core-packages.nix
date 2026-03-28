{ pkgs, ... }:

{
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nix = {
    package = pkgs.nix;
    settings = {
    };
  };

  home.packages = with pkgs; [
    bat
    eza
    fd
    file
    fzf
    ripgrep
    trash-cli
    tree
    unzip
    zip
    zoxide

    asciinema
    chafa
    fastfetch
    glow
    parallel
    tealdeer

    cmark
    fx
    jq
    jqp
    pandoc

    aria2
    httpie
    nmap
    rclone
    xh

    gh
    gitui
    shellcheck
    direnv

    neovim
    opencode

    containerd
    distrobox

    ffmpegthumbnailer
    mediainfo
    yt-dlp

    eget
    fdupes
    pngquant
    resvg
    starship
  ];
}
