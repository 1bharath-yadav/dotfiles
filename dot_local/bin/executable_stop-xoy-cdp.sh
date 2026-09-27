#!/usr/bin/env bash
# Cleanly quit the xoy Chrome so its cookies are saved.
# Use this (or `systemctl --user stop xoy-cdp`); never `kill` Chrome: SIGTERM makes it lose recent
# cookies and leaves the profile locked. CDP Browser.close and SIGINT are both clean.
set -uo pipefail

PROFILE="${XOY_PROFILE:-$HOME/.config/xoy}"
PORT="${XOY_PORT:-9222}"

# If the service is running, let systemd stop it (it calls this script again with --direct).
if [[ "${1:-}" != --direct ]] && systemctl --user is-active --quiet xoy-cdp.service 2>/dev/null; then
  exec systemctl --user stop xoy-cdp.service
fi

# The browser process: uses this profile and has no --type= (renderers, gpu, ... do).
pid=""
for p in $(pgrep -f -- "--user-data-dir=${PROFILE}( |\$)"); do
  [[ "$(readlink "/proc/$p/exe")" == */chrome* ]] || continue
  tr '\0' ' ' < "/proc/$p/cmdline" | grep -q -- '--type=' || { pid="$p"; break; }
done
[[ -n "$pid" ]] || { echo "xoy Chrome is not running"; exit 0; }

# Ask Chrome to quit like File > Exit (CDP Browser.close); if CDP is unreachable, SIGINT.
python3 - "$PORT" <<'PY' 2>/dev/null || kill -INT "$pid"
import base64, json, os, socket, sys, urllib.request
port = int(sys.argv[1])
ver = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json/version", timeout=3))
path = "/" + ver["webSocketDebuggerUrl"].split("/", 3)[3]
s = socket.create_connection(("127.0.0.1", port), timeout=5)
s.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
           f"Sec-WebSocket-Key: {base64.b64encode(os.urandom(16)).decode()}\r\nSec-WebSocket-Version: 13\r\n\r\n").encode())
if b" 101 " not in s.recv(4096).split(b"\r\n", 1)[0]:
    sys.exit(1)
msg, mask = json.dumps({"id": 1, "method": "Browser.close"}).encode(), os.urandom(4)
s.sendall(bytes([0x81, 0x80 | len(msg)]) + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(msg)))
try: s.recv(4096)
except OSError: pass
PY

for _ in $(seq 250); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done      # wait up to 25s
if kill -0 "$pid" 2>/dev/null; then
  echo "Chrome did not quit within 25s; NOT killing it (that would lose cookies)" >&2; exit 1
fi
if [[ -e "$PROFILE/SingletonLock" || -L "$PROFILE/SingletonLock" ]]; then
  echo "warning: Chrome left its profile lock behind (unclean exit)" >&2; exit 1
fi
echo "xoy Chrome stopped cleanly"
