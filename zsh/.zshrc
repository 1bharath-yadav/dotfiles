
if [ -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt ]; then
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
fi


export EDITOR=nvim
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
eval "$(fnm env --use-on-cd --shell zsh)"
export ZSH="$HOME/.oh-my-zsh"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"


export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
source ~/.env
export DOCKER_HUB_USERNAME=bharathyadav1234


bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

alias ts="trash"
alias icat="kitten icat"
# Set-up icons for files/folders in terminal
alias ls='eza --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'
alias i="sudo pacman -S "
alias upd="sudo pacman -Syu"
alias rsearch="pacman -Ss "
alias lsearch="pacman -Qs "
alias rp="sudo pacman -Rscun "
alias nvimedit="nvim /home/archer/.config/nvim"
alias fuzzy='fzf --preview="bat {}" | xargs -r nvim'
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
alias supercd='cd "$(fzf --preview="if [ -d {} ]; then ls -la {}; else cat {}; fi" | xargs -r dirname)"'
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/archer/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/archer/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/archer/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/archer/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Added by LM Studio CLI (lms)
export PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin


export PATH="$HOME/.npm-global/bin:$PATH"

#Yazi Config

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


