#!/usr/bin/env bash
MODEL="/home/archer/linux/voice-detection-system/ggml-base.en-q8_0.bin"
OUT="/tmp/whisper_rec.wav"
PIDFILE="/tmp/whisper_rec.pid"

if [ -f "$PIDFILE" ]; then
  pid=$(cat "$PIDFILE") && kill "$pid" 2>/dev/null
  rm -f "$PIDFILE"
  sleep 0.3
  if [ -s "$OUT" ]; then
    whisper-cli -m "$MODEL" "$OUT" \
      | sed -E 's/^\[[^]]+\][[:space:]]+//' \
      | tr '\n' ' ' \
      | wtype -
    rm -f "$OUT"
  fi
  exit 0
fi

SRC=$(pactl list short sources | awk '/bluez_input/ {print $2; exit}')
[ -z "$SRC" ] && SRC=$(pactl info | awk -F': ' '/Default Source/ {print $2}')
pw-record --target="$SRC" --channels=1 --rate=16000 "$OUT" >/dev/null 2>&1 &
echo $! > "$PIDFILE"
                 