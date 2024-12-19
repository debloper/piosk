#!/bin/bash

# Define colors using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

PI_USER="$SUDO_USER"
PI_USER_HOME_DIR=$(eval echo ~$SUDO_USER)

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "${RED}This script requires root privileges. Attempting to escalate...${RESET}"

  # Re-execute the script with sudo
  sudo "$0" "$@"
  exit $?  # Exit with the status of the sudo command
fi

  echo "${GREEN}Running as root. Continuing with the uninstallation...${RESET}"

#first backup the config.json file
cp /opt/piosk/config.json $PI_USER_HOME_DIR/config.json.bak
chown $PI_USER:$PI_USER $PI_USER_HOME_DIR/config.json.bak

echo "${BLUE}${BOLD}/opt/piosk/config.json${RESET}${GREEN} backed up to ${BOLD}$PI_USER_HOME_DIR/config.json.bak${RESET}"

echo "${BLUE}Stopping all systemd services, please wait...${RESET}"

systemctl stop piosk-switcher
systemctl stop piosk-webserver
systemctl stop piosk-browser

echo "${BLUE}Deleting all piosk systemd services...${RESET}"

rm /etc/systemd/system/piosk-switcher.service
rm /etc/systemd/system/piosk-webserver.service
rm /etc/systemd/system/piosk-browser.service

echo "${BLUE}Reloading systemd...${RESET}"

systemctl daemon-reload

echo "${BLUE}Deleting package files...${RESET}"

rm -rf /opt/piosk

echo "${GREEN}Uninstallation complete...${RESET}"
