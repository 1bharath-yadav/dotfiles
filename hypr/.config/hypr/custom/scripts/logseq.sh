#!/bin/bash

# Start Syncthing in the background
syncthing -no-browser &

# Store Syncthing's PID
SYNCTHING_PID=$!

# Start Logseq and wait for it to exit
logseq &

# Store Logseq's PID
LOGSEQ_PID=$!

# Wait for Logseq to exit
wait $LOGSEQ_PID

# Kill Syncthing when Logseq exits
kill $SYNCTHING_PID
