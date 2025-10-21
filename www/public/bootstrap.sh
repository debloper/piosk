#!/usr/bin/env bash
set -euo pipefail

# PiOSK Bootstrap Script (v5)
# This script fetches the latest PiOSK package and dispatches to the correct internal script.
# 
# Usage:
# curl -sSL https://code.debs.io/piosk/bootstrap.sh | sudo bash -s -- [command]

# --- Configuration ---
readonly PIOSK_REPO="debloper/piosk"
readonly PIOSK_INSTALL_DIR="/opt/piosk"
readonly PIOSK_TEMP_DIR="/opt/piosk.new"

# --- ANSI Color Codes & Helper ---
RESET="\033[0m"
ERROR="\033[1;31m"
SUCCESS="\033[1;32m"
INFO="\033[1;34m"

msg() {
    local color="$1"
    local text="$2"
    echo -e "${color}${text}${RESET}"
}

# --- Sudo Check ---
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        msg "$ERROR" "This script must be run as root. Please use sudo."
        exit 1
    fi
}

# --- Core Logic ---
# Downloads and extracts the latest PiOSK release to a specified directory.
download_and_extract() {
    local target_dir="$1"

    msg "$INFO" "Determining package architecture..."
    local ARCH
    ARCH=$(uname -m)
    local PKG_ARCH
    case "${ARCH}" in
      x86_64) PKG_ARCH="linux-x86_64" ;;
      aarch64|arm64) PKG_ARCH="linux-aarch64" ;;
      *) msg "$ERROR" "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    local tarball_name="piosk-${PKG_ARCH}.tar.gz"
    
    local download_url="https://github.com/$PIOSK_REPO/releases/latest/download/$tarball_name"
    local temp_tarball="/tmp/$tarball_name"
    
    msg "$INFO" "Downloading latest package for '$PKG_ARCH'..."
    if ! curl -fL --progress-bar "$download_url" -o "$temp_tarball"; then
        msg "$ERROR" "Download failed. Check the URL or your network connection."
        exit 1
    fi

    msg "$INFO" "Extracting to $target_dir..."
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    tar -xzf "$temp_tarball" -C "$target_dir"
    
    rm -f "$temp_tarball"
    msg "$SUCCESS" "Package successfully prepared."
}

show_help() {
    echo "Usage: curl ... | sudo bash -s -- [command]"
    echo "Commands:"
    echo "  --install   Install PiOSK."
    echo "  --update    Update an existing installation."
    echo "  --cleanup   Uninstall PiOSK (requires local installation)."
    echo "  --backup    Backup configuration (requires local installation)."
}

# --- Main Execution ---
check_sudo

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

COMMAND=$1
shift || true # Shift arguments, ignore error if no args left

case "$COMMAND" in
    --install)
        download_and_extract "$PIOSK_INSTALL_DIR"
        bash "$PIOSK_INSTALL_DIR/scripts/setup/install.sh" "$SUDO_USER" "$@"
        ;;
    --update)
        if [ -f "$PIOSK_INSTALL_DIR/scripts/setup/backup.sh" ]; then
            msg "$INFO" "Backing up existing configuration before updating..."
            bash "$PIOSK_INSTALL_DIR/scripts/setup/backup.sh"
        fi
        download_and_extract "$PIOSK_TEMP_DIR"
        bash "$PIOSK_TEMP_DIR/scripts/setup/update.sh" "$SUDO_USER" "$@"
        ;;
    --cleanup)
        if [ ! -f "$PIOSK_INSTALL_DIR/scripts/setup/cleanup.sh" ]; then
            msg "$ERROR" "PiOSK is not installed. Cannot run cleanup."
            exit 1
        fi
        bash "$PIOSK_INSTALL_DIR/scripts/setup/cleanup.sh" "$@"
        ;;
    --backup)
        if [ ! -f "$PIOSK_INSTALL_DIR/scripts/setup/backup.sh" ]; then
            msg "$ERROR" "PiOSK is not installed. Cannot run backup."
            exit 1
        fi
        bash "$PIOSK_INSTALL_DIR/scripts/setup/backup.sh" "$@"
        ;;
    *)
        msg "$ERROR" "Invalid command: $COMMAND"
        show_help
        exit 1
        ;;
esac

