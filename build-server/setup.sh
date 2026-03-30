#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# setup.sh — Prepare a fresh Ubuntu/Debian VPS for building Magoradesk APKs
# ---------------------------------------------------------------------------

ANDROID_SDK_DIR=/opt/android-sdk
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
CMDLINE_TOOLS_ZIP="/tmp/commandlinetools-linux.zip"
GRADLE_VERSION="8.5"
GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
GRADLE_ZIP="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# 1. OS check
# ---------------------------------------------------------------------------
if [ ! -f /etc/debian_version ]; then
    echo "ERROR: This script requires Ubuntu or Debian. Exiting." >&2
    exit 1
fi

echo "==> Detected Debian/Ubuntu. Continuing setup..."

# ---------------------------------------------------------------------------
# 2. System dependencies
# ---------------------------------------------------------------------------
echo "==> Installing system dependencies..."
apt-get update -qq
apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    unzip \
    wget \
    curl \
    git \
    python3 \
    nginx

# ---------------------------------------------------------------------------
# 3. JAVA_HOME
# ---------------------------------------------------------------------------
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
echo "==> JAVA_HOME set to ${JAVA_HOME}"

# ---------------------------------------------------------------------------
# 4. Android command-line tools
# ---------------------------------------------------------------------------
echo "==> Downloading Android command-line tools..."
mkdir -p "${ANDROID_SDK_DIR}/cmdline-tools"
wget -q -O "${CMDLINE_TOOLS_ZIP}" "${CMDLINE_TOOLS_URL}"
unzip -q "${CMDLINE_TOOLS_ZIP}" -d /tmp/cmdline-tools-extract
# The zip contains a single top-level directory called "cmdline-tools"; rename it to "latest"
mv /tmp/cmdline-tools-extract/cmdline-tools "${ANDROID_SDK_DIR}/cmdline-tools/latest"
rm -f "${CMDLINE_TOOLS_ZIP}"

export ANDROID_HOME="${ANDROID_SDK_DIR}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_DIR}"
export PATH="${ANDROID_SDK_DIR}/cmdline-tools/latest/bin:${ANDROID_SDK_DIR}/platform-tools:${PATH}"

# ---------------------------------------------------------------------------
# 5. Accept SDK licenses and install components
# ---------------------------------------------------------------------------
echo "==> Accepting SDK licenses..."
yes | sdkmanager --licenses >/dev/null 2>&1 || true   # exit code 1 is normal when all are already accepted

echo "==> Installing SDK components..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# ---------------------------------------------------------------------------
# 6. Persist environment variables
# ---------------------------------------------------------------------------
echo "==> Writing environment to /etc/profile.d/android-build.sh..."
cat > /etc/profile.d/android-build.sh <<'EOF'
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export PATH="${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
EOF
chmod 644 /etc/profile.d/android-build.sh

# ---------------------------------------------------------------------------
# 7. Gradle wrapper jar
# ---------------------------------------------------------------------------
echo "==> Downloading Gradle ${GRADLE_VERSION} to extract gradle-wrapper.jar..."
wget -q -O "${GRADLE_ZIP}" "${GRADLE_ZIP_URL}"

WRAPPER_JAR_DEST="${REPO_ROOT}/gradle/wrapper/gradle-wrapper.jar"
mkdir -p "$(dirname "${WRAPPER_JAR_DEST}")"

unzip -p "${GRADLE_ZIP}" "gradle-${GRADLE_VERSION}/lib/gradle-wrapper.jar" > "${WRAPPER_JAR_DEST}" 2>/dev/null || \
    unzip -j "${GRADLE_ZIP}" "*/gradle-wrapper.jar" -d "$(dirname "${WRAPPER_JAR_DEST}")"
rm -f "${GRADLE_ZIP}"
echo "==> gradle-wrapper.jar placed at ${WRAPPER_JAR_DEST}"

# ---------------------------------------------------------------------------
# 8. gradlew script
# ---------------------------------------------------------------------------
GRADLEW_DEST="${REPO_ROOT}/gradlew"
echo "==> Downloading gradlew from Gradle ${GRADLE_VERSION} GitHub release..."
wget -q -O "${GRADLEW_DEST}" \
    "https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}.0/gradlew" || \
    wget -q -O "${GRADLEW_DEST}" \
    "https://raw.githubusercontent.com/gradle/gradle/refs/tags/v${GRADLE_VERSION}.0/gradlew"
chmod +x "${GRADLEW_DEST}"
echo "==> gradlew placed at ${GRADLEW_DEST} (executable)"

# ---------------------------------------------------------------------------
# 9. Download panel directory
# ---------------------------------------------------------------------------
echo "==> Creating APK panel directories..."
mkdir -p /var/www/apk-panel/builds

# ---------------------------------------------------------------------------
# 10. nginx configuration
# ---------------------------------------------------------------------------
echo "==> Configuring nginx..."
cat > /etc/nginx/sites-available/apk-panel <<'NGINX'
server {
    listen 8080;
    server_name _;

    root /var/www/apk-panel;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /builds/ {
        alias /var/www/apk-panel/builds/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/apk-panel /etc/nginx/sites-enabled/apk-panel
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx || systemctl start nginx

# ---------------------------------------------------------------------------
# 11. HTML index page
# ---------------------------------------------------------------------------
echo "==> Creating /var/www/apk-panel/index.html..."

# Copy the standalone panel.html if available, otherwise write inline
PANEL_HTML="${REPO_ROOT}/build-server/panel.html"
if [ -f "${PANEL_HTML}" ]; then
    cp "${PANEL_HTML}" /var/www/apk-panel/index.html
else
    cat > /var/www/apk-panel/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Magoradesk APK Build Server</title>
<style>body{background:#1a1a2e;color:#eee;font-family:sans-serif;max-width:800px;margin:40px auto;padding:20px}
h1{color:#e94560}button{background:#e94560;color:#fff;border:none;padding:12px 28px;font-size:1rem;border-radius:6px;cursor:pointer}
button:hover{background:#c73652}</style></head>
<body>
<h1>Magoradesk APK Build Server</h1>
<button onclick="fetch('/api/build',{method:'POST'}).then(()=>alert('Build triggered!'))">Build Now</button>
<p>See <a href="/builds/" style="color:#e94560">/builds/</a> for downloadable APKs.</p>
</body></html>
HTML
fi

# ---------------------------------------------------------------------------
# 12. Summary
# ---------------------------------------------------------------------------
echo ""
echo "======================================================"
echo " Setup complete!"
echo "======================================================"
echo " JAVA_HOME    : ${JAVA_HOME}"
echo " ANDROID_HOME : ${ANDROID_HOME}"
echo " gradlew      : ${GRADLEW_DEST}"
echo " APK output   : /var/www/apk-panel/builds/"
echo ""
echo " To start the Python build-panel server:"
echo "   python3 ${REPO_ROOT}/build-server/panel-server.py"
echo ""
echo " Or install the systemd service:"
echo "   cp ${REPO_ROOT}/build-server/magoradesk-panel.service /etc/systemd/system/"
echo "   systemctl daemon-reload && systemctl enable --now magoradesk-panel.service"
echo "======================================================"
