#!/bin/bash

# Installation directory
PIOSK_DIR="/opt/piosk"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "Checking superuser privileges..."
if [ "$EUID" -ne 0 ]; then
  echo "${RED}Not running as superuser. Escalating...${RESET}"

  # Re-execute the script with sudo
  sudo "$0" "$@"
  exit $?  # Exit with the status of the sudo command
fi

echo "Configuring autologin..."
if grep -q "autologin" "/etc/systemd/system/getty@tty1.service.d/autologin.conf" 2>/dev/null; then
  echo "${GREEN}autologin is enabled!${RESET}."
else
  echo "${RED}autologin is disabled!${RESET}"
  raspi-config nonint do_boot_behaviour B4
fi

echo "Installing dependencies..."
apt install -y git jq wtype nodejs npm

echo "Cloning repository..."
git clone https://github.com/debloper/piosk.git $PIOSK_DIR

echo "Checking out latest release..."
cd $PIOSK_DIR
git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

echo "Installing npm dependencies..."
npm i

echo "Installing PiOSK services..."

# Variables based on $SUDO_USER
PI_USER="$SUDO_USER"
PI_USER_HOME_DIR=$(eval echo ~$SUDO_USER)
PI_USER_ID=$(id -u $SUDO_USER)

sed -e "s|PI_USER_HOME_DIR|$PI_USER_HOME_DIR|g" \
    -e "s|PI_USER_ID|$PI_USER_ID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/templates/piosk-browser.service" > "/etc/systemd/system/piosk-browser.service"

sed -e "s|PI_USER_HOME_DIR|$PI_USER_HOME_DIR|g" \
    -e "s|PI_USER_ID|$PI_USER_ID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/templates/piosk-switcher.service" > "/etc/systemd/system/piosk-switcher.service"

echo "${BLUE}Reloading systemd daemons...${RESET}"
systemctl daemon-reload
echo "${BLUE}Enabling PiOSK daemons...${RESET}"
systemctl enable piosk-browser
systemctl enable piosk-switcher
systemctl enable piosk-webserver

echo "${BLUE}Starting scripts, may take up to 30 seconds...${RESET}"
#fork the switcher due to the long PreStart sleep, otherwise the setup script will block
systemctl start piosk-browser
systemctl start piosk-switcher &
systemctl start piosk-webserver

echo "${GREEN}${BOLD}Installation is complete. PiOSK should be running.${RESET}"
