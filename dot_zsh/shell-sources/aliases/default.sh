#!/usr/bin/env bash
# default.sh — general shell aliases

# path / shell
alias path='echo ${PATH//:/\\n}'
alias r='exec $SHELL -l'
alias reload='exec $SHELL -l'
alias ':q'='exit'
alias quit='exit'

# network
alias nls='sudo lsof -i -P | grep LISTEN'   # active listeners
alias op='sudo lsof -i -P'                   # all open ports
alias ping='ping -c 5'
alias ports='netstat -tulan'
alias dirserve='python3 -m http.server 8000 --bind 127.0.0.1'
alias curl='curl --compressed'
alias weather='curl -s "wttr.in/?format=3"'
