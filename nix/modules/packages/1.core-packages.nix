{ pkgs, ... }:

{
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
  xdg.enable = true;

  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "$HOME/bin"
    "$HOME/.local/bin"
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
    # Core CLI
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

    # Data & Parsing
    cmark
    fx
    jq
    jqp
    pandoc

    # Development
    delta
    direnv
    gh
    git-lfs
    gitui
    nix-direnv
    shellcheck

    # Editors
    neovim
    opencode

    # Media
    ffmpegthumbnailer
    mediainfo
    yt-dlp

    # Network
    aria2
    httpie
    nmap
    rclone
    xh

    # Nix Tooling
    comma
    deadnix
    nix-tree
    statix

    # Terminal Utils
    asciinema
    chafa
    containerd
    distrobox
    eget
    fastfetch
    fdupes
    glow
    parallel
    pngquant
    resvg
    starship
    tealdeer
  ];
}
