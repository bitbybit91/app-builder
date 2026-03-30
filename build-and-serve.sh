#!/usr/bin/env bash
# build-and-serve.sh — Rebuild APK and update the nginx download panel.
# Run manually or via cron: 0 */6 * * * /path/to/build-and-serve.sh >> /var/log/build-and-serve.log 2>&1
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="/var/www/apk-panel"
BUILDS_DIR="$SERVE_DIR/builds"
ANDROID_SDK_ROOT="/opt/android-sdk"
JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
KEYSTORE_PATH="${KEYSTORE_PATH:-}"
MAX_BUILDS=10  # keep last N builds

export JAVA_HOME="$JAVA_HOME_PATH"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "========================================"
echo "  Magoradesk — Build & Serve  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# ── 1. Pull latest code ───────────────────────────────────────────────────────
echo "[1/4] Pulling latest code..."
cd "$REPO_DIR"
git fetch origin
git pull --rebase origin "$(git rev-parse --abbrev-ref HEAD)" || {
    echo "  Warning: git pull failed (local changes?). Continuing with current code."
}
CURRENT_SHA=$(git rev-parse --short HEAD)
echo "  Commit: $CURRENT_SHA"

# ── 2. Gradle build ───────────────────────────────────────────────────────────
echo "[2/4] Building APK..."
mkdir -p "$BUILDS_DIR"

