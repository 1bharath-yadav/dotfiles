# ~/.zshrc — shared config for Arch Linux & Ubuntu/WSL
# Termux uses zsh-termux/.zshrc instead
# Managed by stow: zsh package

# ── Oh My Zsh ─────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
plugins=(git archlinux zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# ── Prompt & tools ─────────────────────────────────────────────────────────
_has() { command -v "$1" >/dev/null 2>&1; }
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
_has pay-respects  && eval "$(pay-respects zsh --alias)"
_has intelli-shell && eval "$(intelli-shell init zsh)"
source <(fzf --zsh)

# ── Dotfiles cache loader ──────────────────────────────────────────────────
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
_DOTFILES_CACHE="$HOME/.zsh_dotfiles_cache"
_CACHE_TTL=86400

_load_dotfiles() {
  local stale=1
  if [[ -f "$_DOTFILES_CACHE" ]]; then
    local ct; ct=$(stat -c %Y "$_DOTFILES_CACHE" 2>/dev/null || stat -f %m "$_DOTFILES_CACHE")
    (( $(date +%s) - ct < _CACHE_TTL )) && stale=0
  fi
  if (( stale )); then
    { echo "# dotfiles cache — $(date)"
      for f in "$DOTFILES_DIR"/shell-sources/**/*.sh; do
        [[ -f "$f" ]] && { echo "# ── $f"; cat "$f"; echo; }
      done
    } > "$_DOTFILES_CACHE"
  fi
  source "$_DOTFILES_CACHE"
}
_load_dotfiles

# ── Yazi cd-on-exit wrapper ────────────────────────────────────────────────
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
  rm -f -- "$tmp"
}

# ── Key bindings ───────────────────────────────────────────────────────────
bindkey '^[f' forward-word
bindkey '^[b' backward-word
bindkey '^[d' kill-word
bindkey '^d'  backward-kill-word
bindkey '^K'  kill-line
bindkey '^[u' backward-kill-line
bindkey '^P'  history-beginning-search-backward
bindkey '^N'  history-beginning-search-forward

sudo-command-line() { LBUFFER="sudo $LBUFFER"; zle reset-prompt; }
zle -N sudo-command-line
bindkey '^[s' sudo-command-line

# ── History ────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST

# ── Environment ────────────────────────────────────────────────────────────
export EDITOR=nvim
export SUDO_EDITOR=nvim
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
export DOTFILES_DIR="$HOME/.dotfiles"

# GPG / secrets
[[ -f "$HOME/.secrets/config" ]] && source "$HOME/.secrets/config"

# Load .env only if it exists (personal env vars)
[[ -f "$HOME/.env" ]] && source "$HOME/.env"
