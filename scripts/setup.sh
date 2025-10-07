#!/bin/bash
set -e

# --- ANSI Colors ---
RESET='\033[0m'
INFO='\033[1;34m'
SUCCESS='\033[1;32m'
ERROR='\033[1;31m'
DEBUG='\033[1;36m'

# --- Constants ---
REPO_OWNER="debloper"
REPO_NAME="piosk"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
INSTALL_DIR="/opt/${REPO_NAME}"
CONFIG_FILE="${INSTALL_DIR}/config.json"
CONFIG_BACKUP="/opt/piosk.config.bak"

echo -e "${INFO}Fetching latest release tag...${RESET}"
LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | jq -r '.tag_name')

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
  echo -e "${ERROR}❌ Failed to fetch latest release tag from GitHub.${RESET}"
  exit 1
fi
echo -e "${SUCCESS}✅ Latest release detected: ${LATEST_TAG}${RESET}"

# --- Ensure git is available ---
if ! command -v git >/dev/null 2>&1; then
  echo -e "${INFO}Installing git...${RESET}"
  apt update -qq && apt install -y git >/dev/null
fi

# --- Backup existing config if present ---
if [ -f "$CONFIG_FILE" ]; then
  echo -e "${DEBUG}Backing up existing configuration...${RESET}"
  cp "$CONFIG_FILE" "$CONFIG_BACKUP"
fi

# --- Clone or update repo ---
if [ -d "$INSTALL_DIR" ]; then
  echo -e "${DEBUG}Removing old ${INSTALL_DIR}...${RESET}"
  rm -rf "$INSTALL_DIR"
fi

echo -e "${INFO}Cloning ${REPO_URL}@${LATEST_TAG}...${RESET}"
git clone --depth 1 --branch "$LATEST_TAG" "$REPO_URL" "$INSTALL_DIR"

# --- Restore configuration if backup exists ---
if [ -f "$CONFIG_BACKUP" ]; then
  echo -e "${DEBUG}Restoring previous configuration...${RESET}"
  mv "$CONFIG_BACKUP" "$CONFIG_FILE"
fi

# --- Run installer from tag ---
cd "$INSTALL_DIR/scripts"
echo -e "${INFO}Running install.sh from ${LATEST_TAG}...${RESET}"
if bash install.sh "$@"; then
  echo -e "${SUCCESS}✅ PiOSK installed successfully (tag ${LATEST_TAG}).${RESET}"
else
  echo -e "${ERROR}❌ Installation failed for tag ${LATEST_TAG}.${RESET}"
  exit 1
fi