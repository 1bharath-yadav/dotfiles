# Intel IPU6 Camera Bridge

Purpose: expose the working IPU6/libcamera webcam as a normal V4L2 camera for applications that cannot consume the native libcamera PipeWire camera directly.

## Architecture

`OV02C10 → Intel IPU6/libcamera → GStreamer → v4l2loopback /dev/video33 → Hardware ISP Camera`

Camera Effects can then use `Hardware ISP Camera` as its V4L2 input and publish `Camera Effects` separately.

## Packages

The required packages are:

```bash
sudo pacman -S --needed libcamera libcamera-tools gst-plugin-libcamera v4l2loopback-dkms v4l2loopback-utils
```

`v4l2-relayd` is **not required** for this modern IPU6/libcamera setup. It was installed during troubleshooting but the working bridge uses GStreamer directly.

```bash
sudo pacman -S --needed v4l2-relayd
```

## 1. Verify the physical camera

```bash
cam -l
```

Expected:

```text
Available cameras:
1: Internal front camera (\\_SB_.PC00.LNK0)
```

The IPU6 nodes under `/dev/video0` … `/dev/video31` are capture/metadata nodes, not V4L2 output devices. Do **not** use them with `v4l2sink`.

## 2. Create the V4L2 loopback camera

Create a dedicated virtual output device:

```bash
sudo v4l2loopback-ctl add -n "Hardware ISP Camera" -x 1 -o 16 /dev/video33
```

Verify:

```bash
v4l2-ctl --list-devices
```

Expected:

```text
Hardware ISP Camera (platform:v4l2loopback-033):
    /dev/video33
```

## 3. Test the bridge manually

```bash
gst-launch-1.0 \
  libcamerasrc \
  ! videoconvert \
  ! video/x-raw,format=YUY2,width=1280,height=720,framerate=30/1 \
  ! v4l2sink device=/dev/video33 sync=false
```

Keep this running while testing the virtual camera from another application.

Test the V4L2 reader:

```bash
ffmpeg -hide_banner -loglevel error \
  -f v4l2 -video_size 1280x720 -framerate 30 \
  -i /dev/video33 -frames:v 5 -f null -
```

A zero exit status confirms that frames are reaching the virtual camera.

## 4. Make the bridge persistent

Create `/etc/systemd/system/ipU6-camera-bridge.service`:

```ini
[Unit]
Description=IPU6 libcamera to V4L2 virtual camera bridge
After=systemd-modules-load.service
Wants=systemd-modules-load.service

[Service]
Type=simple
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=LIBCAMERA_LOG_LEVELS=*:ERROR
ExecStart=/usr/bin/gst-launch-1.0 -q libcamerasrc ! videoconvert ! video/x-raw,format=YUY2,width=1280,height=720,framerate=30/1 ! v4l2sink device=/dev/video33 sync=false
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ipU6-camera-bridge.service
```

Check it:

```bash
sudo systemctl status ipU6-camera-bridge.service
v4l2-ctl --list-devices
```

## 5. Camera Effects

Camera Effects uses its own loopback:

```text
/dev/video32 = Camera Effects
/dev/video33 = Hardware ISP Camera
```

The required flow is:

```text
/dev/video33 Hardware ISP Camera
        ↓
 camera-effects-server
        ↓
/dev/video32 Camera Effects
```

Select `Hardware ISP Camera` as the source in Camera Effects. Do not select `/dev/video0`; it is an IPU6 capture node and `v4l2sink` cannot write to it.

## 6. Verification

```bash
v4l2-ctl --list-devices
systemctl is-active ipU6-camera-bridge.service
sudo v4l2-ctl -d /dev/video33 --all
```

The bridge should report:

```text
Card type        : Hardware ISP Camera
Video Capture
Streaming
Width/Height     : 1280/720
Pixel Format     : YUYV
Frames per second: 30.000
```

## Troubleshooting

`Device '/dev/video0' is not a output device.` means the physical IPU6 capture node was supplied to `v4l2sink`. Use `/dev/video33` (the loopback) instead.

`camera-effects-server` reports `no camera found` when it cannot find a usable V4L2 source. Verify that `/dev/video33` exists, the bridge service is active, and Camera Effects is configured to use `Hardware ISP Camera`.

The IPU6/libcamera warnings about failing to retrieve OV02C10 crop rectangles are present on this machine but do not prevent qcam or the tested GStreamer pipeline from producing frames.

## Removal

Stop and disable the bridge:

```bash
sudo systemctl disable --now ipU6-camera-bridge.service
sudo rm /etc/systemd/system/ipU6-camera-bridge.service
sudo systemctl daemon-reload
```

Remove the virtual camera:

```bash
sudo v4l2loopback-ctl delete /dev/video33
```

Remove the optional relay package if it is no longer wanted:

```bash
sudo pacman -Rns v4l2-relayd
```
