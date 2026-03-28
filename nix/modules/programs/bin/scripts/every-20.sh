#!/bin/bash
notify-send "look aside"
FILE=$(find /home/archer/Music/tones -type f -name "*.wav" | shuf -n 1)
/usr/bin/aplay "$FILE"
timestamp=$(date +%s)
grim "/home/archer/logs/breach/$(date +%Y%m%d_%H%M%S).screenshot"



# [Unit]
# Description=triggered every 20 minutes

# [Service]
# Type=oneshot
# Environment=DISPLAY=:0
# Environment=XAUTHORITY=/home/archer/.Xauthority
# ExecStart=/bin/bash /home/archer/bin/every-20.sh
# [Unit]
# Description=Run every-20.service every 20 minutes

# [Timer]
# OnBootSec=20min
# OnUnitActiveSec=20min
# Unit=every-20.service

# [Install]
# WantedBy=timers.target
