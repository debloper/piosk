#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Installation directory
PIOSK_DIR="/opt/piosk"

# --- ANSI Color Codes ---
RESET='\033[0m'      # Reset to default
ERROR='\033[1;31m'   # Bold Red
SUCCESS='\033[1;32m' # Bold Green
WARNING='\033[1;33m' # Bold Yellow
INFO='\033[1;34m'    # Bold Blue
CALLOUT='\033[1;35m' # Bold Magenta
DEBUG='\033[1;36m'   # Bold Cyan

# --- Sudo Privilege Check ---
echo -e "${INFO}Checking superuser privileges...${RESET}"
if [ "$EUID" -ne 0 ]; then
  echo -e "${DEBUG}Escalating privileges as superuser...${RESET}"

  sudo "$0" "$@" # Re-execute the script as superuser
  exit $?  # Exit with the status of the sudo command
fi

# --- Autologin Configuration ---
echo -e "${INFO}Configuring autologin...${RESET}"
if grep -q "autologin" "/etc/systemd/system/getty@tty1.service.d/autologin.conf" 2>/dev/null; then
  echo -e "${SUCCESS}\tautologin is already enabled!${RESET}."
else
  if command -v raspi-config >/dev/null 2>&1; then
    echo -e "${DEBUG}Enabling autologin using raspi-config...${RESET}"
    raspi-config nonint do_boot_behaviour B4
    echo -e "${SUCCESS}\tAutologin has been enabled!${RESET}"
  else
    echo -e "${ERROR}Could not enable autologin${RESET}"
    echo -e "${ERROR}Please configure autologin manually and rerun setup.${RESET}"
    exit 1
  fi
fi

# --- Dependency Installation ---
echo -e "${INFO}Installing dependencies...${RESET}"
apt update && apt install -y git jq wtype curl unzip

# --- Repo Cloning ---
echo -e "${INFO}Cloning repository...${RESET}"

# Before deleting the directory, check if a config file exists and back it up.
if [ -f "$PIOSK_DIR/config.json" ]; then
    echo -e "${DEBUG}Found existing installation. Backing up config.json...${RESET}"
    cp "$PIOSK_DIR/config.json" /opt/piosk.config.bak
fi

rm -rf "$PIOSK_DIR"
git clone https://github.com/debloper/piosk.git "$PIOSK_DIR"
cd "$PIOSK_DIR"

git checkout "d586dfa833187df34de8e8345b85c8d27be8bdc9"

# --- Binary Download ---
echo -e "${INFO}Downloading PiOSK binary...${RESET}"
ARCH=$(uname -m)
BINARY_NAME=""

case "${ARCH}" in
  x86_64)
    BINARY_NAME="piosk-linux-x64"
    ;;
  aarch64|arm64)
    BINARY_NAME="piosk-linux-arm64"
    ;;
  *)
    echo -e "${ERROR}Unsupported architecture: $ARCH${RESET}"
    echo -e "${ERROR}No pre-compiled binary is available for your system.${RESET}"
    exit 1
    ;;
esac

echo -e "${DEBUG}Architecture: '$ARCH', Binary: '$BINARY_NAME'${RESET}"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/debloper/piosk/releases/latest | jq -r '.tag_name')

if [ -z "$LATEST_RELEASE" ] || [ "$LATEST_RELEASE" = "null" ]; then
  echo -e "${ERROR}Could not find any releases on the GitHub repository.${RESET}"
  exit 1
fi

DOWNLOAD_URL="https://github.com/debloper/piosk/releases/download/$LATEST_RELEASE/$BINARY_NAME.tar.gz"
echo -e "${INFO}Downloading from: $DOWNLOAD_URL${RESET}"

if ! curl -fL --progress-bar "$DOWNLOAD_URL" | tar -xz; then
  echo -e "${ERROR}Failed to download or extract the binary.${RESET}"
  exit 1
fi

chmod +x "$BINARY_NAME"
mv "$BINARY_NAME" piosk
echo -e "${SUCCESS}PiOSK binary downloaded successfully.${RESET}"

# --- Configuration Setup ---
echo -e "${INFO}Restoring configurations...${RESET}"
if [ ! -f /opt/piosk/config.json ]; then
    if [ -f /opt/piosk.config.bak ]; then
        echo -e "${DEBUG}Restoring backed-up configuration...${RESET}"
        mv /opt/piosk.config.bak /opt/piosk/config.json
    else
        echo -e "${DEBUG}Creating default configuration from sample...${RESET}"
        mv config.json.sample config.json
    fi
fi

# --- Service Installation ---
echo -e "${INFO}Installing PiOSK services...${RESET}"
PI_USER="$SUDO_USER"
PI_SUID=$(id -u "$SUDO_USER")
PI_HOME=$(eval echo ~"$SUDO_USER")

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/services/piosk-runner.template" > "/etc/systemd/system/piosk-runner.service"

sed -e "s|PI_HOME|$PI_HOME|g" \
    -e "s|PI_SUID|$PI_SUID|g" \
    -e "s|PI_USER|$PI_USER|g" \
    "$PIOSK_DIR/services/piosk-switcher.template" > "/etc/systemd/system/piosk-switcher.service"

cp "$PIOSK_DIR/services/piosk-dashboard.template" /etc/systemd/system/piosk-dashboard.service

# --- Finalizing Setup ---
echo -e "${INFO}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo -e "${INFO}Enabling PiOSK daemons...${RESET}"
systemctl enable piosk-runner
systemctl enable piosk-switcher
systemctl enable piosk-dashboard

echo -e "${INFO}Starting PiOSK daemons...${RESET}"
# The runner and switcher services are meant to be started after reboot
# systemctl start piosk-runner
# systemctl start piosk-switcher
systemctl start piosk-dashboard

echo -e "${CALLOUT}\nPiOSK is now installed.${RESET}"
echo -e "Visit either of these links to access PiOSK dashboard:"
echo -e "\t- ${INFO}\033[0;32mhttp://$(hostname)/${RESET} or,"
echo -e "\t- ${INFO}http://$(hostname -I | cut -d " " -f1)/${RESET}"
echo -e "Use the dashboard to configure URLs, then apply changes to reboot."
echo -e "${WARNING}\033[0;31mThe kiosk mode will launch on next startup.${RESET}"
