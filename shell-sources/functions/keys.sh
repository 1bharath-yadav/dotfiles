#!/usr/bin/env bash

# ===== Secrets location =====
SECRETS_DIR="$HOME/.apikeys"

# Load encrypted env file into memory
load_secret() {
    eval "$(gpg --quiet --decrypt "$SECRETS_DIR/$1")"
}

# Bitwarden login using encrypted API key
bwlogin() {
    load_secret bw-api.env.gpg
    bw login --apikey
    unset BW_CLIENTID BW_CLIENTSECRET
}

# Unlock vault with auto lock
bwunlock() {
    if [[ -f "$SECRETS_DIR/bw-pass.env.gpg" ]]; then
        load_secret bw-pass.env.gpg
        export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
        unset BW_PASSWORD
    else
        export BW_SESSION=$(bw unlock --raw)
    fi

    # Auto-lock on shell exit
    trap 'bw lock >/dev/null 2>&1; unset BW_SESSION' EXIT
}

# Manual lock
bwlock() {
    bw lock
    unset BW_SESSION
}

