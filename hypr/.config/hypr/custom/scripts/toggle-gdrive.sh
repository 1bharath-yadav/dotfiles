#!/bin/bash

MOUNTPOINT="$HOME/gdrive"

if mount | grep -q "on $MOUNTPOINT type fuse.rclone"; then
    notify-send "GDrive" "Unmounting Google Drive..."
    fusermount -uz "$MOUNTPOINT"
else
    notify-send "GDrive" "Mounting Google Drive..."
    rclone mount gdrive: "$MOUNTPOINT" \
        --daemon \
        --vfs-cache-mode full \
        --buffer-size 16M \
        --vfs-read-chunk-size 32M \
        --vfs-read-chunk-size-limit 512M \
        --vfs-cache-max-size 10G \
        --vfs-cache-max-age 24h \
        --vfs-cache-poll-interval 1m \
        --dir-cache-time 24h \
        --poll-interval 15s \
        --vfs-fast-fingerprint
fi

