#!/bin/bash
set -e

PIOSK_DIR="/opt/piosk"
REPO_URL="https://github.com/debloper/piosk.git"

RESET='\033[0m'      # Reset to default
ERROR='\033[1;31m'   # Bold Red
SUCCESS='\033[1;32m' # Bold Green
WARNING='\033[1;33m' # Bold Yellow
INFO='\033[1;34m'    # Bold Blue
CALLOUT='\033[1;35m' # Bold Magenta
DEBUG='\033[1;36m'   # Bold Cyan

# This function builds the binary from source if a pre-compiled release can't be downloaded.
install_from_source() {
    echo -e "${WARNING}Falling back to building from source. This will take longer.${RESET}"
    
    echo -e "${INFO}Installing build dependencies (Node.js, npm, git)...${RESET}"
    apt-get install -y nodejs npm git
    
    echo -e "${INFO}Cloning repository...${RESET}"
    git clone "$REPO_URL" "$PIOSK_DIR"
    cd "$PIOSK_DIR"

    echo -e "${INFO}Installing Node.js dependencies...${RESET}"
    npm install --omit=dev

    echo -e "${INFO}Building PiOSK binary locally...${RESET}"
    # This is a simplified local build. It uses the system's own Node.js binary.
    cat <<EOF > sea-config.json
    {
      "main": "index.js",
      "output": "piosk.blob",
      "disableExperimentalSEAWarning": true,
      "assets": { "web/index.html": "./web/index.html", "web/script.js": "./web/script.js" }
    }
EOF
    node --experimental-sea-config sea-config.json
    cp "$(command -v node)" piosk
    npx postject piosk NODE_SEA_BLOB piosk.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2
    
    echo -e "${SUCCESS}Local build complete.${RESET}"
}

# --- Main Script Execution ---

echo -e "${INFO}Checking for superuser privileges...${RESET}"
if [ "$EUID" -ne 0 ]; then
  echo -e "${DEBUG}Privileges not found. Re-executing with sudo...${RESET}"
  sudo "$0" "$@"
  exit $?
fi

echo -e "${INFO}Installing runtime dependencies...${RESET}"
apt-get update && apt-get install -y jq wtype curl chromium-browser

# Clean up previous installation if it exists
if [ -d "$PIOSK_DIR" ]; then
    echo -e "${INFO}Removing previous PiOSK installation...${RESET}"
    # Stop services before removing files
    systemctl stop piosk-dashboard.service piosk-runner.service piosk-switcher.service || true
    rm -rf "$PIOSK_DIR"
fi
mkdir -p "$PIOSK_DIR"

# --- Download Binary or Build from Source ---
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/debloper/piosk/releases/latest" | jq -r '.tag_name')

if [ "$LATEST_RELEASE" = "null" ] || [ -z "$LATEST_RELEASE" ]; then
    echo -e "${WARNING}No GitHub releases found.${RESET}"
    install_from_source
else
    ARCH=$(uname -m)
    ASSET_NAME=""
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        ASSET_NAME="piosk-linux-arm64.tar.gz"
    elif [[ "$ARCH" == "armv7l" ]]; then
        ASSET_NAME="piosk-linux-armv7.tar.gz"
    else
        echo -e "${ERROR}Unsupported architecture for release download: $ARCH${RESET}"
        install_from_source
    fi

    if [ -n "$ASSET_NAME" ]; then
        DOWNLOAD_URL="https://github.com/debloper/piosk/releases/download/$LATEST_RELEASE/$ASSET_NAME"
        echo -e "${DEBUG}Downloading from: $DOWNLOAD_URL${RESET}"

        # Download and extract the release package
        if curl -fsSL "$DOWNLOAD_URL" | tar -xz -C "$PIOSK_DIR"; then
            echo -e "${SUCCESS}PiOSK downloaded and extracted successfully.${RESET}"
        else
            echo -e "${ERROR}Failed to download binary release.${RESET}"
            install_from_source
        fi
    fi
fi

cd "$PIOSK_DIR"
# Ensure all necessary files are executable
chmod +x "$PIOSK_DIR/piosk"
chmod +x "$PIOSK_DIR/scripts/"*.sh

# ... (Configuration restore logic here) ...

echo -e "${INFO}Installing PiOSK services...${RESET}"
PI_USER="${SUDO_USER:-$USER}"
PI_SUID=$(id -u "$PI_USER")
PI_HOME=$(getent passwd "$PI_USER" | cut -d: -f6)

# Use a temporary file for sed to avoid issues with stdin
DASHBOARD_SERVICE_TMP=$(mktemp)
sed "s|ExecStart=.*|ExecStart=$PIOSK_DIR/piosk|" "$PIOSK_DIR/services/piosk-dashboard.template" > "$DASHBOARD_SERVICE_TMP"
cp "$DASHBOARD_SERVICE_TMP" /etc/systemd/system/piosk-dashboard.service
rm "$DASHBOARD_SERVICE_TMP"

sed -e "s|PI_HOME|$PI_HOME|g" -e "s|PI_USER|$PI_USER|g" "$PIOSK_DIR/services/piosk-runner.template" > /etc/systemd/system/piosk-runner.service
sed -e "s|PI_HOME|$PI_HOME|g" -e "s|PI_USER|$PI_USER|g" "$PIOSK_DIR/services/piosk-switcher.template" > /etc/systemd/system/piosk-switcher.service

echo -e "${INFO}Reloading systemd daemons...${RESET}"
systemctl daemon-reload

echo -e "${INFO}Enabling PiOSK services...${RESET}"
systemctl enable piosk-dashboard.service piosk-runner.service piosk-switcher.service

echo -e "${INFO}Starting PiOSK dashboard...${RESET}"
systemctl start piosk-dashboard.service
echo -e "${SUCCESS}\nPiOSK is now installed.${RESET}"
