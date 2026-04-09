# zsh-autosuggestions configuration
if [[ -d /usr/share/zsh/plugins/zsh-autosuggestions ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -d $HOME/.oh-my-zsh/plugins/zsh-autosuggestions ]]; then
  source $HOME/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# autosuggestion key bindings
bindkey '^n' autosuggest-accept
