chromium-browser \
  $(jq -r '.urls | map(.url) | join(" ")' ~/piosk/config.json) \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --no-first-run \
  --ozone-platform=wayland \
  --enable-features=OverlayScrollbar \
  --start-maximized
