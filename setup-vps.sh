#!/usr/bin/env bash
# setup-vps.sh — Full VPS setup on Ubuntu 22.04/24.04:
#   1. Install JDK 17, Android SDK, Gradle wrapper, nginx, Tor
#   2. Build the Magoradesk debug APK
#   3. Serve the APK via nginx behind a Tor hidden service (.onion)
#
# Usage:  sudo bash setup-vps.sh
# Re-run: safe (idempotent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVE_DIR="/var/www/apk-panel"
BUILDS_DIR="$SERVE_DIR/builds"
NGINX_CONF="/etc/nginx/sites-available/apk-panel"
ANDROID_SDK_ROOT="/opt/android-sdk"
CMDLINE_TOOLS_VERSION="9477386"
JAVA_HOME_PATH="/usr/lib/jvm/java-17-openjdk-amd64"
GRADLE_WRAPPER_JAR="$REPO_DIR/gradle/wrapper/gradle-wrapper.jar"
GRADLE_WRAPPER_JAR_URL="https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
HS_DIR="/var/lib/tor/hidden_service"

echo "========================================"
echo "  Magoradesk VPS Setup"
echo "  Hidden-service build pipeline"
echo "========================================"

# ── 1. System packages ────────────────────────────────────────────────────────
echo "[1/11] Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
    openjdk-17-jdk \
    wget \
    curl \
    unzip \
    git \
    nginx \
    tor \
    ca-certificates

# ── 2. Java ───────────────────────────────────────────────────────────────────
echo "[2/11] Configuring Java..."
update-alternatives --set java "$JAVA_HOME_PATH/bin/java" 2>/dev/null || true
export JAVA_HOME="$JAVA_HOME_PATH"
export PATH="$JAVA_HOME/bin:$PATH"
java -version

# ── 3. Android SDK ────────────────────────────────────────────────────────────
echo "[3/11] Installing Android SDK command-line tools..."
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

# ── 4. SDK licenses and components ────────────────────────────────────────────
echo "[4/11] Accepting licenses, installing platform/build-tools..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "platform-tools" \
    2>&1 | grep -v "^$" || true

# ── 5. Project configuration ──────────────────────────────────────────────────
echo "[5/11] Writing local.properties and persisting env vars..."

cat > "$REPO_DIR/local.properties" <<EOF
sdk.dir=$ANDROID_SDK_ROOT
EOF

ENV_FILE="/etc/profile.d/android-sdk.sh"
cat > "$ENV_FILE" <<EOF
export JAVA_HOME="$JAVA_HOME_PATH"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
EOF
chmod +x "$ENV_FILE"

# ── 6. Gradle wrapper jar ─────────────────────────────────────────────────────
echo "[6/11] Downloading gradle-wrapper.jar..."
mkdir -p "$REPO_DIR/gradle/wrapper"
if [ ! -f "$GRADLE_WRAPPER_JAR" ]; then
    wget -q -O "$GRADLE_WRAPPER_JAR" "$GRADLE_WRAPPER_JAR_URL" || {
        echo "  Primary URL failed, trying backup..."
        wget -q -O "$GRADLE_WRAPPER_JAR" \
            "https://github.com/gradle/gradle/raw/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
    }
fi
[ -f "$REPO_DIR/gradlew" ] && chmod +x "$REPO_DIR/gradlew"

# ── 7. Build APK ──────────────────────────────────────────────────────────────
echo "[7/11] Building debug APK..."
cd "$REPO_DIR"
if [ -f "$REPO_DIR/gradlew" ]; then
    ./gradlew assembleDebug --no-daemon --stacktrace 2>&1 | tail -30
else
    echo "  WARNING: gradlew not present — skipping build."
    echo "  The hidden service will still be created; add the app"
    echo "  source and re-run build-and-serve.sh later."
fi

APK_SRC=$(find "$REPO_DIR" -path "*/apk/debug/*.apk" 2>/dev/null | head -1)
mkdir -p "$BUILDS_DIR"

