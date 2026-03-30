#!/usr/bin/env bash
# setup-vps.sh — Full VPS setup: Install Android SDK, build APK, serve via nginx
# Tested on Ubuntu 22.04 / 24.04 (fresh install).
# Usage: bash setup-vps.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="/var/www/apk-panel"
BUILDS_DIR="$SERVE_DIR/builds"
NGINX_CONF="/etc/nginx/sites-available/apk-panel"
ANDROID_SDK_ROOT="/opt/android-sdk"
CMDLINE_TOOLS_VERSION="9477386"  # commandlinetools-linux-9477386_latest.zip (stable)
JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
GRADLE_WRAPPER_JAR="$REPO_DIR/gradle/wrapper/gradle-wrapper.jar"
GRADLE_WRAPPER_JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar"

echo "========================================"
echo "  Magoradesk APK Builder — VPS Setup"
echo "========================================"

# ── 1. System packages ────────────────────────────────────────────────────────
echo "[1/9] Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    openjdk-17-jdk \
    wget \
    curl \
    unzip \
    git \
    nginx \
    ca-certificates

# ── 2. Java environment ───────────────────────────────────────────────────────
echo "[2/9] Configuring Java..."
update-alternatives --set java "$JAVA_HOME_PATH/bin/java" 2>/dev/null || true
export JAVA_HOME="$JAVA_HOME_PATH"
export PATH="$JAVA_HOME/bin:$PATH"
java -version

# ── 3. Android SDK ────────────────────────────────────────────────────────────
echo "[3/9] Installing Android SDK command-line tools..."
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

CMDLINE_ZIP="/tmp/commandlinetools-linux.zip"
if [ ! -f "$CMDLINE_ZIP" ]; then
    wget -q -O "$CMDLINE_ZIP" \
        "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
fi

