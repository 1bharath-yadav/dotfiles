#!/usr/bin/env bash

# Function: set_default_aliases
#
# Description:
#   Sets default shell aliases for enhanced shell usage.
#
# Arguments:
#   None
#
# Notes:
#   - Some aliases are designed for enhanced shell navigation and utility.
#   - Ensure to validate that all aliases work as expected in the bash shell.

set_default_aliases() {
    fc -W

    ## General aliases

    # Display the $PATH variable on newlines.
    alias path='echo ${PATH//:/\\n}'

    # Reload the shell.
    alias r='reload'

    # Prints the last 10 lines of a text or log file, and then waits for new
    # additions to the file to print it in real time.
    alias t='tail -f'

    ## Exit/shutdown aliases
    # Shortcut for the `exit` command.
    alias ':q'='quit'

    # Shortcut for the `exit` command.
    alias quit='exit'

    ## Network aliases

    # Show only active network listeners.
    alias nls='sudo lsof -i -P | grep LISTEN'

    # List of open ports.
    alias op='sudo lsof -i -P'

    # Limit Ping to 5 ECHO_REQUEST packets.
    alias ping='ping -c 5'

    # List all listening ports.
    alias ports='netstat -tulan'

    # Start a simple HTTP server to serve the current directory on port 8000.
    alias dirserve='python3 -m http.server 8000 --bind 127.0.0.1'

    ## Utility aliases

    # Use compression when transferring data.
    alias curl='curl --compressed'

    # Reload the shell.
    alias reload='exec $SHELL -l'

    # Get the weather.
    alias weather='curl -s "wttr.in/?format=3"'
}

set_default_aliases
