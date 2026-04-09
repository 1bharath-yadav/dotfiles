#!/usr/bin/env bash
# tmux.sh — tmux session aliases

command -v tmux >/dev/null 2>&1 || return 0

alias ta='tmux attach-session'
alias tat='tmux attach-session -t'
alias tl='tmux list-sessions'
alias tks='tmux kill-session -a'    # kill all except current
alias tka='tmux kill-server'        # kill all
alias tmn='tmux new-session'
alias ts='tmux new-session -s'
alias tr='tmux source ~/.config/tmux/tmux.conf'
alias tn='tmux new-session -A -s "$(basename "$PWD")"'  # session named after cwd
alias tmls='tmux list-windows'
alias tmlp='tmux list-panes'
alias tmi='tmux info'
