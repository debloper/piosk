#!/usr/bin/env bash
set -euo pipefail

# XiOSK Bootstrap Script (v5)
# This script fetches the latest XiOSK package and dispatches to the correct internal script.
# 
# Usage:
# curl -sSL https://code.debs.io/xiosk/bootstrap.sh | sudo bash -s -- [command]

# --- Configuration ---
readonly XIOSK_REPO="debloper/xiosk"
readonly XIOSK_INSTALL_DIR="/opt/xiosk"
readonly XIOSK_TEMP_DIR="/opt/xiosk.new"

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
# Downloads and extracts the latest XiOSK release to a specified directory.
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
    
    local tarball_name="xiosk-${PKG_ARCH}.tar.gz"
    
    local download_url="https://github.com/$XIOSK_REPO/releases/latest/download/$tarball_name"
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
    echo "  --install   Install XiOSK."
    echo "  --update    Update an existing installation."
    echo "  --cleanup   Uninstall XiOSK (requires local installation)."
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
        download_and_extract "$XIOSK_INSTALL_DIR"
        bash "$XIOSK_INSTALL_DIR/scripts/setup/install.sh" "$SUDO_USER" "$@"
        ;;
    --update)
        if [ -f "$XIOSK_INSTALL_DIR/scripts/setup/backup.sh" ]; then
            msg "$INFO" "Backing up existing configuration before updating..."
            bash "$XIOSK_INSTALL_DIR/scripts/setup/backup.sh"
        fi
        download_and_extract "$XIOSK_TEMP_DIR"
        bash "$XIOSK_TEMP_DIR/scripts/setup/update.sh" "$SUDO_USER" "$@"
        ;;
    --cleanup)
        if [ ! -f "$XIOSK_INSTALL_DIR/scripts/setup/cleanup.sh" ]; then
            msg "$ERROR" "XiOSK is not installed. Cannot run cleanup."
            exit 1
        fi
        bash "$XIOSK_INSTALL_DIR/scripts/setup/cleanup.sh" "$@"
        ;;
    --backup)
        if [ ! -f "$XIOSK_INSTALL_DIR/scripts/setup/backup.sh" ]; then
            msg "$ERROR" "XiOSK is not installed. Cannot run backup."
            exit 1
        fi
        bash "$XIOSK_INSTALL_DIR/scripts/setup/backup.sh" "$@"
        ;;
    *)
        msg "$ERROR" "Invalid command: $COMMAND"
        show_help
        exit 1
        ;;
esac

