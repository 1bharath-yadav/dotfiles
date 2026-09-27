#!/usr/bin/env bash
# Dedicated xoy Chrome with remote debugging on 127.0.0.1:$PORT.
# Launches headed inside Xvfb (virtual framebuffer) on an isolated X11 display,
# completely invisible and with zero focus stealing or Wayland scratchpad requirements.
# Stop it with stop-xoy-cdp.sh / `systemctl --user stop xoy-cdp`.
set -euo pipefail

BROWSER="/usr/bin/google-chrome-stable"
PROFILE="${XOY_PROFILE:-$HOME/.config/xoy}"
PORT="${XOY_PORT:-9222}"

[[ -x "$BROWSER" ]] || { echo "Chrome binary not found: $BROWSER" >&2; exit 1; }
command -v xvfb-run >/dev/null 2>&1 || { echo "xvfb-run not found: please install xorg-server-xvfb" >&2; exit 1; }
mkdir -p "$PROFILE"

# The keyring (cookie decryption) and GTK need the user session bus.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
export PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"
export PIPEWIRE_RUNTIME_DIR="${XDG_RUNTIME_DIR}"

# Unset WAYLAND_DISPLAY so Chrome strictly targets the Xvfb X11 display
unset WAYLAND_DISPLAY

# Already running and reachable? Then nothing to do.
if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  echo "xoy Chrome is already running on port ${PORT}"
  exit 0
fi

FLAGS=(
  --user-data-dir="$PROFILE"
  --remote-debugging-port="$PORT"
  --ozone-platform=x11
  --no-first-run
  --no-default-browser-check
  --password-store=gnome-libsecret
  --use-fake-ui-for-media-stream
  --autoplay-policy=no-user-gesture-required
  --disable-background-timer-throttling
  --disable-renderer-backgrounding
  --disable-backgrounding-occluded-windows
  --window-size=1920,1080
  --start-maximized
)

XVFB_CMD=(
  xvfb-run
  -a
  -w 0
  -s "-screen 0 1920x1080x24 -ac -nolisten tcp"
)

if [[ "${1:-}" == "--foreground" ]]; then
  exec "${XVFB_CMD[@]}" "$BROWSER" "${FLAGS[@]}"
fi

# If systemd service exists, delegate to it for supervision
if systemctl --user is-enabled --quiet xoy-cdp.service 2>/dev/null; then
  systemctl --user start xoy-cdp.service
  for _ in $(seq 50); do
    if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
      echo "xoy Chrome started via systemd (xoy-cdp.service, port ${PORT})"
      exit 0
    fi
    sleep 0.2
  done
  echo "xoy-cdp.service failed to listen on port ${PORT} within 10s" >&2
  exit 1
fi

# Fallback background launch
nohup setsid "${XVFB_CMD[@]}" "$BROWSER" "${FLAGS[@]}" </dev/null >/dev/null 2>&1 &
disown $! 2>/dev/null || true
for _ in $(seq 50); do
  if curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
    echo "xoy Chrome started on port ${PORT} (Xvfb)"
    exit 0
  fi
  sleep 0.2
done
echo "xoy Chrome failed to listen on port ${PORT} within 10s" >&2
exit 1
