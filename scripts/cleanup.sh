#!/bin/bash
set -e

# Installation directory
PIOSK_DIR="/opt/piosk"

RESET='\033[0m'      # Reset to default
ERROR='\033[1;31m'   # Bold Red
SUCCESS='\033[1;32m' # Bold Green
WARNING='\033[1;33m' # Bold Yellow
INFO='\033[1;34m'    # Bold Blue
CALLOUT='\033[1;35m' # Bold Magenta
DEBUG='\033[1;36m'   # Bold Cyan

echo -e "${INFO}Checking superuser privileges...${RESET}"
if [ "$EUID" -ne 0 ]; then
  echo -e "${ERROR}Not running as superuser. Escalating...${RESET}"

  sudo "$0" "$@" # Re-execute the script as superuser
  exit $?  # Exit with the status of the sudo command
fi

echo -e "${INFO}Backing up configuration...${RESET}"
cp /opt/piosk/config.json /opt/piosk.config.bak

echo -e "${INFO}Stopping PiOSK services...${RESET}"
systemctl stop piosk-switcher
systemctl stop piosk-runner
systemctl stop piosk-dashboard

echo -e "${INFO}Disabling PiOSK services...${RESET}"
systemctl disable piosk-switcher
systemctl disable piosk-runner
systemctl disable piosk-dashboard

echo -e "${INFO}Removing PiOSK services...${RESET}"
rm /etc/systemd/system/piosk-switcher.service
rm /etc/systemd/system/piosk-runner.service
rm /etc/systemd/system/piosk-dashboard.service

echo -e "${INFO}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo -e "${INFO}Removing PiOSK directory...${RESET}"
rm -rf /opt/piosk

echo -e "${CALLOUT}Successfully uninstalled PiOSK.${RESET}"
