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
git checkout devel
# git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

echo "Installing npm dependencies..."
npm i

echo "Installing PiOSK services..."
PI_USER=$SUDO_USER
PI_SUID=$(id -u $SUDO_USER)
PI_HOME=$(eval echo ~$SUDO_USER)

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    $PIOSK_DIR/services/piosk-runner.template > /etc/systemd/system/piosk-runner.service

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    $PIOSK_DIR/services/piosk-switcher.template > /etc/systemd/system/piosk-switcher.service

cp $PIOSK_DIR/services/piosk-dashboard.template /etc/systemd/system/piosk-dashboard.service

echo "${BLUE}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo "${BLUE}Enabling PiOSK daemons...${RESET}"
systemctl enable piosk-runner
systemctl enable piosk-switcher
systemctl enable piosk-dashboard

echo "${BLUE}Starting PiOSK daemons...${RESET}"
systemctl start piosk-runner
systemctl start piosk-switcher
systemctl start piosk-dashboard

echo "${GREEN}${BOLD}Installation is complete. PiOSK should be running.${RESET}"
