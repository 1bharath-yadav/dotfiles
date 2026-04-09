#!/usr/bin/env bash


# File manipulation aliases

# cp: Copy files and directories interactively (ask before overwrite) with verbose output.
alias cp="cp -vi"

# del: Remove files or directories interactively (ask before each removal) with verbose output, recursively.
alias del="rm -rfvi"

# ln: Create symbolic links interactively (ask before overwrite) with verbose output.
alias ln='ln -vi'

# mv: Move or rename files interactively (ask before overwrite) with verbose output.
alias mv='mv -vi'

# rm: Remove files or directories interactively (ask before each removal) with verbose output.
alias rm='rm -vi'

# zap: Alias for 'rm', removes files or directories interactively (ask before each removal) with verbose output.
alias zap='rm -vi'


# Other interactive aliases

# chmod: Change file or directory permissions with verbose output.
alias chmod='chmod -v'

# chown: Change file or directory owner and group with verbose output.
alias chown='chown -v'

# diff: Compare and show differences between two files in unified format.
alias diff='diff -u'

# grep: Search for a pattern in files or output, showing line numbers and case-insensitively.
alias grep='grep -n -i'

# mkdir: Create a new directory, making parent directories as needed, with verbose output.
alias mkdir='mkdir -pv'


# Make directory and cd into it.
alias mcd='mkdir -pv && cd'

# Make example directory with current date.
alias mde='mkdir -pv "$(date +%Y%m%d)-example"'

# Make directory.
alias md='mkdir -v'

# Make directory with date.
alias mdd='mkdir -pv $(date +%Y%m%d) && cd $(date +%Y%m%d)'

# Make notes directory with current date.
alias mdn='mkdir -pv "$(date +%Y%m%d)-notes"'

# Make work directory with current date.
alias mdw='mkdir -pv "$(date +%Y%m%d)-work"'

# Make directory with time.
alias mdt='mkdir -pv $(date +%H%M%S)'
