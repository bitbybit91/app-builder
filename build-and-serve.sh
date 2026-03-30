#!/usr/bin/env bash
# build-and-serve.sh — Rebuild APK(s) and refresh the nginx download panel.
#
# Usage:
#   sudo bash build-and-serve.sh              # full rebuild
#   sudo bash build-and-serve.sh --skip-build # regenerate HTML only
#
# Cron example (every 6 hours):
#   0 */6 * * * /opt/app-builder/build-and-serve.sh >> /var/log/build-and-serve.log 2>&1
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="/var/www/apk-panel"
BUILDS_DIR="$SERVE_DIR/builds"
ANDROID_SDK_ROOT="/opt/android-sdk"
JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
HS_DIR="/var/lib/tor/hidden_service"
KEYSTORE_PATH="${KEYSTORE_PATH:-}"
MAX_BUILDS=10
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

export JAVA_HOME="$JAVA_HOME_PATH"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "========================================"
echo "  Magoradesk — Build & Serve  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

mkdir -p "$BUILDS_DIR"

# ── 1. Pull latest code ───────────────────────────────────────────────────────
if [ "$SKIP_BUILD" = false ]; then
    echo "[1/4] Pulling latest code..."
    cd "$REPO_DIR"
    git fetch origin 2>/dev/null || true
    git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || {
        echo "  Warning: git pull failed. Continuing with current code."
    }
fi