if [ -n "$APK_SRC" ]; then
    APK_FILENAME="magoradesk-debug-$(date +%Y%m%d-%H%M%S).apk"
    cp "$APK_SRC" "$BUILDS_DIR/$APK_FILENAME"
    echo "  APK: $BUILDS_DIR/$APK_FILENAME"
else
    echo "  No APK found (app source may not be present yet)."
fi

# ── 8. Nginx ──────────────────────────────────────────────────────────────────
echo "[8/11] Configuring nginx..."
mkdir -p "$SERVE_DIR"

# Install nginx config from template
if [ -f "$REPO_DIR/nginx/nginx-hidden-service.conf" ]; then
    cp "$REPO_DIR/nginx/nginx-hidden-service.conf" "$NGINX_CONF"
    sed -i "s|__SERVE_DIR__|$SERVE_DIR|g" "$NGINX_CONF"
else
    # Fallback inline config
    cat > "$NGINX_CONF" <<NGINX
server {
    listen 127.0.0.1:80;
    server_name localhost;
    root $SERVE_DIR;
    index index.html;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    location /builds/ {
        alias $SERVE_DIR/builds/;
        autoindex on;
        types { application/vnd.android.package-archive apk; }
        add_header Content-Disposition 'attachment' always;
    }
    location / { try_files \$uri \$uri/ =404; }
    location ~ /\\. { deny all; }
}
NGINX
fi

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/apk-panel 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Generate index page
"$REPO_DIR/build-and-serve.sh" --skip-build 2>/dev/null || {
    # If build-and-serve.sh is not ready, use the template
    cp "$REPO_DIR/nginx/index.html" "$SERVE_DIR/index.html" 2>/dev/null || true
}

nginx -t && systemctl enable nginx && systemctl restart nginx
echo "  nginx ready (listening on 127.0.0.1:80)."

# ── 9. Tor hidden service ─────────────────────────────────────────────────────
echo "[9/11] Setting up Tor hidden service..."
mkdir -p "$HS_DIR"
chown debian-tor:debian-tor "$HS_DIR"
chmod 700 "$HS_DIR"

TORRC="/etc/tor/torrc"

# Remove any previous block we wrote
if grep -q "# --- Magoradesk hidden service ---" "$TORRC" 2>/dev/null; then
    sed -i '/# --- Magoradesk hidden service ---/,/# --- End Magoradesk ---/d' "$TORRC"
fi

cat >> "$TORRC" <<EOF
# --- Magoradesk hidden service ---
HiddenServiceDir $HS_DIR
HiddenServicePort 80 127.0.0.1:80
# --- End Magoradesk ---
EOF

# ── 10. Start Tor ─────────────────────────────────────────────────────────────
echo "[10/11] Starting Tor..."
systemctl enable tor
systemctl restart tor

echo "  Waiting for .onion address..."
TRIES=0
MAX_TRIES=30
while [ ! -f "$HS_DIR/hostname" ] && [ "$TRIES" -lt "$MAX_TRIES" ]; do
    sleep 2
    TRIES=$((TRIES + 1))
done

# ── 11. Summary ───────────────────────────────────────────────────────────────
echo ""
echo "[11/11] Setup complete!"
echo "========================================"

if [ -f "$HS_DIR/hostname" ]; then
    ONION_ADDR=$(cat "$HS_DIR/hostname")
    echo "  🧅 Hidden service : http://$ONION_ADDR"
else
    echo "  ⚠  Tor started but hostname file not yet created."
    echo "     Check: journalctl -u tor"
fi

echo "  ℹ️  nginx listens on 127.0.0.1:80 (Tor-only by default)."
echo "     To also expose publicly, change 'listen 127.0.0.1:80' to"
echo "     'listen 80' in $NGINX_CONF and reload nginx."

if [ -n "${APK_FILENAME:-}" ]; then
    echo "  📱 Latest APK      : $BUILDS_DIR/$APK_FILENAME"
else
    echo "  📱 No APK yet — add app source and run build-and-serve.sh"
fi

echo ""
echo "  Rebuild:  sudo bash build-and-serve.sh"
echo "  Cron:     0 */6 * * * $(cd "$REPO_DIR" && pwd)/build-and-serve.sh"
echo "========================================"