if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools/latest" ]; then
    unzip -q "$CMDLINE_ZIP" -d /tmp/cmdline-tools-extract
    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    mv /tmp/cmdline-tools-extract/cmdline-tools/* "$ANDROID_SDK_ROOT/cmdline-tools/latest/"
    rm -rf /tmp/cmdline-tools-extract
fi

export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# ── 4. Accept licenses and install SDK components ─────────────────────────────
echo "[4/9] Accepting Android SDK licenses and installing platform/build-tools..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "platform-tools" \
    2>&1 | grep -v "^$" || true

# ── 5. Project configuration ──────────────────────────────────────────────────
echo "[5/9] Configuring project..."

# local.properties
cat > "$REPO_DIR/local.properties" <<EOF
sdk.dir=$ANDROID_SDK_ROOT
EOF

# Persist environment variables for future sessions
ENV_FILE="/etc/profile.d/android-sdk.sh"
cat > "$ENV_FILE" <<EOF
export JAVA_HOME="$JAVA_HOME_PATH"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF
chmod +x "$ENV_FILE"

# ── 6. Gradle wrapper jar ─────────────────────────────────────────────────────
echo "[6/9] Downloading gradle-wrapper.jar..."
mkdir -p "$REPO_DIR/gradle/wrapper"
if [ ! -f "$GRADLE_WRAPPER_JAR" ]; then
    wget -q -O "$GRADLE_WRAPPER_JAR" "$GRADLE_WRAPPER_JAR_URL" || {
        echo "  Primary URL failed, trying backup..."
        wget -q -O "$GRADLE_WRAPPER_JAR" \
            "https://github.com/gradle/gradle/raw/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
    }
fi
chmod +x "$REPO_DIR/gradlew"

# ── 7. Build APK ──────────────────────────────────────────────────────────────
echo "[7/9] Building debug APK..."
cd "$REPO_DIR"
./gradlew assembleDebug --no-daemon --stacktrace 2>&1 | tail -30

APK_SRC=$(find "$REPO_DIR/app/build/outputs/apk/debug" -name "*.apk" | head -1)
if [ -z "$APK_SRC" ]; then
    echo "ERROR: APK not found after build!"
    exit 1
fi
echo "  APK built: $APK_SRC"

# ── 8. Set up nginx serving directory ─────────────────────────────────────────
echo "[8/9] Setting up download panel..."
mkdir -p "$BUILDS_DIR"

APK_FILENAME="magoradesk-debug-$(date +%Y%m%d-%H%M%S).apk"
cp "$APK_SRC" "$BUILDS_DIR/$APK_FILENAME"

# Copy nginx config files from repo
if [ -f "$REPO_DIR/nginx/nginx-app-builder.conf" ]; then
    cp "$REPO_DIR/nginx/nginx-app-builder.conf" "$NGINX_CONF"
    # Replace placeholder with actual path
    sed -i "s|__SERVE_DIR__|$SERVE_DIR|g" "$NGINX_CONF"
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/apk-panel 2>/dev/null || true
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
fi

# Generate index.html
BUILD_DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')
APK_SIZE=$(du -sh "$BUILDS_DIR/$APK_FILENAME" | cut -f1)

cat > "$SERVE_DIR/index.html" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Magoradesk — APK Download Panel</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 1rem; }
  .card { background: #1e293b; border-radius: 1rem; padding: 2rem; max-width: 480px; width: 100%; box-shadow: 0 25px 50px rgba(0,0,0,0.5); }
  h1 { font-size: 1.75rem; font-weight: 700; color: #f8fafc; margin-bottom: 0.25rem; }
  .subtitle { color: #94a3b8; margin-bottom: 1.5rem; font-size: 0.95rem; }
  .badge { display: inline-block; background: #1d4ed8; color: #bfdbfe; font-size: 0.75rem; font-weight: 600; padding: 0.25rem 0.75rem; border-radius: 9999px; margin-bottom: 1.5rem; text-transform: uppercase; letter-spacing: 0.05em; }
  .meta { display: grid; gap: 0.5rem; margin-bottom: 1.5rem; }
  .meta-row { display: flex; justify-content: space-between; font-size: 0.875rem; }
  .meta-label { color: #64748b; }
  .meta-value { color: #cbd5e1; font-weight: 500; }
  .download-btn { display: block; text-align: center; background: linear-gradient(135deg, #3b82f6, #1d4ed8); color: #fff; text-decoration: none; font-size: 1.1rem; font-weight: 700; padding: 0.9rem 2rem; border-radius: 0.75rem; transition: opacity 0.2s; }
  .download-btn:hover { opacity: 0.9; }
  .footer { margin-top: 1.5rem; text-align: center; font-size: 0.8rem; color: #475569; }
  .builds-list { margin-top: 1.5rem; }
  .builds-list h2 { font-size: 0.9rem; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.75rem; }
  .build-item { background: #0f172a; border-radius: 0.5rem; padding: 0.75rem 1rem; margin-bottom: 0.5rem; display: flex; justify-content: space-between; align-items: center; }
  .build-name { font-size: 0.8rem; color: #94a3b8; word-break: break-all; }
  .build-link { font-size: 0.8rem; color: #60a5fa; text-decoration: none; white-space: nowrap; margin-left: 0.5rem; }
</style>
</head>
<body>
<div class="card">
  <h1>Magoradesk</h1>
  <p class="subtitle">P2P Cryptocurrency Trading App</p>
  <span class="badge">Debug Build</span>
  <div class="meta">
    <div class="meta-row"><span class="meta-label">Built</span><span class="meta-value">$BUILD_DATE</span></div>
    <div class="meta-row"><span class="meta-label">Size</span><span class="meta-value">$APK_SIZE</span></div>
    <div class="meta-row"><span class="meta-label">Type</span><span class="meta-value">Debug APK</span></div>
    <div class="meta-row"><span class="meta-label">Min Android</span><span class="meta-value">7.0 (API 24+)</span></div>
  </div>
  <a class="download-btn" href="/builds/$APK_FILENAME" download>⬇ Download APK</a>
  <div class="builds-list">
    <h2>All Builds</h2>
HTML

# List all APKs
for apk_file in "$BUILDS_DIR"/*.apk; do
    [ -f "$apk_file" ] || continue
    fname=$(basename "$apk_file")
    fsize=$(du -sh "$apk_file" | cut -f1)
    echo "    <div class=\"build-item\"><span class=\"build-name\">$fname ($fsize)</span><a class=\"build-link\" href=\"/builds/$fname\" download>Download</a></div>" >> "$SERVE_DIR/index.html"
done

cat >> "$SERVE_DIR/index.html" <<HTML
  </div>
  <div class="footer">Auto-updated by build-and-serve.sh · <a href="https://github.com/bitbybit91/app-builder" style="color:#475569">Source</a></div>
</div>
</body>
</html>
HTML

# ── 9. Start nginx ────────────────────────────────────────────────────────────
echo "[9/9] Starting nginx..."
nginx -t && systemctl enable nginx && systemctl restart nginx

echo ""
echo "========================================"
echo "  Setup complete!"
echo "  Panel: http://$(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VPS_IP')"
echo "  APK:   $BUILDS_DIR/$APK_FILENAME"
echo "========================================"
