#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh — Master install script for the Magoradesk APK Build Panel
# Run as root on a fresh Ubuntu/Debian VPS.
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 1. Root check
# ---------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo or log in as root)." >&2
    exit 1
fi

echo "======================================================"
echo " Magoradesk APK Build Panel — Master Installer"
echo "======================================================"
echo ""

# ---------------------------------------------------------------------------
# 2. Run setup.sh (installs dependencies, SDK, nginx, etc.)
# ---------------------------------------------------------------------------
echo "==> Step 1/4: Running setup.sh..."
bash "${SCRIPT_DIR}/setup.sh"

# ---------------------------------------------------------------------------
# 3. First build
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 2/4: Running first build..."
bash "${SCRIPT_DIR}/build.sh" || {
    echo "WARNING: First build failed. You can retry later with:"
    echo "  bash ${SCRIPT_DIR}/build.sh"
}

# ---------------------------------------------------------------------------
# 4. Install systemd service
# ---------------------------------------------------------------------------
echo ""
echo "==> Step 3/4: Installing systemd service..."
cp "${SCRIPT_DIR}/magoradesk-panel.service" /etc/systemd/system/magoradesk-panel.service
systemctl daemon-reload
systemctl enable --now magoradesk-panel.service
echo "==> Service 'magoradesk-panel' enabled and started."

# ---------------------------------------------------------------------------
# 5. Summary
# ---------------------------------------------------------------------------
SERVER_IP="$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "<your-server-ip>")"

echo ""
echo "======================================================"
echo " Installation complete!"
echo "======================================================"
echo ""
echo " Access the build panel at:"
echo "   http://${SERVER_IP}:8080"
echo ""
echo " Useful commands:"
echo "   systemctl status magoradesk-panel   # check service status"
echo "   journalctl -u magoradesk-panel -f   # follow service logs"
echo "   bash ${SCRIPT_DIR}/build.sh         # trigger a build manually"
echo "======================================================"
