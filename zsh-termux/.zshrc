# ~/.zshrc (Termux) — sources shared zsh config then applies Termux overrides
# Managed by stow: zsh-termux package

# ── OMZ (Termux has no archlinux plugin) ──────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# ── Shared base config ────────────────────────────────────────────────────
# Source dotfiles cache (aliases, functions, paths) — same system as arch/ubuntu
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
_DOTFILES_CACHE="$HOME/.zsh_dotfiles_cache"
_CACHE_TTL=86400

_load_dotfiles_cache() {
  local stale=1
  if [[ -f "$_DOTFILES_CACHE" ]]; then
    local ct; ct=$(stat -c %Y "$_DOTFILES_CACHE" 2>/dev/null || stat -f %m "$_DOTFILES_CACHE")
    (( $(date +%s) - ct < _CACHE_TTL )) && stale=0
  fi
  if (( stale )); then
    { echo "# dotfiles cache $(date)"
      for f in "$DOTFILES_DIR"/shell-sources/**/*.sh; do
        [[ -f "$f" ]] && { echo "# $f"; cat "$f"; echo; }
      done
    } > "$_DOTFILES_CACHE"
  fi
  source "$_DOTFILES_CACHE"
}
_load_dotfiles_cache

# ── Prompt + tools ────────────────────────────────────────────────────────
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

# ── Termux-specific aliases ────────────────────────────────────────────────
alias i="pkg install"
alias upd="pkg update && pkg upgrade"
alias rsearch="pkg search"
alias lsearch="pkg list-installed"
alias rp="pkg uninstall"

# bun needs grun on Termux
bun() { grun "$HOME/.bun/bin/bun" "$@"; }

# ── PATH ──────────────────────────────────────────────────────────────────
export PATH="$HOME/bin:$HOME/.npm-global/bin:$PATH"
export EDITOR=nvim

# ── History ───────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history; HISTSIZE=10000; SAVEHIST=10000
setopt appendhistory
