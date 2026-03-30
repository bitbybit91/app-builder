# Magoradesk — P2P Cryptocurrency Trading Android App

A peer-to-peer cryptocurrency trading Android application supporting Bitcoin, Monero, Litecoin, and Ethereum. Built with Kotlin for Android (API 24+, targeting API 34).

## Features

- P2P trade creation, listing, and execution
- Multi-currency support: BTC, XMR, LTC, ETH
- 4% admin fee automatically split to configured admin wallets
- Deposit and wallet management screens
- F-Droid / Google Play / Aurora Store compatible

## Quick Start (VPS — Zero to Downloadable APK)

```bash
# 1. Clone the repo
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder

# 2. Run the full VPS setup (Ubuntu 22.04 / 24.04, run as root or with sudo)
sudo bash setup-vps.sh

# 3. Open your browser
#    http://YOUR_VPS_IP  → download panel with built APK
```

`setup-vps.sh` handles everything: JDK 17, Android SDK, licenses, `gradle-wrapper.jar`, building the APK, and configuring nginx.

---

## Manual Setup (Step by Step)

### Prerequisites

| Tool | Version |
|------|---------|
| JDK | 17 (OpenJDK) |
| Android SDK | Platform 34, Build-tools 34.0.0 |
| Gradle | 8.5 (via wrapper) |
| OS | Ubuntu 22.04+ (VPS) or macOS/Windows (local) |

### 1. Install JDK 17

```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jdk

# macOS
brew install openjdk@17

# Verify
java -version   # must show 17.x
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64  # Linux
```

### 2. Install Android SDK

```bash
# Download command-line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-9477386_latest.zip -d /opt/android-sdk/cmdline-tools
mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest

export ANDROID_HOME=/opt/android-sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Accept licenses and install required components
yes | sdkmanager --licenses
sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"
```

### 3. Configure the Project

```bash
# Create local.properties (required by Android Gradle Plugin)
echo "sdk.dir=$ANDROID_HOME" > local.properties
```

### 4. Download the Gradle Wrapper JAR

The `gradle-wrapper.jar` binary is not committed to git. Download it:

```bash
mkdir -p gradle/wrapper
wget -O gradle/wrapper/gradle-wrapper.jar \
  https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar
chmod +x gradlew
```

### 5. Build the APK

```bash
# Debug APK (no signing required)
./gradlew assembleDebug

# The APK is at:
# app/build/outputs/apk/debug/app-debug.apk
```

---

## Configuration

### Admin Wallet Addresses

Edit `app/src/main/java/com/magoradesk/app/service/AdminWalletConfig.kt` and replace placeholder addresses:

```kotlin
private val adminWallets = mutableMapOf(
    CryptoCurrency.BITCOIN  to "bc1q...",   // Your BTC wallet
    CryptoCurrency.MONERO   to "4...",      // Your XMR wallet (95 chars)
    CryptoCurrency.LITECOIN to "ltc1q...",  // Your LTC wallet
    CryptoCurrency.ETHEREUM to "0x...",     // Your ETH wallet (42 chars)
)
```

A 4% fee from all trades and deposits is sent to these wallets. The app warns at startup if any address still contains the placeholder prefix `"YOUR_"`.

### Release Signing

For a signed release APK, create a keystore and configure it in `app/build.gradle.kts`:

```bash
keytool -genkeypair -v -keystore release.jks -alias mykey \
  -keyalg RSA -keysize 2048 -validity 10000

# Set environment variables before building
export KEYSTORE_PATH=/path/to/release.jks
export KEY_ALIAS=mykey
export KEY_PASSWORD=yourpassword
export STORE_PASSWORD=yourstorepassword

./gradlew assembleRelease
```

---

## Build Commands

| Command | Output |
|---------|--------|
| `./gradlew assembleDebug` | Debug APK — `app/build/outputs/apk/debug/` |
| `./gradlew assembleRelease` | Release APK — `app/build/outputs/apk/release/` |
| `./gradlew bundleRelease` | Release AAB — `app/build/outputs/bundle/release/` |
| `./gradlew test` | Run unit tests |
| `./gradlew clean` | Clean build directory |

---

## VPS Download Panel

After running `setup-vps.sh`, a self-hosted download panel is available at `http://YOUR_VPS_IP`.

### Rebuild on Demand

