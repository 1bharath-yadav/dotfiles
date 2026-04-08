export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
[[ -f "$ZDOTDIR/env.zsh" ]] && source "$ZDOTDIR/env.zsh"

has() { command -v "$1" >/dev/null 2>&1; }
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS SHARE_HISTORY HIST_EXPIRE_DUPS_FIRST
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

autoload -Uz compinit && compinit
bindkey -e

if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="robbyrussell"
  plugins=(git sudo)
  source "$ZSH/oh-my-zsh.sh"
fi

for f in "$ZDOTDIR"/init/*.zsh(.N); do
  source "$f"
done

alias dots='${EDITOR:-nvim} $HOME/.dotfiles'
