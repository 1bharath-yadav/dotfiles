{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    asciinema
    bat
    chafa
    direnv
    eza
    fastfetch
    fd
    file
    fx
    fzf
    gh
    gitui
    glow
    httpie
    jq
    nmap
    parallel
    ripgrep
    shellcheck
    tealdeer
    trash-cli
    tree
    unzip
    xh
    zip
    zoxide
  ];
}