```bash
# Pull latest code and rebuild
sudo bash build-and-serve.sh
```

### Automated Builds via Cron

```bash
# Edit root crontab
sudo crontab -e

# Rebuild every 6 hours
0 */6 * * * /path/to/build-and-serve.sh >> /var/log/magoradesk-build.log 2>&1
```

### Nginx Configuration

- Config file: `nginx/nginx-app-builder.conf` (copied to `/etc/nginx/sites-available/apk-panel`)
- Serves APKs from `/var/www/apk-panel/builds/` with `Content-Type: application/vnd.android.package-archive`
- HTML panel at `/var/www/apk-panel/index.html` auto-refreshes every 5 minutes

---

## File Structure

```
app-builder/
├── app/
│   ├── build.gradle.kts          # App module build config (SDK 34, minSdk 24)
│   └── src/
│       └── main/java/com/magoradesk/app/
│           ├── service/
│           │   ├── AdminWalletConfig.kt   # Admin wallet addresses (configure this!)
│           │   ├── AdminFeeService.kt     # 4% fee calculation
│           │   ├── TradeService.kt        # Trade logic
│           │   └── ...
│           └── model/
│               ├── CryptoCurrency.kt
│               └── ...
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar     # Downloaded by setup-vps.sh (not in git)
│       └── gradle-wrapper.properties  # Points to Gradle 8.5
├── nginx/
│   ├── index.html                 # Download panel template
│   └── nginx-app-builder.conf     # Nginx server block
├── build.gradle.kts               # Root build file (AGP 8.2.2, Kotlin 1.9.22)
├── settings.gradle.kts            # Project settings (dependencyResolutionManagement)
├── gradle.properties              # JVM args including --add-opens for JDK 17+
├── gradlew                        # Gradle wrapper shell script
├── gradlew.bat                    # Gradle wrapper Windows script
├── setup-vps.sh                   # One-shot VPS setup script
├── build-and-serve.sh             # Ongoing rebuild script
├── local.properties               # Created by setup-vps.sh (sdk.dir=...)
└── PUBLISHING.md                  # Store publishing guide
```

---

## Troubleshooting

### `bash: ./gradlew: No such file or directory`

The Gradle wrapper script is missing. It is included in this repo. If it disappears:

```bash
# Verify it exists
ls -la gradlew

# If missing, restore from git
git checkout gradlew
chmod +x gradlew
```

Also ensure `gradle/wrapper/gradle-wrapper.jar` exists (download via `setup-vps.sh` or manually):

```bash
wget -O gradle/wrapper/gradle-wrapper.jar \
  https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar
```

### `ERROR: JAVA_HOME is set to an invalid directory`

JDK 17 is not installed or `JAVA_HOME` points to a wrong path:

```bash
sudo apt install openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
java -version  # must show 17.x
```

### `module java.base does not open java.lang` (JDK 17 module access)

Gradle is missing the `--add-opens` JVM arguments. This is already fixed in `gradle.properties`:

```properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8 \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/java.io=ALL-UNNAMED \
  --add-opens=java.base/java.util=ALL-UNNAMED
```

If you see this error, verify your `gradle.properties` contains the `--add-opens` flags.

### `dependencyResolution` not found / ScriptPluginFactory error

A typo existed in `settings.gradle.kts`. The correct identifier is `dependencyResolutionManagement` (not `dependencyResolution`). This is already fixed in this repo. Verify:

```bash
grep "dependencyResolutionManagement" settings.gradle.kts
```

### `GRADLE_HOME is unknown` / corrupt gradle-wrapper.jar

The `gradle-wrapper.jar` is corrupted or missing. Re-download it:

```bash
rm -f gradle/wrapper/gradle-wrapper.jar
wget -O gradle/wrapper/gradle-wrapper.jar \
  https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar
./gradlew --version  # verify
```

### `SDK location not found`

`local.properties` is missing. Create it:

```bash
echo "sdk.dir=/opt/android-sdk" > local.properties
# Replace /opt/android-sdk with your actual ANDROID_HOME path
```

### Build fails with `License for package ... not accepted`

```bash
yes | sdkmanager --licenses
```

---

## Publishing

See [PUBLISHING.md](PUBLISHING.md) for full instructions on publishing to:
- Google Play Store
- F-Droid
- Aurora Store

---

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.

magoradesk
