{ config, lib, ... }:

let
  initSnippets = [
    ./init/00-utils.zsh
    ./init/10-tools.zsh
    ./init/12-tmux.zsh
    ./init/15-nh.zsh
    ./init/20-dotfiles-cache.zsh
    ./init/30-yazi.zsh
    ./init/40-bindings.zsh
    ./init/50-secrets.zsh
  ];
in

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";

    shellAliases = {
      apply-dotfiles = "dotfiles-switch";
      hms = "dotfiles-switch";
      hmt = "dotfiles-test";
      hmb = "dotfiles-build";
      hme = "nh home edit $HOME/.dotfiles";
      nhc = "nh clean all --keep-since 4d --keep 3";
      nhh = "nh home";
      dotsa = "dots-apply";
      dotsu = "dots-update";
    };

    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlight = "fg=8,underline"; # Grey with underline for visibility
    };
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreAllDups = true;
      share = true;
      expireDuplicatesFirst = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "docker"
        "kubectl"
        "ansible"
        "terraform"
        "helm"
      ];
      theme = "robbyrussell";
    };

    envExtra = builtins.readFile ./env.zsh;

    initContent = lib.concatStringsSep "\n\n" (map builtins.readFile initSnippets);
  };
}
