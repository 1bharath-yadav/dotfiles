{ config, lib, ... }:

let
  initSnippets = [
    ./init/00-utils.zsh
    ./init/10-tools.zsh
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
      apply-dotfiles = "git -C ~/.dotfiles add . && home-manager switch --flake ~/.dotfiles#archer-arch";
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
