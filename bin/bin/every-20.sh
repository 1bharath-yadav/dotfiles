#!/bin/bash
notify-send "look aside"
FILE=$(find /home/archer/Music/tones -type f -name "*.wav" | shuf -n 1)
/usr/bin/aplay "$FILE"
timestamp=$(date +%s)
grim "/tmp/tmp${timestamp}.png"
tesseract "/tmp/tmp${timestamp}.png" "/home/archer/logs/screenshot-raws/$(date +%Y%m%d_%H%M%S).screenshot"
rm "/tmp/tmp${timestamp}.png"
