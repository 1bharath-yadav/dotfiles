has starship && eval "$(starship init zsh)"
has zoxide && eval "$(zoxide init zsh)"
has direnv && eval "$(direnv hook zsh)"
has pay-respects && eval "$(pay-respects zsh --alias)"
has fzf && source <(fzf --zsh)
