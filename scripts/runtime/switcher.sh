#!/bin/bash

# Ensure the script runs from the correct directory, where config.json is located.
cd /opt/piosk

export XDG_RUNTIME_DIR=/run/user/1000

# --- Read Configuration using jq ---
# Create a Bash array of durations for each URL.
mapfile -t DURATIONS < <(jq -r '.urls[].duration' ./config.json)

# Create a Bash array of cycle counts before a refresh is triggered.
mapfile -t CYCLES < <(jq -r '.urls[].cycles' ./config.json)

# Count the total number of URLs to manage.
URL_COUNT=${#DURATIONS[@]}

# If no URLs are configured, exit gracefully.
if [ "$URL_COUNT" -eq 0 ]; then
  echo "No URLs configured. Exiting switcher."
  exit 0
fi

# --- Initialize State ---
# Create and initialize an array to track the display count for each tab.
REFRESH_COUNTS=()
for ((i=0; i<URL_COUNT; i++)); do
  REFRESH_COUNTS+=(0)
done

CURRENT_TAB_INDEX=0

# Give Chromium a moment to start up on boot before we start sending keys.
echo "Switcher waiting for browser to initialize..."
sleep 15

echo "PiOSK switcher started. Managing $URL_COUNT tabs."

# --- Main Loop ---
while true; do
  # --- Get Settings for the Current Tab ---
  duration=${DURATIONS[$CURRENT_TAB_INDEX]}
  cycle_target=${CYCLES[$CURRENT_TAB_INDEX]}

  # --- Handle Refresh Logic ---
  # Only run this if cycle_target is greater than 0
  if [ "$cycle_target" -gt 0 ]; then
    # Increment the display counter for the current tab.
    ((REFRESH_COUNTS[$CURRENT_TAB_INDEX]++))
    echo "Tab $((CURRENT_TAB_INDEX + 1)): Display cycle ${REFRESH_COUNTS[$CURRENT_TAB_INDEX]} of $cycle_target."

    # Check if it's time to refresh this specific tab.
    if [ "${REFRESH_COUNTS[$CURRENT_TAB_INDEX]}" -ge "$cycle_target" ]; then
      echo "Refreshing Tab $((CURRENT_TAB_INDEX + 1))."
      
      # Send Ctrl+r to refresh the current tab using wtype.
      wtype -M ctrl r -m ctrl
      
      # Reset the counter for this tab.
      REFRESH_COUNTS[$CURRENT_TAB_INDEX]=0
    fi
  else
    echo "Tab $((CURRENT_TAB_INDEX + 1)): Refresh disabled (set to 0)."
  fi
  
  # --- Wait for the specified duration ---
  echo "Waiting for $duration seconds."
  sleep "$duration"

  # --- Switch to the Next Tab ---
  echo "Switching to next tab."
  # Send Ctrl+Tab to switch to the next tab using wtype.
  wtype -M ctrl -P Tab -m ctrl

  # --- Update Tab Index ---
  # Move to the next index, wrapping around to 0 if at the end.
  CURRENT_TAB_INDEX=$(( (CURRENT_TAB_INDEX + 1) % URL_COUNT ))

done