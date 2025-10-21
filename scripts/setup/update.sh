#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/common.sh"

msg "$CALLOUT" "--- Starting PiOSK Update ---"

PI_USER="${1:-$SUDO_USER}"

# The bootstrap script has already backed up and downloaded the new version.
# This script's job is to clean the old version and install the new one.

# Step 1: Clean up the old version.
msg "$INFO" "Step 1: Removing old version..."
# Source the old cleanup script if it exists for a clean removal.
if [ -f "$PIOSK_INSTALL_DIR/scripts/setup/cleanup.sh" ]; then
    bash "$PIOSK_INSTALL_DIR/scripts/setup/cleanup.sh"
else
    # Fallback for older versions or broken installs
    rm -rf "$PIOSK_INSTALL_DIR"
fi

# Step 2: Move the new version (this script's parent dir) into its final place.
msg "$INFO" "Step 2: Activating the new version..."
mv "$PIOSK_TEMP_DIR" "$PIOSK_INSTALL_DIR"

# Step 3: Run the new installation script to finalize setup.
msg "$INFO" "Step 3: Finalizing the new installation..."
bash "$PIOSK_INSTALL_DIR/scripts/setup/install.sh" "$PI_USER"

msg "$CALLOUT" "--- Update Complete ---"