CURRENT_SHA=$(cd "$REPO_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# ── 2. Build APK ──────────────────────────────────────────────────────────────
DEBUG_DEST=""
RELEASE_DEST=""
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

if [ "$SKIP_BUILD" = false ] && [ -f "$REPO_DIR/gradlew" ]; then
    echo "[2/4] Building APK..."

    # Ensure gradle-wrapper.jar exists
    if [ ! -f "$REPO_DIR/gradle/wrapper/gradle-wrapper.jar" ]; then
        echo "  Downloading gradle-wrapper.jar..."
        mkdir -p "$REPO_DIR/gradle/wrapper"
        wget -q -O "$REPO_DIR/gradle/wrapper/gradle-wrapper.jar" \
            "https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
    fi
    chmod +x "$REPO_DIR/gradlew"

    # Debug build
    echo "  Building debug..."
    ./gradlew assembleDebug --no-daemon 2>&1 | tail -10

    DEBUG_APK=$(find "$REPO_DIR" -path "*/apk/debug/*.apk" 2>/dev/null | head -1)
    if [ -n "$DEBUG_APK" ]; then
        DEBUG_DEST="$BUILDS_DIR/magoradesk-debug-${TIMESTAMP}-${CURRENT_SHA}.apk"
        cp "$DEBUG_APK" "$DEBUG_DEST"
        echo "  Debug APK: $DEBUG_DEST"
    fi

    # Release build (only if keystore configured)
    if [ -n "$KEYSTORE_PATH" ] && [ -f "$KEYSTORE_PATH" ]; then
        echo "  Building release (signed)..."
        ./gradlew assembleRelease --no-daemon 2>&1 | tail -10
        RELEASE_APK=$(find "$REPO_DIR" -path "*/apk/release/*.apk" 2>/dev/null | head -1)
        if [ -n "$RELEASE_APK" ]; then
            RELEASE_DEST="$BUILDS_DIR/magoradesk-release-${TIMESTAMP}-${CURRENT_SHA}.apk"
            cp "$RELEASE_APK" "$RELEASE_DEST"
            echo "  Release APK: $RELEASE_DEST"
        fi
    fi
else
    if [ "$SKIP_BUILD" = false ]; then
        echo "[2/4] Skipping build (gradlew not found)."
    else
        echo "[2/4] Skipping build (--skip-build)."
    fi
fi

# ── 3. Prune old builds ───────────────────────────────────────────────────────
echo "[3/4] Pruning old builds (keep last $MAX_BUILDS)..."
find "$BUILDS_DIR" -maxdepth 1 -name '*.apk' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | tail -n +$((MAX_BUILDS + 1)) | cut -d' ' -f2- \
    | xargs rm -f -- 2>/dev/null || true

# ── 4. Regenerate HTML panel ──────────────────────────────────────────────────
echo "[4/4] Updating download panel..."
mkdir -p "$SERVE_DIR"

BUILD_DATE=$(TZ=UTC date '+%Y-%m-%d %H:%M:%S %Z')
LATEST_APK=$(find "$BUILDS_DIR" -maxdepth 1 -name '*.apk' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)

if [ -n "$LATEST_APK" ]; then
    LATEST_APK_NAME=$(basename "$LATEST_APK")
    LATEST_APK_SIZE=$(du -sh "$LATEST_APK" | cut -f1)
    DOWNLOAD_HREF="/builds/$LATEST_APK_NAME"
else
    LATEST_APK_NAME="(none)"
    LATEST_APK_SIZE="—"
    DOWNLOAD_HREF="/builds/"
fi

# Determine .onion address if available
ONION_LINE=""
if [ -f "$HS_DIR/hostname" ]; then
    ONION_ADDR=$(cat "$HS_DIR/hostname")
    ONION_LINE="<div class=\"meta-row\"><span class=\"meta-label\">Onion</span><span class=\"meta-value\" style=\"font-size:.7rem;word-break:break-all\">$ONION_ADDR</span></div>"
fi

cat > "$SERVE_DIR/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="300">
<title>Magoradesk &mdash; APK Download</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:1rem}
  .card{background:#1e293b;border-radius:1rem;padding:2rem;max-width:520px;width:100%;box-shadow:0 25px 50px rgba(0,0,0,.5)}
  h1{font-size:1.75rem;font-weight:700;color:#f8fafc;margin-bottom:.25rem}
  .subtitle{color:#94a3b8;margin-bottom:1.5rem;font-size:.95rem}
  .badge{display:inline-block;font-size:.75rem;font-weight:600;padding:.25rem .75rem;border-radius:9999px;margin-bottom:1.5rem;text-transform:uppercase;letter-spacing:.05em}
  .badge.onion{background:#6b21a8;color:#e9d5ff}
  .meta{background:#0f172a;border-radius:.5rem;padding:1rem;display:grid;gap:.5rem;margin-bottom:1.5rem}
  .meta-row{display:flex;justify-content:space-between;font-size:.875rem}
  .meta-label{color:#64748b}
  .meta-value{color:#cbd5e1;font-weight:500}
  .download-btn{display:block;text-align:center;background:linear-gradient(135deg,#3b82f6,#1d4ed8);color:#fff;text-decoration:none;font-size:1.1rem;font-weight:700;padding:.9rem 2rem;border-radius:.75rem;margin-bottom:1rem}
  .download-btn:hover{opacity:.9}
  .builds-section{margin-top:1.5rem}
  .builds-section h2{font-size:.8rem;font-weight:600;color:#64748b;text-transform:uppercase;letter-spacing:.05em;margin-bottom:.75rem}
  .build-item{background:#0f172a;border-radius:.5rem;padding:.75rem 1rem;margin-bottom:.5rem;display:flex;justify-content:space-between;align-items:center;gap:.5rem}
  .build-name{font-size:.8rem;color:#94a3b8;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;flex:1}
  .build-dl{font-size:.8rem;color:#60a5fa;text-decoration:none;white-space:nowrap}
  .footer{margin-top:1.5rem;text-align:center;font-size:.75rem;color:#334155}
  .footer a{color:#475569}
  .refresh-note{font-size:.7rem;color:#334155;text-align:center;margin-top:.5rem}
</style>
</head>
<body>
<div class="card">
  <div style="font-size:2rem">📱</div>
  <h1>Magoradesk</h1>
  <p class="subtitle">P2P Cryptocurrency Trading App</p>
  <span class="badge onion">🧅 Tor Hidden Service</span>
  <div class="meta">
    <div class="meta-row"><span class="meta-label">Built</span><span class="meta-value">$BUILD_DATE</span></div>
    <div class="meta-row"><span class="meta-label">Commit</span><span class="meta-value">$CURRENT_SHA</span></div>
    <div class="meta-row"><span class="meta-label">Size</span><span class="meta-value">$LATEST_APK_SIZE</span></div>
    <div class="meta-row"><span class="meta-label">Min Android</span><span class="meta-value">7.0 (API 24+)</span></div>
    $ONION_LINE
  </div>
  <a class="download-btn" href="$DOWNLOAD_HREF" download>⬇ Download Latest APK</a>
  <div class="builds-section">
    <h2>All Builds</h2>
HTML

while IFS= read -r apk_file; do
    [ -z "$apk_file" ] && continue
    fname=$(basename "$apk_file")
    fsize=$(du -sh "$apk_file" | cut -f1)
    echo "    <div class=\"build-item\"><span class=\"build-name\">$fname ($fsize)</span><a class=\"build-dl\" href=\"/builds/$fname\" download>⬇</a></div>" >> "$SERVE_DIR/index.html"
done < <(find "$BUILDS_DIR" -maxdepth 1 -name '*.apk' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | cut -d' ' -f2-)

cat >> "$SERVE_DIR/index.html" <<HTML
  </div>
  <div class="footer">Auto-updated by build-and-serve.sh · <a href="https://github.com/bitbybit91/app-builder">Source</a></div>
  <p class="refresh-note">Page auto-refreshes every 5 minutes</p>
</div>
</body>
</html>
HTML

echo ""
echo "Done! Panel updated."
if [ -f "$HS_DIR/hostname" ]; then
    echo "  🧅 http://$(cat "$HS_DIR/hostname")"
fi
if [ -n "$LATEST_APK" ]; then
    echo "  📱 Latest: /builds/$LATEST_APK_NAME"
fi
