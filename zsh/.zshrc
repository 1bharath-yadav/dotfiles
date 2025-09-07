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
alias i="sudo pacman -S "
alias upd="sudo pacman -Syu"
alias rsearch="pacman -Ss "
alias lsearch="pacman -Qs "
alias rp="sudo pacman -Rscun "
alias nvimedit="nvim /home/archer/.config/nvim"
alias fuzzy='fzf --preview="bat {}" | xargs -r nvim'
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
alias supercd='cd "$(fzf --preview="if [ -d {}; then ls -la {}; else cat {}; fi" | xargs -r dirname)"'
alias mail='neomutt'


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



# Terminal Session Logger for .zshrc
# Creates JSONL logs in ~/logs/terminal-sessions/

# Create logs directory
mkdir -p ~/logs/terminal-sessions

# Generate session ID and log file
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_$$"
LOG_DIR="$HOME/logs/terminal-sessions"
RAW_LOG="$LOG_DIR/${SESSION_ID}.raw"
JSONL_LOG="$LOG_DIR/${SESSION_ID}.jsonl"

# Function to convert script output to JSONL
convert_to_jsonl() {
    if [[ -f "$RAW_LOG" ]]; then
        {
            echo "{\"session_id\":\"$SESSION_ID\",\"start_time\":\"$(date -Iseconds)\",\"type\":\"session_start\"}"
            
            # Process the raw log and convert to JSONL format
            while IFS= read -r line; do
                # Escape quotes and backslashes for JSON
                escaped_line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
                timestamp=$(date -Iseconds)
                echo "{\"session_id\":\"$SESSION_ID\",\"timestamp\":\"$timestamp\",\"type\":\"output\",\"content\":\"$escaped_line\"}"
            done < "$RAW_LOG"
            
            echo "{\"session_id\":\"$SESSION_ID\",\"end_time\":\"$(date -Iseconds)\",\"type\":\"session_end\"}"
        } > "$JSONL_LOG"
        
        # Remove raw log after conversion
        rm -f "$RAW_LOG"
    fi
}

# Start script recording if not already running and not in a script session
if [[ -z "$SCRIPT_RUNNING" && -z "$TERM_SESSION_ID" ]]; then
    export SCRIPT_RUNNING=1
    export TERM_SESSION_ID="$SESSION_ID"
    
    # Use script to record session
    exec script -f -q "$RAW_LOG" -c "SCRIPT_RUNNING=1 TERM_SESSION_ID=$SESSION_ID zsh"
fi

# Cleanup function to convert logs on exit
cleanup_session() {
    convert_to_jsonl
    trap - EXIT
}

# Set trap to cleanup on shell exit
trap cleanup_session EXIT

