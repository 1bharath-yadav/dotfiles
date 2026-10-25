#!/usr/bin/env bash
# tmux.sh — tmux session aliases

command -v tmux >/dev/null 2>&1 || return 0

alias tmas='tmux attach-session'
alias tmat='tmux attach-session -t'
alias tml='tmux list-sessions'
alias tmks='tmux kill-session -a'    # kill all except current
alias tmka='tmux kill-server'        # kill all
alias tmn='tmux new-session'
alias tms='tmux new-session -s'
alias tmr='tmux source-file ~/.tmux.conf'
alias tmn='tmux new-session -A -s "$(basename "$PWD")"'  # session named after cwd
alias tmls='tmux list-windows'
alias tmlp='tmux list-panes'
alias tmi='tmux info'
