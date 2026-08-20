#!/usr/bin/env bash

PORT=8022

# start ssh server if not running
pgrep sshd >/dev/null || sshd

# detect local ip
IP=$(ifconfig | awk '/inet / && $2!="127.0.0.1"{print $2; exit}')

USER=$(whoami)
CMD="ssh -p $PORT $USER@$IP"

echo
echo "SSH command:"
echo "$CMD"
echo
echo "Scan QR to connect:"
echo

qrencode -t ansiutf8 "$CMD"

echo
