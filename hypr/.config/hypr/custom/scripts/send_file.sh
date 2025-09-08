
#!/usr/bin/env bash
DEVICE="8d0842b1f41544afa56c0dfd720e9ee1"
PREFIX=$(wl-paste 2>/dev/null | head -c 7); if [[ "$PREFIX" == "file://" ]]; then FILE=$(wl-paste 2>/dev/null); FILE="${FILE#file://}"; kdeconnect-cli --device "$DEVICE" --share "$FILE" & disown; exit 0; fi
TMP="/tmp/kdeconnect_clipboard_$(date +%Y%m%d_%H%M%S)"; wl-paste > "$TMP"
EXT=$(file --mime-type -b "$TMP" | sed 's|.*/||;s|+.*||'); mv "$TMP" "$TMP.$EXT"
kdeconnect-cli --device "$DEVICE" --share "$TMP.$EXT" & disown; echo "sent $TMP.$EXT"
#make sure no -(hyphens) are present between file or foldername