#!/bin/bash

NIGHT_HASH_FILE="$HOME/.night_password_hash"
NIGHT_START="22:30"
NIGHT_END="05:00"

# Get current time in HH:MM format
CURRENT_TIME=$(date +%H:%M)

# Check if we're in night hours
if [[ "$CURRENT_TIME" > "$NIGHT_START" ]] || [[ "$CURRENT_TIME" < "$NIGHT_END" ]]; then
    # Night time - require night password
    echo -n "Night password: "
    read -s input_password
    echo
    
    # Hash the input
    input_hash=$(echo -n "$input_password" | sha256sum | awk '{print $1}')
    stored_hash=$(cat "$NIGHT_HASH_FILE" 2>/dev/null)
    
    if [[ "$input_hash" == "$stored_hash" ]]; then
        exit 0  # Success
    else
        echo "Access denied during night hours"
        exit 1  # Failure
    fi
else
    # Day time - allow normal authentication
    exit 0
fi
