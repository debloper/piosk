#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$INFO" "Starting XiOSK installation..."

# 1. IDENTIFY USER
PI_USER="${1:-$SUDO_USER}"
if [ -z "$PI_USER" ]; then
    msg "$ERROR" "Could not determine target user. Ensure SUDO_USER is set."
    exit 1
fi
msg "$SUCCESS" "Target user identified as '$PI_USER'."

# 2. INSTALL RUNTIME DEPENDENCIES
msg "$INFO" "Installing runtime dependencies (wtype, chromium)..."
apt-get update
apt-get install -y wtype chromium jq

# 3. INSTALL BINARY
msg "$INFO" "Installing XiOSK binary..."
BINARY_FILE="$XIOSK_INSTALL_DIR/dashboard/xiosk"
if [ ! -f "$BINARY_FILE" ]; then
    msg "$ERROR" "XiOSK binary not found. Package is corrupt."
    exit 1
fi
chmod +x "$BINARY_FILE"
msg "$SUCCESS" "Binary prepared at $BINARY_FILE"

# 4. SETUP CONFIGURATION
msg "$INFO" "Setting up configuration file..."
if [ ! -f "$XIOSK_CONFIG_FILE" ]; then
    mv "$XIOSK_INSTALL_DIR/config.json.sample" "$XIOSK_CONFIG_FILE"
    msg "$DEBUG" "Created default config.json from sample."
fi

# 5. INSTALL SYSTEMD SERVICES
msg "$INFO" "Installing systemd services..."
PI_HOME=$(getent passwd "$PI_USER" | cut -d: -f6)
PI_SUID=$(id -u "$PI_USER")

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$XIOSK_INSTALL_DIR/services/xiosk-runner.template" > "/etc/systemd/system/xiosk-runner.service"

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$XIOSK_INSTALL_DIR/services/xiosk-switcher.template" > "/etc/systemd/system/xiosk-switcher.service"

cp "$XIOSK_INSTALL_DIR/services/xiosk-dashboard.template" /etc/systemd/system/xiosk-dashboard.service


# 6. FINALIZE
msg "$INFO" "Reloading systemd and enabling services..."
systemctl daemon-reload
systemctl enable xiosk-runner.service xiosk-switcher.service xiosk-dashboard.service
systemctl start xiosk-dashboard.service

# 7. USER INSTRUCTIONS
echo
msg "$CALLOUT" "XiOSK is now installed."
echo -e "Visit either of these links to access the dashboard:"
echo -e "\t- ${SUCCESS}http://$(hostname)/${RESET}"
echo -e "\t- ${SUCCESS}http://$(hostname -I | cut -d ' ' -f 1)/${RESET}"
msg "$WARNING" "The kiosk mode will launch on the next startup."

