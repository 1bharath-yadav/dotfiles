#!/usr/bin/env bash
# keys.sh - Shell helpers for secrets via GNOME Keyring (secret-tool / libsecret).
# Secrets are stored with: service=sensvault, username=<key-name>
# Store a secret: secret-tool store --label="..." service sensvault username <key-name>

# Lookup a secret from the keyring; print to stdout.
# Usage: get_secret <key-name>
get_secret() {
    secret-tool lookup service sensvault username "$1" 2>/dev/null \
        || { echo "[keys.sh] secret not found: $1" >&2; return 1; }
}

# Bitwarden login using API key stored in keyring.
# Store once with:
#   secret-tool store --label="Bitwarden client ID"     service sensvault username bw_client_id
#   secret-tool store --label="Bitwarden client secret" service sensvault username bw_client_secret
bwlogin() {
    BW_CLIENTID="$(get_secret bw_client_id)"       || return 1
    BW_CLIENTSECRET="$(get_secret bw_client_secret)" || return 1
    export BW_CLIENTID BW_CLIENTSECRET
    bw login --apikey
    unset BW_CLIENTID BW_CLIENTSECRET
}

# Unlock Bitwarden vault using master password from keyring.
# Store once with:
#   secret-tool store --label="Bitwarden master password" service sensvault username bw_password
bwunlock() {
    local pw
    pw="$(get_secret bw_password)" || {
        # Fallback: interactive prompt (not stored)
        export BW_SESSION=$(bw unlock --raw)
        trap 'bw lock >/dev/null 2>&1; unset BW_SESSION' EXIT
        return
    }
    export BW_SESSION=$(BW_PASSWORD="$pw" bw unlock --passwordenv BW_PASSWORD --raw)
    unset pw
    trap 'bw lock >/dev/null 2>&1; unset BW_SESSION' EXIT
}

# Manual lock
bwlock() {
    bw lock
    unset BW_SESSION
}
