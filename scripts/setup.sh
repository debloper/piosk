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
  echo -e "${DEBUG}Escalating privileges as superuser...${RESET}"

  sudo "$0" "$@" # Re-execute the script as superuser
  exit $?  # Exit with the status of the sudo command
fi

echo -e "${INFO}Configuring autologin...${RESET}"
if grep -q "autologin" "/etc/systemd/system/getty@tty1.service.d/autologin.conf" 2>/dev/null; then
  echo -e "${SUCCESS}\tautologin is already enabled!${RESET}."
else
  if command -v raspi-config >/dev/null 2>&1; then
    echo -e "${DEBUG}Enabling autologin using raspi-config...${RESET}"
    raspi-config nonint do_boot_behaviour B4
  else
    echo -e "${ERROR}Could not enable autologin${RESET}"
    echo -e "${ERROR}Please configure autologin manually and rerun setup.${RESET}"
  fi
  echo -e "${SUCCESS}\tautologin has been enabled!${RESET}"
fi

echo -e "${INFO}Installing dependencies...${RESET}"
apt install -y git jq wtype curl unzip

echo -e "${INFO}Cloning repository...${RESET}"
git clone https://github.com/debloper/piosk.git "$PIOSK_DIR"
cd "$PIOSK_DIR"

# echo -e "${INFO}Checking out latest release...${RESET}"
# git checkout devel
# git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

echo -e "${INFO}Downloading PiOSK binary...${RESET}"
# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    BINARY_NAME="piosk-linux-x64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    BINARY_NAME="piosk-linux-arm64"
else
    echo -e "${ERROR}Unsupported architecture: $ARCH${RESET}"
    echo -e "${INFO}Falling back to source installation with Deno...${RESET}"
    
    # Install Deno as fallback
    curl -fsSL https://deno.land/x/install/install.sh | sh
    export PATH="$HOME/.deno/bin:$PATH"
    ln -sf $HOME/.deno/bin/deno /usr/local/bin/deno
    
    echo -e "${INFO}Compiling PiOSK with Deno...${RESET}"
    deno compile --allow-net --allow-read --allow-write --allow-run --allow-env --output piosk index.ts
else
    # Download binary from latest release
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/debloper/piosk/releases/latest | jq -r '.tag_name')
    if [ "$LATEST_RELEASE" = "null" ] || [ -z "$LATEST_RELEASE" ]; then
        echo -e "${WARNING}No releases found, falling back to source installation...${RESET}"
        # Install Deno as fallback
        curl -fsSL https://deno.land/x/install/install.sh | sh
        export PATH="$HOME/.deno/bin:$PATH"
        ln -sf $HOME/.deno/bin/deno /usr/local/bin/deno
        
        echo -e "${INFO}Compiling PiOSK with Deno...${RESET}"
        deno compile --allow-net --allow-read --allow-write --allow-run --allow-env --output piosk index.ts
    else
        DOWNLOAD_URL="https://github.com/debloper/piosk/releases/download/$LATEST_RELEASE/$BINARY_NAME.tar.gz"
        echo -e "${DEBUG}Downloading from: $DOWNLOAD_URL${RESET}"
        
        if curl -fsSL "$DOWNLOAD_URL" | tar -xz; then
            chmod +x "$BINARY_NAME"
            mv "$BINARY_NAME" piosk
        else
            echo -e "${ERROR}Failed to download binary, falling back to source installation...${RESET}"
            # Install Deno as fallback
            curl -fsSL https://deno.land/x/install/install.sh | sh
            export PATH="$HOME/.deno/bin:$PATH"
            ln -sf $HOME/.deno/bin/deno /usr/local/bin/deno
            
            echo -e "${INFO}Compiling PiOSK with Deno...${RESET}"
            deno compile --allow-net --allow-read --allow-write --allow-run --allow-env --output piosk index.ts
        fi
    fi
fi

echo -e "${INFO}Restoring configurations...${RESET}"
if [ ! -f /opt/piosk/config.json ]; then
    if [ -f /opt/piosk.config.bak ]; then
        mv /opt/piosk.config.bak /opt/piosk/config.json
    else
        mv config.json.sample config.json
    fi
fi

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
echo -e "Configure links to shuffle; then apply changes to reboot."
echo -e "${WARNING}\033[0;31mThe kiosk mode will launch on next startup.${RESET}"
