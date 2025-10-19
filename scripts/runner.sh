#!/bin/bash

# export essential GUI variables for systemd services
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# give the desktop a moment to settle
sleep 5

# check to ensure URLs are there to load
URLS=$(jq -r '.urls | map(.url) | join(" ")' /opt/piosk/config.json)
if [ -z "$URLS" ]; then
    echo "No URLs found in config.json. Exiting runner."
    exit 0
fi

# use chromium if available, else chromium-browser
if command -v chromium >/dev/null 2>&1; then
    BROWSER=chromium
elif command -v chromium-browser >/dev/null 2>&1; then
    BROWSER=chromium-browser
else
    echo "Neither chromium nor chromium-browser found"
    exit 1
fi

# run chromium/chromium-browser with the URLs and flags
$BROWSER $URLS \
  --disable-component-update \
  --disable-composited-antialiasing \
  --disable-gpu-driver-bug-workarounds \
  --disable-infobars \
  --disable-low-res-tiling \
  --disable-pinch \
  --disable-session-crashed-bubble \
  --disable-smooth-scrolling \
  --enable-accelerated-video-decode \
  --enable-gpu-rasterization \
  --enable-oop-rasterization \
  --force-device-scale-factor=1 \
  --ignore-gpu-blocklist \
  --kiosk \
  --no-first-run \
  --noerrdialogs
