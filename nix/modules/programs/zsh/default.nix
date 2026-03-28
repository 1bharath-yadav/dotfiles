{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";

    shellAliases = {
      apply-dotfiles = "git -C ~/.dotfiles add . && nix run home-manager/master -- switch --flake ~/.dotfiles#archer-arch";
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

    envExtra = ''
      export DOTFILES_DIR="$HOME/.dotfiles"
      export EDITOR=nvim
      export SUDO_EDITOR=nvim
      export MANPAGER="nvim +Man!"

      # Minimal PATH (don’t override system defaults)
      path=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.bun/bin"
        $path
      )
    '';

    initContent = ''
      has() { command -v "$1" >/dev/null 2>&1; }

      # Tool init
      has starship && eval "$(starship init zsh)"
      has zoxide && eval "$(zoxide init zsh)"
      has direnv && eval "$(direnv hook zsh)"
      has pay-respects && eval "$(pay-respects zsh --alias)"
      has fzf && source <(fzf --zsh)

      # Dotfiles loader (cached)
      DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/.dotfiles}"
      CACHE="$HOME/.zsh_dotfiles_cache"
      TTL=86400

      if [[ ! -f "$CACHE" || $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE") )) -gt $TTL ]]; then
        {
          for f in "$DOTFILES_DIR"/shell-sources/**/*.sh; do
            [[ -f "$f" ]] && cat "$f"
          done
        } > "$CACHE"
      fi

      source "$CACHE"

      # Yazi cd-on-exit
      y() {
        local tmp="$(mktemp)" cwd
        yazi "$@" --cwd-file="$tmp"
        read -r cwd < "$tmp"
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd "$cwd"
        rm -f "$tmp"
      }

      # Keybindings (minimal useful set)
      bindkey '^[f' forward-word
      bindkey '^[b' backward-word
      bindkey '^P' history-beginning-search-backward
      bindkey '^N' history-beginning-search-forward

      # sudo shortcut
      sudo-command-line() { LBUFFER="sudo $LBUFFER"; zle reset-prompt; }
      zle -N sudo-command-line
      bindkey '^[s' sudo-command-line

      # Optional secrets
      [[ -f "$HOME/.secrets/config" ]] && source "$HOME/.secrets/config"
      [[ -f "$HOME/.env" ]] && source "$HOME/.env"
    '';
  };
}