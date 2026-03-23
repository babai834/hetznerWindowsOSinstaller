#!/bin/bash
###############################################################################
# Quick Start Launcher - Windows Server 2025 on Hetzner
# 
# Pre-configured for server: 37.27.49.125
# Run this on the Hetzner rescue system to begin installation.
#
# Usage: bash quick-start.sh
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install-windows.sh"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║    Quick Start - Windows Server 2025 Hetzner Installer      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if installer exists
if [ ! -f "$INSTALLER" ]; then
    echo "[ERROR] install-windows.sh not found in $SCRIPT_DIR"
    exit 1
fi

chmod +x "$INSTALLER"

# Pre-configured settings for this server
SERVER_IP="37.27.49.125"

# Let the user choose or accept defaults
echo "Server IP detected from config: $SERVER_IP"
echo ""
read -rp "Administrator password (leave empty for auto-generated): " ADMIN_PASS
echo ""

# Build command as an array to safely handle special characters in arguments
cmd_args=("bash" "$INSTALLER" "--ip" "$SERVER_IP")

if [ -n "${ADMIN_PASS:-}" ]; then
    cmd_args+=("--password" "$ADMIN_PASS")
fi

echo "Running: bash $INSTALLER --ip $SERVER_IP${ADMIN_PASS:+ --password ***}"
echo ""

# Execute
"${cmd_args[@]}"
