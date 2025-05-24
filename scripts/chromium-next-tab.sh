#!/bin/bash

# Chromium remote debugging port (default: 9222)
DEBUG_PORT=9222

# Get the list of open tabs in JSON format
tabs_json=$(curl -s http://localhost:$DEBUG_PORT/json)

# Index of the currently focused tab (assumed to be the first)
focused_index=0

# Total number of tabs
total_tabs=$(echo "$tabs_json" | jq 'length')

# Calculate next index (wrap around if at the end)
#next_index=$(( (focused_index + 1) % total_tabs ))
next_index=$(( (total_tabs - 1) % total_tabs )) # The last json object seems to be the next tab

# Extract the ID of the next tab
next_tab_id=$(echo "$tabs_json" | jq -r ".[$next_index].id")
next_tab_title=$(echo "$tabs_json" | jq -r ".[$next_index].title")
next_tab_url=$(echo "$tabs_json" | jq -r ".[$next_index].url")

# Occasionally there appears to be created a new empty and unusable tab. Not sure why.
# We tried to remove that tab when that happend, but was unsuccessfull.
# So now we just skip that tab when that happens:
if [ -z "$next_tab_url" ] || [ "$next_tab_url" = "about:blank" ]; then
    echo "Tab [$next_index] [$next_tab_id] is empty, falling back to second-last"
    next_index=$(( next_index - 1 ))
    next_tab_id=$(echo "$tabs_json" | jq -r ".[$next_index].id")
    next_tab_title=$(echo "$tabs_json" | jq -r ".[$next_index].title")
    next_tab_url=$(echo "$tabs_json" | jq -r ".[$next_index].url")
fi

# Activate the next tab
curl -s "http://localhost:$DEBUG_PORT/json/activate/$next_tab_id" > /dev/null
echo "Switched to tab [$next_index]: $next_tab_title ($next_tab_url | $next_tab_id) (total of $total_tabs)"