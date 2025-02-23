#!/bin/bash

# @TODO: fetch the user dynamically or from config
export XDG_RUNTIME_DIR=/run/user/1000

# THIS IS NOT THE BEST WAY TO SWITCH & REFRESH TABS BUT IT WORKS
# should parameterize cycle count & sleep delay with config.json

# count the number of URLs, that are configured to cycle through
URLS=$(jq -r '.urls | length' /opt/piosk/config.json)

# swich tabs each 10s, refresh tabs each 10th cycle & then reset
for ((TURN=1; TURN<=$((10*URLS)); TURN++)) do
  if [ $TURN -le $((10*URLS)) ]; then
    wtype -M ctrl -P Tab
    if [ $TURN -gt $((9*URLS)) ]; then
      wtype -M ctrl r
      if [ $TURN -eq $((10*URLS)) ]; then
        (( TURN=0 ))
      fi
    fi
  fi
  sleep 10
done
