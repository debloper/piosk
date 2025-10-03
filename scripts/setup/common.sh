#!/usr/bin/env bash

# This script is intended to be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed." >&2
    exit 1
fi

# --- Configuration ---
readonly PIOSK_INSTALL_DIR="/opt/piosk"
readonly PIOSK_CONFIG_FILE="$PIOSK_INSTALL_DIR/config.json"
readonly PIOSK_TEMP_DIR="/opt/piosk.new"

# --- ANSI Color Codes ---
RESET='\033[0m'
ERROR='\033[1;31m'
SUCCESS='\033[1;32m'
WARNING='\033[1;33m'
INFO='\033[1;34m'
CALLOUT='\033[1;35m'
DEBUG='\033[1;36m'

# --- Helper Function ---
msg() {
    local color="$1"
    local text="$2"
    echo -e "${color}${text}${RESET}"
}

