# if [ -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt ]; then
#     cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
# fi
#

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
eval "$(pay-respects zsh --alias)"
eval "$(intelli-shell init zsh)"
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
alias sourcezsh="source ~/.zshrc"
alias ts="trash"
alias icat="kitten icat"
alias f="$(pay-respects zsh)"
# Set-up icons for files/folders in terminal
alias ls='eza --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'

alias nvimedit="nvim ~/.dotfiles/nvim/.config/nvim"
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
export DOTFILES_DIR="$HOME/.dotfiles"


# 🅻🅾🅰🅳🅴🆁🆂 - Concatenate dotfiles into a single cache
_DOTFILES_CACHE="${HOME}/.zsh_dotfiles_cache"
_DOTFILES_CACHE_TIME=86400  # 24 hours in seconds
DOTFILES_DIR="${HOME}/.dotfiles"
load_dotfiles() {
  local load_from_cache=0

  # Check if cache exists and is recent
  if [[ -f "${_DOTFILES_CACHE}" ]]; then
    local cache_time=$(stat -c %Y "${_DOTFILES_CACHE}" 2>/dev/null || stat -f %m "${_DOTFILES_CACHE}" 2>/dev/null)
    local current_time=$(date +%s)
    if (( current_time - cache_time < _DOTFILES_CACHE_TIME )); then
      load_from_cache=1
    fi
  fi

  if (( load_from_cache )); then
    source "${_DOTFILES_CACHE}"
  else
    # Generate new cache: concatenate everything into one big file
    {
      echo "# Auto-generated dotfiles cache - $(date)"
      for loader in "${DOTFILES_DIR}"/shell-sources/**/*.sh; do
        if [[ -f "$loader" ]]; then
          echo "# Source: $loader"
          cat "$loader"
          echo ""   # ensure newline between files
        fi
      done
    } > "${_DOTFILES_CACHE}"

    source "${_DOTFILES_CACHE}"
  fi
}


load_dotfiles


# shellcheck disable=SC2034,SC2153,SC2086,SC2155

# Above line is because shellcheck doesn't support zsh, per
# https://github.com/koalaman/shellcheck/wiki/SC1071, and the ignore: param in
# ludeeus/action-shellcheck only supports _directories_, not _files_. So
# instead, we manually add any error the shellcheck step finds in the file to
# the above line ...

# Source this in your ~/.zshrc
autoload -U add-zsh-hook

zmodload zsh/datetime 2>/dev/null

# If zsh-autosuggestions is installed, configure it to use Atuin's search. If
# you'd like to override this, then add your config after the $(atuin init zsh)
# in your .zshrc
_zsh_autosuggest_strategy_atuin() {
    # silence errors, since we don't want to spam the terminal prompt while typing.
    suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --limit 1 --search-mode prefix 2>/dev/null)
}

if [ -n "${ZSH_AUTOSUGGEST_STRATEGY:-}" ]; then
    ZSH_AUTOSUGGEST_STRATEGY=("atuin" "${ZSH_AUTOSUGGEST_STRATEGY[@]}")
else
    ZSH_AUTOSUGGEST_STRATEGY=("atuin")
fi

export ATUIN_SESSION=$(atuin uuid)
ATUIN_HISTORY_ID=""

_atuin_preexec() {
    local id
    id=$(atuin history start -- "$1")
    export ATUIN_HISTORY_ID="$id"
    __atuin_preexec_time=${EPOCHREALTIME-}
}

_atuin_precmd() {
    local EXIT="$?" __atuin_precmd_time=${EPOCHREALTIME-}

    [[ -z "${ATUIN_HISTORY_ID:-}" ]] && return

    local duration=""
    if [[ -n $__atuin_preexec_time && -n $__atuin_precmd_time ]]; then
        printf -v duration %.0f $(((__atuin_precmd_time - __atuin_preexec_time) * 1000000000))
    fi

    (ATUIN_LOG=error atuin history end --exit $EXIT ${duration:+--duration=$duration} -- $ATUIN_HISTORY_ID &) >/dev/null 2>&1
    export ATUIN_HISTORY_ID=""
}

_atuin_search() {
    emulate -L zsh
    zle -I

    # swap stderr and stdout, so that the tui stuff works
    # TODO: not this
    local output
    # shellcheck disable=SC2048
    output=$(ATUIN_SHELL=zsh ATUIN_LOG=error ATUIN_QUERY=$BUFFER atuin search $* -i 3>&1 1>&2 2>&3)

    zle reset-prompt
    # re-enable bracketed paste
    # shellcheck disable=SC2154
    echo -n ${zle_bracketed_paste[1]} >/dev/tty

    if [[ -n $output ]]; then
        RBUFFER=""
        LBUFFER=$output

        if [[ $LBUFFER == __atuin_accept__:* ]]
        then
            LBUFFER=${LBUFFER#__atuin_accept__:}
            zle accept-line
        fi
    fi
}
_atuin_search_vicmd() {
    _atuin_search --keymap-mode=vim-normal
}
_atuin_search_viins() {
    _atuin_search --keymap-mode=vim-insert
}

_atuin_up_search() {
    # Only trigger if the buffer is a single line
    if [[ ! $BUFFER == *$'\n'* ]]; then
        _atuin_search --shell-up-key-binding "$@"
    else
        zle up-line
    fi
}
_atuin_up_search_vicmd() {
    _atuin_up_search --keymap-mode=vim-normal
}
_atuin_up_search_viins() {
    _atuin_up_search --keymap-mode=vim-insert
}

add-zsh-hook preexec _atuin_preexec
add-zsh-hook precmd _atuin_precmd

zle -N atuin-search _atuin_search
zle -N atuin-search-vicmd _atuin_search_vicmd
zle -N atuin-search-viins _atuin_search_viins
zle -N atuin-up-search _atuin_up_search
zle -N atuin-up-search-vicmd _atuin_up_search_vicmd
zle -N atuin-up-search-viins _atuin_up_search_viins

# These are compatibility widget names for "atuin <= 17.2.1" users.
zle -N _atuin_search_widget _atuin_search
zle -N _atuin_up_search_widget _atuin_up_search

bindkey -M emacs '^r' atuin-search
bindkey -M viins '^r' atuin-search-viins
bindkey -M vicmd '/' atuin-search
bindkey -M emacs '^[[A' atuin-up-search
bindkey -M vicmd '^[[A' atuin-up-search-vicmd
bindkey -M viins '^[[A' atuin-up-search-viins
bindkey -M emacs '^[OA' atuin-up-search
bindkey -M vicmd '^[OA' atuin-up-search-vicmd
bindkey -M viins '^[OA' atuin-up-search-viins
bindkey -M vicmd 'k' atuin-up-search-vicmd
