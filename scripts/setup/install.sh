#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$INFO" "Starting PiOSK installation..."

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
msg "$INFO" "Installing PiOSK binary..."
BINARY_FILE="$PIOSK_INSTALL_DIR/dashboard/piosk"
if [ ! -f "$BINARY_FILE" ]; then
    msg "$ERROR" "PiOSK binary not found. Package is corrupt."
    exit 1
fi
chmod +x "$BINARY_FILE"
msg "$SUCCESS" "Binary prepared at $BINARY_FILE"

# 4. SETUP CONFIGURATION
msg "$INFO" "Setting up configuration file..."
if [ ! -f "$PIOSK_CONFIG_FILE" ]; then
    mv "$PIOSK_INSTALL_DIR/config.json.sample" "$PIOSK_CONFIG_FILE"
    msg "$DEBUG" "Created default config.json from sample."
fi

# 5. INSTALL SYSTEMD SERVICES
msg "$INFO" "Installing systemd services..."
PI_HOME=$(getent passwd "$PI_USER" | cut -d: -f6)
PI_SUID=$(id -u "$PI_USER")

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_INSTALL_DIR/services/piosk-runner.template" > "/etc/systemd/system/piosk-runner.service"

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_INSTALL_DIR/services/piosk-switcher.template" > "/etc/systemd/system/piosk-switcher.service"

cp "$PIOSK_INSTALL_DIR/services/piosk-dashboard.template" /etc/systemd/system/piosk-dashboard.service


# 6. FINALIZE
msg "$INFO" "Reloading systemd and enabling services..."
systemctl daemon-reload
systemctl enable piosk-runner.service piosk-switcher.service piosk-dashboard.service
systemctl start piosk-dashboard.service

# 7. USER INSTRUCTIONS
echo
msg "$CALLOUT" "PiOSK is now installed."
echo -e "Visit either of these links to access the dashboard:"
echo -e "\t- ${SUCCESS}http://$(hostname)/${RESET}"
echo -e "\t- ${SUCCESS}http://$(hostname -I | cut -d ' ' -f 1)/${RESET}"
msg "$WARNING" "The kiosk mode will launch on the next startup."

