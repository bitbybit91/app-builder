#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# build.sh — Clone/update the repo and build the debug APK
# ---------------------------------------------------------------------------

# Source environment variables set by setup.sh
# shellcheck source=/dev/null
if [ -f /etc/profile.d/android-build.sh ]; then
    source /etc/profile.d/android-build.sh
fi

BRANCH="${1:-copilot/add-admin-wallet-percentage}"
REPO_URL="https://github.com/bitbybit91/app-builder.git"
BUILD_DIR="/opt/app-builder"
OUTPUT_DIR="/var/www/apk-panel/builds"
LOG_DIR="/var/log/app-builder"
GRADLE_VERSION="8.5"
GRADLE_ZIP_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/build-${TIMESTAMP}.log"

echo "==> Build started at $(date)" | tee -a "${LOG_FILE}"
echo "==> Branch : ${BRANCH}" | tee -a "${LOG_FILE}"
echo "==> Log    : ${LOG_FILE}" | tee -a "${LOG_FILE}"

# ---------------------------------------------------------------------------
# 1. Clone or update the repository
# ---------------------------------------------------------------------------
if [ -d "${BUILD_DIR}/.git" ]; then
    echo "==> Updating existing repo in ${BUILD_DIR}..." | tee -a "${LOG_FILE}"
    git -C "${BUILD_DIR}" fetch --all 2>&1 | tee -a "${LOG_FILE}"
    git -C "${BUILD_DIR}" checkout "${BRANCH}" 2>&1 | tee -a "${LOG_FILE}"
    git -C "${BUILD_DIR}" pull origin "${BRANCH}" 2>&1 | tee -a "${LOG_FILE}"
else
    echo "==> Cloning ${REPO_URL} into ${BUILD_DIR}..." | tee -a "${LOG_FILE}"
    git clone --branch "${BRANCH}" "${REPO_URL}" "${BUILD_DIR}" 2>&1 | tee -a "${LOG_FILE}"
fi

cd "${BUILD_DIR}"

# ---------------------------------------------------------------------------
# 2. Ensure gradle-wrapper.jar exists
# ---------------------------------------------------------------------------
WRAPPER_JAR="${BUILD_DIR}/gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "${WRAPPER_JAR}" ]; then
    echo "==> gradle-wrapper.jar missing — downloading from Gradle distribution..." | tee -a "${LOG_FILE}"
    GRADLE_ZIP="/tmp/gradle-${GRADLE_VERSION}-bin.zip"
    wget -q -O "${GRADLE_ZIP}" "${GRADLE_ZIP_URL}"
    mkdir -p "$(dirname "${WRAPPER_JAR}")"
    unzip -p "${GRADLE_ZIP}" "gradle-${GRADLE_VERSION}/lib/gradle-wrapper.jar" > "${WRAPPER_JAR}" 2>/dev/null || \
        unzip -j "${GRADLE_ZIP}" "*/gradle-wrapper.jar" -d "$(dirname "${WRAPPER_JAR}")"
    rm -f "${GRADLE_ZIP}"
    echo "==> gradle-wrapper.jar installed." | tee -a "${LOG_FILE}"
fi

# ---------------------------------------------------------------------------
# 3. Ensure gradlew exists and is executable
# ---------------------------------------------------------------------------
if [ ! -f "${BUILD_DIR}/gradlew" ]; then
    echo "==> gradlew missing — downloading from Gradle GitHub..." | tee -a "${LOG_FILE}"
    wget -q -O "${BUILD_DIR}/gradlew" \
        "https://raw.githubusercontent.com/gradle/gradle/v${GRADLE_VERSION}.0/gradlew" || \
        wget -q -O "${BUILD_DIR}/gradlew" \
        "https://raw.githubusercontent.com/gradle/gradle/refs/tags/v${GRADLE_VERSION}.0/gradlew"
fi
chmod +x "${BUILD_DIR}/gradlew"

# ---------------------------------------------------------------------------
# 4. local.properties
# ---------------------------------------------------------------------------
echo "sdk.dir=/opt/android-sdk" > "${BUILD_DIR}/local.properties"
echo "==> local.properties written." | tee -a "${LOG_FILE}"

# ---------------------------------------------------------------------------
# 5. Build
# ---------------------------------------------------------------------------
echo "==> Running assembleDebug..." | tee -a "${LOG_FILE}"
if "${BUILD_DIR}/gradlew" assembleDebug --no-daemon --stacktrace 2>&1 | tee -a "${LOG_FILE}"; then
    BUILD_SUCCESS=true
else
    BUILD_SUCCESS=false
fi

# ---------------------------------------------------------------------------
# 6. Handle output
# ---------------------------------------------------------------------------
mkdir -p "${OUTPUT_DIR}"

if [ "${BUILD_SUCCESS}" = "true" ]; then
    APK_SRC="$(find "${BUILD_DIR}/app/build/outputs/apk/debug/" -name "*.apk" | head -1)"
    if [ -z "${APK_SRC}" ]; then
        echo "ERROR: Build reported success but no APK found!" | tee -a "${LOG_FILE}"
        exit 1
    fi
    DATED_APK="${OUTPUT_DIR}/magoradesk-debug-$(date +%Y%m%d-%H%M%S).apk"
    cp "${APK_SRC}" "${DATED_APK}"
    cp "${APK_SRC}" "${OUTPUT_DIR}/magoradesk-debug-latest.apk"
    echo "" | tee -a "${LOG_FILE}"
    echo "=====================================================" | tee -a "${LOG_FILE}"
    echo " BUILD SUCCEEDED" | tee -a "${LOG_FILE}"
    echo " APK : ${DATED_APK}" | tee -a "${LOG_FILE}"
    echo " Latest : ${OUTPUT_DIR}/magoradesk-debug-latest.apk" | tee -a "${LOG_FILE}"
    echo " Log    : ${LOG_FILE}" | tee -a "${LOG_FILE}"
    echo "=====================================================" | tee -a "${LOG_FILE}"
else
    echo "" | tee -a "${LOG_FILE}"
    echo "=====================================================" | tee -a "${LOG_FILE}"
    echo " BUILD FAILED" | tee -a "${LOG_FILE}"
    echo " Log : ${LOG_FILE}" | tee -a "${LOG_FILE}"
    echo "=====================================================" | tee -a "${LOG_FILE}"
    exit 1
fi
