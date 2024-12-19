#!/bin/bash

#our vars
#autologin files for a raspberry pi
AUTOLGIN_CONF_DIR="/etc/systemd/system/getty@tty1.service.d"
AUTOLGIN_CONF_FILE="$AUTOLGIN_CONF_DIR/autologin.conf"


# Get the directory of the package
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Destination directory
DEST_DIR="/opt/piosk"

# Define colors using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Function to check current autologin status
check_autologin() {
  echo "Checking if autologin is already enabled..."
  if grep -q "autologin" $AUTOLGIN_CONF_FILE 2>/dev/null; then
    # enabled
    return 0
  else
    # not enabled
    return 1
  fi
}

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "${RED}This script requires root privileges. Attempting to escalate...${RESET}"
  
  # Re-execute the script with sudo
  sudo "$0" "$@"
  exit $?  # Exit with the status of the sudo command
fi

  echo "${GREEN}Running as root. Continuing with the installation...${RESET}"

# Function to check current autologin status
check_autologin() {
  if grep -q "autologin" $AUTOLGIN_CONF_FILE 2>/dev/null; then
    #Autologin is already enabled.
    return 0
  else
    #Autologin is not enabled.
    return 1
  fi
}

# Main logic
if check_autologin; then
  echo "${GREEN}Autologin is configured properly!${RESET}."
else
  echo "${RED}Autologin is NOT configured! Piosk will not function! Halting installation!${RESET}"	
  echo "To enable autologin, please run the following command:"
  echo "sudo raspi-config"
  echo "Navigate to 'System Options' > 'Boot / Auto Login' > 'Desktop Autologin'."
  exit 1
fi
 
# Create the destination directory if it doesn't exist
sudo mkdir -p "$DEST_DIR"

# Copy files from the script's directory to the destination
echo "${BLUE}Copying application files from $SCRIPT_DIR to $DEST_DIR...${RESET}"
sudo cp -r "$SCRIPT_DIR/"* "$DEST_DIR/"

# Set proper permissions (optional)
sudo chown -R $SUDO_USER:$SUDO_USER "$DEST_DIR"
sudo chmod -R 755 "$DEST_DIR"

echo "${GREEN}Application files copied to $DEST_DIR.${GREEN}"

echo "${BLUE}Installing node, wtype and dependencies.${RESET}"
apt install -y git jq nodejs wtype npm

echo "${BLUE}Installing npm dependencies...${RESET}"

cd $DEST_DIR
npm i

echo "${BLUE}Installing systemd services${RESET}"

# Variables based on $SUDO_USER
PI_USER="$SUDO_USER"
PI_USER_HOME_DIR=$(eval echo ~$SUDO_USER)
PI_USER_ID=$(id -u $SUDO_USER)

TEMPLATE_FILE="$DEST_DIR/templates/piosk-browser.service"
OUTPUT_FILE="/etc/systemd/system/piosk-browser.service"

# Verify the template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file $TEMPLATE_FILE not found!"
  exit 1
fi

# Replace placeholders in the template file
echo "${BLUE}Customizing systemd service for user: $PI_USER${RESET}"
sed -e "s|PI_USER_HOME_DIR|$PI_USER_HOME_DIR|g" \
    -e "s|PI_USER_ID|$PI_USER_ID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"
TEMPLATE_FILE="$DEST_DIR/templates/piosk-switcher.service"
OUTPUT_FILE="/etc/systemd/system/piosk-switcher.service"

sed -e "s|PI_USER_HOME_DIR|$PI_USER_HOME_DIR|g" \
    -e "s|PI_USER_ID|$PI_USER_ID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

TEMPLATE_FILE="$DEST_DIR/templates/piosk-webserver.service"
OUTPUT_FILE="/etc/systemd/system/piosk-webserver.service"


sed -e "s|PI_USER_HOME_DIR|$PI_USER_HOME_DIR|g" \
    -e "s|PI_USER_ID|$PI_USER_ID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "${BLUE}Reloading systemd daemons...${RESET}"
systemctl daemon-reload
echo "${BLUE}Enabling scripts...${RESET}"
systemctl enable piosk-browser
systemctl enable piosk-switcher
systemctl enable piosk-browser

echo "${BLUE}Starting scripts, may take up to 30 seconds...${RESET}"
#fork the switcher due to the long PreStart sleep, otherwise the setup script will block
systemctl start piosk-browser
systemctl start piosk-switcher &
systemctl start piosk-webserver

echo "${GREEN}${BOLD}Installation is complete. Piosk should be running.${RESET}"

