#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$INFO" "Uninstalling XiOSK..."
msg "$INFO" "A backup of your configuration will be created before cleanup."
bash "$SCRIPT_DIR/backup.sh"

msg "$DEBUG" "Stopping and disabling systemd services..."
systemctl stop xiosk-dashboard xiosk-runner xiosk-switcher &>/dev/null || true
systemctl disable xiosk-dashboard xiosk-runner xiosk-switcher &>/dev/null || true

msg "$DEBUG" "Removing systemd service files..."
rm -f /etc/systemd/system/xiosk-*.service

msg "$DEBUG" "Reloading systemd daemon..."
systemctl daemon-reload

msg "$DEBUG" "Removing installation directory: $XIOSK_INSTALL_DIR"
rm -rf "$XIOSK_INSTALL_DIR"
rm -f /opt/xiosk.config.bak

msg "$SUCCESS" "XiOSK has been successfully uninstalled."

