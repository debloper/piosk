#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$INFO" "Starting configuration backup..."

readonly backup_dir="/opt/xiosk-backups"
readonly latest_file="$backup_dir/xiosk-latest.config"

if [ ! -f "$XIOSK_CONFIG_FILE" ]; then
    msg "$WARNING" "Configuration file not found at '$XIOSK_CONFIG_FILE'. Nothing to back up."
    exit 0
fi

mkdir -p "$backup_dir"

if [ -f "$latest_file" ]; then
    last_backup_timestamp=$(date -d "@$(stat -c %Y "$latest_file")" +"%Y-%m-%d_%H%M%S")
    archived_filename="config-${last_backup_timestamp}.json"
    mv "$latest_file" "$backup_dir/$archived_filename"
fi

cp "$XIOSK_CONFIG_FILE" "$latest_file"
msg "$SUCCESS" "Backup successful! Latest config saved to: $latest_file"

msg "$DEBUG" "Applying retention policy (keeping last 5)..."
while [ "$(ls -1 "$backup_dir"/config-*.json 2>/dev/null | wc -l)" -gt 5 ]; do
    oldest_backup=$(ls -1 "$backup_dir"/config-*.json | head -n 1)
    rm "$oldest_backup"
done

