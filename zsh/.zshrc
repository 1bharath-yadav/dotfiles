if [ -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt ]; then
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
fi



plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)


# If you come from bash you might have to change your $PATH.
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)
source ~/.env

#Yazi Config
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}




#keybindings

bindkey '^[f' forward-word   # Alt+f to move forward by word
bindkey '^[b' backward-word  # Alt+b to move backward by word
 
bindkey '^[d' kill-word        # Alt+d deletes word forward
bindkey '^d' backward-kill-word # Ctrl+w deletes word backward

bindkey '^K' kill-line             # Ctrl+K kills to end of line
bindkey '^[u' backward-kill-line   # Alt+u kills to beginning
bindkey '^L' clear-screen  # Ctrl+L (already default for many)
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward

sudo-command-line() {
  LBUFFER="sudo $LBUFFER"
  zle reset-prompt
}
zle -N sudo-command-line
bindkey '^[s' sudo-command-line


###Aliases

alias ts="trash"
alias icat="kitten icat"
# Set-up icons for files/folders in terminal
alias ls='eza --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'
# alias i="sudo pacman -S "
alias i='pkg-log.sh'
alias upd="sudo pacman -Syu"
alias rsearch="pacman -Ss "
alias lsearch="pacman -Qs "
alias rp="sudo pacman -Rscun "
alias pc='yay -Sc' # remove all cached packages
alias po='yay -Qtdq | sudo pacman -Rns -' # remove orphaned packages
alias nvimedit="nvim /home/archer/.config/nvim"
alias fuzzy='fzf --preview="bat {}" | xargs -r nvim'
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
alias supercd='cd "$(fzf --preview="if [ -d {}; then ls -la {}; else cat {}; fi" | xargs -r dirname)"'
alias mail='neomutt'

# tmux shortcuts
alias t='tmux'
alias tl='tmux list-sessions'
alias tns='tmux new-session -s'
alias ta='tmux attach-session'
alias tksa='tmux kill-session -a'
alias to='tmux attach-session -t'  #attach to specific session name
alias tn='tmux new-session -A -s "$(basename \"$PWD\")"'   #session name based on pwd


# Download high-quality audio for music
alias youtube-audio='yt-dlp --extract-audio --audio-format opus --embed-thumbnail'
# Download compressed audio for speech-to-text
alias youtube-opus='yt-dlp --extract-audio --audio-format opus --embed-thumbnail --postprocessor-args "-c:a libopus -b:a 12k -ac 1 -application voip -vbr off -ar 8000 -cutoff 4000 -frame_duration 60 -compression_level 10"'
# Download subtitles
youtube-subtitles () {
    curl -s "$(yt-dlp -q --skip-download --convert-subs srt --write-sub --sub-langs "en" --write-auto-sub --print "requested_subtitles.en.url" "$1")"
}


HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

export PATH=$PATH:/opt/android-sdk/cmdline-tools/latest/bin
export PATH="$HOME/.npm-global/bin:$PATH"
export EDITOR=nvim
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export DOCKER_HUB_USERNAME=bharathyadav1234
export PATH=$HOME/bin:/usr/local/bin:$PATH



