#!/bin/bash
###############################################################################
# Bootstrap Loader - Windows Server 2025 Hetzner Installer
#
# ONE-LINER FOR USERS:
#   wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash
#
# Or with custom password:
#   wget -qO- https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install.sh | bash -s -- --password "MyPass123"
#
# This bootstrap script:
#   1. Downloads the main installer to /root/
#   2. Makes it executable
#   3. Launches it with any arguments passed through
#
# The user only needs PuTTY SSH — no SCP, no file uploads.
###############################################################################

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Windows Server 2025 - Hetzner Automated Installer        ║"
echo "║   Bootstrap Loader                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Configuration ───────────────────────────────────────────────
# Installer source URL.
# Options:
#   - GitHub raw URL:  https://raw.githubusercontent.com/YOU/REPO/main/install-windows.sh
#   - Any direct URL:  https://your-domain.com/install-windows.sh
INSTALLER_URL="https://raw.githubusercontent.com/babai834/hetznerWindowsOSinstaller/main/install-windows.sh"
# ─────────────────────────────────────────────────────────────────

INSTALL_DIR="/root"
INSTALLER_PATH="${INSTALL_DIR}/install-windows.sh"

# Check we're root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root."
    exit 1
fi

echo -e "${GREEN}[1/3]${NC} Downloading installer..."
if command -v wget &>/dev/null; then
    wget -q --no-check-certificate -O "$INSTALLER_PATH" "$INSTALLER_URL"
elif command -v curl &>/dev/null; then
    curl -fsSL -k -o "$INSTALLER_PATH" "$INSTALLER_URL"
else
    echo -e "${RED}[ERROR]${NC} Neither wget nor curl found."
    exit 1
fi

if [ ! -s "$INSTALLER_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} Download failed or file is empty."
    exit 1
fi

echo -e "${GREEN}[2/3]${NC} Setting permissions..."
chmod +x "$INSTALLER_PATH"

echo -e "${GREEN}[3/3]${NC} Launching installer..."
echo ""

# Pass through any command-line arguments
exec bash "$INSTALLER_PATH" "$@"
