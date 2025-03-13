#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias pacman='pacman --needed'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/archer/.lmstudio/bin"
