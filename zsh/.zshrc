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
# alias i="sudo pacman -S "
alias i='~/.dotfiles/bin/bin/pkg-log.sh'
alias upd="sudo pacman -Syu"
# Pacman aliases
alias pSyu='sudo pacman -Syu'              # Sync, refresh, and upgrade system
alias pS='sudo pacman -S'                  # Install package(s)
alias pR='sudo pacman -R'                  # Remove package(s)
alias pRs='sudo pacman -Rs'                # Remove package(s) + unused dependencies
alias pQ='pacman -Q'                       # Query installed packages
alias pQs='pacman -Qs'                     # Search installed & repo packages
alias pQe='pacman -Qe'                     # List explicitly installed packages
alias pQdt='pacman -Qdt'                   # List orphaned packages
alias pU='sudo pacman -U'                  # Install local package file
alias pSc='sudo pacman -Sc'                # Remove old package caches (safe)
alias pScc='sudo pacman -Scc'              # Clear ALL caches (danger: no rollback)
alias pFiles='pacman -Ql'                  # List files owned by a package
# Yay aliases (AUR helper)
alias ySyu='yay -Syu'                      # Sync & upgrade system (repos + AUR)
alias yS='yay -S'                          # Install package(s) from repo or AUR
alias yR='yay -R'                          # Remove package(s)
alias yRs='yay -Rs'                        # Remove + deps
alias ySs='yay -Ss'                        # Search repos + AUR
alias ySi='yay -Si'                        # Show package info (repo or AUR)
alias yQi='yay -Qi'                        # Show installed package info
alias yQe='yay -Qe'                        # List explicitly installed packages
alias yQdt='yay -Qdt'                      # List orphans
alias yG='yay -G'                          # Get PKGBUILD from AUR

alias pc='yay -Sc' # remove all cached packages
alias po='yay -Qtdq | sudo pacman -Rns -' # remove orphaned packages
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