# Ensure gradle-wrapper.jar exists
if [ ! -f "$REPO_DIR/gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "  Downloading gradle-wrapper.jar..."
    wget -q -O "$REPO_DIR/gradle/wrapper/gradle-wrapper.jar" \
        "https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
fi

chmod +x "$REPO_DIR/gradlew"

# Debug build (always)
echo "  Building debug..."
./gradlew assembleDebug --no-daemon 2>&1 | tail -10

DEBUG_APK=$(find "$REPO_DIR/app/build/outputs/apk/debug" -name "*.apk" | head -1)
if [ -z "$DEBUG_APK" ]; then
    echo "ERROR: Debug APK not found!"
    exit 1
fi

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
DEBUG_DEST="$BUILDS_DIR/magoradesk-debug-${TIMESTAMP}-${CURRENT_SHA}.apk"
cp "$DEBUG_APK" "$DEBUG_DEST"
echo "  Debug APK: $DEBUG_DEST"

# Release build (only if keystore is configured)
RELEASE_DEST=""
if [ -n "$KEYSTORE_PATH" ] && [ -f "$KEYSTORE_PATH" ]; then
    echo "  Building release (signed)..."
    ./gradlew assembleRelease --no-daemon 2>&1 | tail -10
    RELEASE_APK=$(find "$REPO_DIR/app/build/outputs/apk/release" -name "*.apk" | head -1)
    if [ -n "$RELEASE_APK" ]; then
        RELEASE_DEST="$BUILDS_DIR/magoradesk-release-${TIMESTAMP}-${CURRENT_SHA}.apk"
        cp "$RELEASE_APK" "$RELEASE_DEST"
        echo "  Release APK: $RELEASE_DEST"
    fi
else
    echo "  Skipping release build (KEYSTORE_PATH not set or file missing)."
fi

# ── 3. Prune old builds ───────────────────────────────────────────────────────
echo "[3/4] Pruning old builds (keep last $MAX_BUILDS)..."
ls -1t "$BUILDS_DIR"/*.apk 2>/dev/null | tail -n +$((MAX_BUILDS + 1)) | xargs rm -f --

# ── 4. Regenerate HTML panel ──────────────────────────────────────────────────
echo "[4/4] Updating download panel..."
mkdir -p "$SERVE_DIR"

BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')
DEBUG_SIZE=$(du -sh "$DEBUG_DEST" | cut -f1)
LATEST_APK_NAME=$(basename "$DEBUG_DEST")

cat > "$SERVE_DIR/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="refresh" content="300">
<title>Magoradesk — APK Download Panel</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 1rem; }
  .card { background: #1e293b; border-radius: 1rem; padding: 2rem; max-width: 520px; width: 100%; box-shadow: 0 25px 50px rgba(0,0,0,0.5); }
  h1 { font-size: 1.75rem; font-weight: 700; color: #f8fafc; margin-bottom: 0.25rem; }
  .subtitle { color: #94a3b8; margin-bottom: 1.5rem; font-size: 0.95rem; }
  .badge { display: inline-block; background: #1d4ed8; color: #bfdbfe; font-size: 0.75rem; font-weight: 600; padding: 0.25rem 0.75rem; border-radius: 9999px; margin-bottom: 1.5rem; text-transform: uppercase; letter-spacing: 0.05em; }
  .meta { background: #0f172a; border-radius: 0.5rem; padding: 1rem; display: grid; gap: 0.5rem; margin-bottom: 1.5rem; }
  .meta-row { display: flex; justify-content: space-between; font-size: 0.875rem; }
  .meta-label { color: #64748b; }
  .meta-value { color: #cbd5e1; font-weight: 500; }
  .download-btn { display: block; text-align: center; background: linear-gradient(135deg, #3b82f6, #1d4ed8); color: #fff; text-decoration: none; font-size: 1.1rem; font-weight: 700; padding: 0.9rem 2rem; border-radius: 0.75rem; margin-bottom: 1rem; }
  .download-btn:hover { opacity: 0.9; }
  .builds-section { margin-top: 1.5rem; }
  .builds-section h2 { font-size: 0.8rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.75rem; }
  .build-item { background: #0f172a; border-radius: 0.5rem; padding: 0.75rem 1rem; margin-bottom: 0.5rem; display: flex; justify-content: space-between; align-items: center; gap: 0.5rem; }
  .build-name { font-size: 0.8rem; color: #94a3b8; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex: 1; }
  .build-dl { font-size: 0.8rem; color: #60a5fa; text-decoration: none; white-space: nowrap; }
  .footer { margin-top: 1.5rem; text-align: center; font-size: 0.75rem; color: #334155; }
  .footer a { color: #475569; }
</style>
</head>
<body>
<div class="card">
  <div style="font-size:2rem">📱</div>
  <h1>Magoradesk</h1>
  <p class="subtitle">P2P Cryptocurrency Trading App</p>
  <span class="badge">Debug Build</span>
  <div class="meta">
    <div class="meta-row"><span class="meta-label">Built</span><span class="meta-value">$BUILD_DATE</span></div>
    <div class="meta-row"><span class="meta-label">Commit</span><span class="meta-value">$CURRENT_SHA</span></div>
    <div class="meta-row"><span class="meta-label">Size</span><span class="meta-value">$DEBUG_SIZE</span></div>
    <div class="meta-row"><span class="meta-label">Min Android</span><span class="meta-value">7.0 (API 24+)</span></div>
  </div>
  <a class="download-btn" href="/builds/$LATEST_APK_NAME" download>⬇ Download Latest APK</a>
  <div class="builds-section">
    <h2>All Builds</h2>
HTML

for apk_file in $(ls -1t "$BUILDS_DIR"/*.apk 2>/dev/null); do
    fname=$(basename "$apk_file")
    fsize=$(du -sh "$apk_file" | cut -f1)
    echo "    <div class=\"build-item\"><span class=\"build-name\">$fname ($fsize)</span><a class=\"build-dl\" href=\"/builds/$fname\" download>⬇</a></div>" >> "$SERVE_DIR/index.html"
done

cat >> "$SERVE_DIR/index.html" <<HTML
  </div>
  <div class="footer">Auto-updated by build-and-serve.sh · <a href="https://github.com/bitbybit91/app-builder">Source</a></div>
</div>
</body>
</html>
HTML

echo ""
echo "Done! Panel updated: http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo "Latest APK: /builds/$LATEST_APK_NAME"
