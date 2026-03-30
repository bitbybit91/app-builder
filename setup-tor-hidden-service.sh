#!/usr/bin/env bash
# setup-tor-hidden-service.sh — Install Tor and expose a local service as a
# .onion hidden service.  Idempotent: safe to re-run.
#
# Usage:
#   sudo bash setup-tor-hidden-service.sh [--port 80] [--hs-dir /var/lib/tor/hidden_service]
#
# After the script finishes the .onion address is printed to stdout and
# written to <hs-dir>/hostname.
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
HS_PORT="${HS_PORT:-80}"
HS_DIR="${HS_DIR:-/var/lib/tor/hidden_service}"

# ── Parse CLI args ────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)  HS_PORT="$2"; shift 2 ;;
        --hs-dir) HS_DIR="$2"; shift 2 ;;
        *)       echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo "========================================"
echo "  Tor Hidden Service Setup"
echo "  Port : $HS_PORT"
echo "  Dir  : $HS_DIR"
echo "========================================"

# ── 1. Install Tor ────────────────────────────────────────────────────────────
echo "[1/4] Installing Tor..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq tor

# ── 2. Configure Tor ──────────────────────────────────────────────────────────
echo "[2/4] Configuring Tor hidden service..."
mkdir -p "$HS_DIR"
chown debian-tor:debian-tor "$HS_DIR"
chmod 700 "$HS_DIR"

TORRC="/etc/tor/torrc"

# Remove any previous hidden-service block we wrote
if grep -q "# --- Magoradesk hidden service ---" "$TORRC" 2>/dev/null; then
    sed -i '/# --- Magoradesk hidden service ---/,/# --- End Magoradesk ---/d' "$TORRC"
fi

cat >> "$TORRC" <<EOF
# --- Magoradesk hidden service ---
HiddenServiceDir $HS_DIR
HiddenServicePort $HS_PORT 127.0.0.1:80
# --- End Magoradesk ---
EOF

echo "  torrc updated."

# ── 3. Restart Tor ────────────────────────────────────────────────────────────
echo "[3/4] Restarting Tor daemon..."
systemctl enable tor
systemctl restart tor

# ── 4. Wait for hostname file ─────────────────────────────────────────────────
echo "[4/4] Waiting for .onion address..."
TRIES=0
MAX_TRIES=30
while [ ! -f "$HS_DIR/hostname" ] && [ "$TRIES" -lt "$MAX_TRIES" ]; do
    sleep 2
    TRIES=$((TRIES + 1))
done

if [ -f "$HS_DIR/hostname" ]; then
    ONION_ADDR=$(cat "$HS_DIR/hostname")
    echo ""
    echo "========================================"
    echo "  Hidden service is live!"
    echo "  Address: $ONION_ADDR"
    echo "  Port   : $HS_PORT"
    echo "========================================"
else
    echo ""
    echo "WARNING: Tor started but $HS_DIR/hostname was not created"
    echo "         within $((MAX_TRIES * 2))s. Check: journalctl -u tor"
    exit 1
fi
