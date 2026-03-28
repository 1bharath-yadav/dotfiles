bindkey '^[f' forward-word
bindkey '^[b' backward-word
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

sudo-command-line() { LBUFFER="sudo $LBUFFER"; zle reset-prompt; }
zle -N sudo-command-line
bindkey '^[s' sudo-command-line
