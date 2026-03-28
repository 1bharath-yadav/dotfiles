sudo modprobe -v v4l2loopback exclusive_caps=1 card_label="camera"


scrcpy -m 1024 --no-audio --video-source=camera --no-video-playback --camera-facing=front --v4l2-sink=/dev/video0
