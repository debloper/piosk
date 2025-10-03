#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$INFO" "Uninstalling PiOSK..."
msg "$INFO" "A backup of your configuration will be created before cleanup."
bash "$SCRIPT_DIR/backup.sh"

msg "$DEBUG" "Stopping and disabling systemd services..."
systemctl stop piosk-dashboard piosk-runner piosk-switcher &>/dev/null || true
systemctl disable piosk-dashboard piosk-runner piosk-switcher &>/dev/null || true

msg "$DEBUG" "Removing systemd service files..."
rm -f /etc/systemd/system/piosk-*.service

msg "$DEBUG" "Reloading systemd daemon..."
systemctl daemon-reload

msg "$DEBUG" "Removing installation directory: $PIOSK_INSTALL_DIR"
rm -rf "$PIOSK_INSTALL_DIR"
rm -f /opt/piosk.config.bak

msg "$SUCCESS" "PiOSK has been successfully uninstalled."

