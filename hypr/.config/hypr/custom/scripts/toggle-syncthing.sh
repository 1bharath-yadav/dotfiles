#!/bin/bash

if pgrep syncthing > /dev/null; then
    pkill syncthing
    notify-send "Syncthing" "Syncthing stopped"
else
    syncthing --no-browser & disown
    notify-send "Syncthing" "Syncthing started"
fi
