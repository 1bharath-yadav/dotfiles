#!/usr/bin/env bash

PORT=22

pgrep -x sshd >/dev/null || sudo /usr/bin/sshd

ss -tln | grep -q ":$PORT " || {
    echo "sshd not listening on port $PORT"
    exit 1
}

IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')

[ -n "$IP" ] || {
    echo "Could not determine IP address"
    exit 1
}

CMD="ssh $(whoami)@$IP"

echo
echo "$CMD"
echo

command -v qrencode >/dev/null &&
    qrencode -t ansiutf8 "$CMD"
