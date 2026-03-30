# Publishing Guide for Magoradesk

This document describes how to prepare and publish Magoradesk to F-Droid, Aurora Store, and Google Play.

## Prerequisites

- Android SDK with Build Tools 34
- JDK 17
- Gradle 8.5+
- A signing keystore for release builds

## Build Configuration

### Signing Setup

1. Generate a signing keystore:
   ```bash
   keytool -genkey -v -keystore magoradesk-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias magoradesk
   ```

2. Create `local.properties` in the project root:
   ```properties
   RELEASE_STORE_FILE=/path/to/magoradesk-release.jks
   RELEASE_STORE_PASSWORD=your_store_password
   RELEASE_KEY_ALIAS=magoradesk
   RELEASE_KEY_PASSWORD=your_key_password
   ```

### Admin Wallet Configuration

Before publishing, configure the admin wallet addresses in `AdminWalletConfig.kt`. Replace the placeholder addresses with real wallet addresses for each supported cryptocurrency:

- Bitcoin (BTC)
- Monero (XMR)
- Litecoin (LTC)
- Ethereum (ETH)

The 4% admin fee from all trades and deposits will be sent to these wallets.

## Building

### Debug Build
```bash
./gradlew assembleDebug
```

### Release APK (for F-Droid / Aurora Store)
```bash
./gradlew assembleRelease
```

### Release AAB (for Google Play)
```bash
./gradlew bundleRelease
```

## Publishing to Google Play

1. **Create a Google Play Developer account** at https://play.google.com/console

2. **Create a new app** in the Google Play Console

3. **Upload the AAB**:
   ```bash
   ./gradlew bundleRelease
   ```
   Upload `app/build/outputs/bundle/release/app-release.aab`

4. **Fill in store listing** using content from `fastlane/metadata/android/en-US/`

5. **Set content rating** via the Google Play Console questionnaire

6. **Submit for review**

### Using Fastlane
```bash
fastlane deploy_internal  # Deploy to internal test track
fastlane deploy_production  # Deploy to production
```

## Publishing to F-Droid

F-Droid builds apps from source. To submit:

1. **Ensure the app builds from source** without proprietary dependencies

2. **Create the metadata file** (already provided at `metadata/com.magoradesk.app.yml`)

3. **Submit a merge request** to the [F-Droid Data repository](https://gitlab.com/fdroid/fdroiddata):
   - Fork the repository
   - Add `metadata/com.magoradesk.app.yml`
   - Submit a merge request

4. **Tag releases** with version tags (e.g., `v1.0.0`)

5. F-Droid will automatically build and publish new versions from tagged releases

### F-Droid Requirements Met
- ✅ Open source repository
- ✅ Builds with standard Gradle
- ✅ No proprietary dependencies
- ✅ Metadata file provided (`metadata/com.magoradesk.app.yml`)
- ✅ Fastlane metadata structure provided
- ✅ Network security config (HTTPS only)

## Publishing to Aurora Store

Aurora Store is an alternative Google Play client. Apps published on Google Play are automatically available on Aurora Store.

To ensure compatibility:

1. **Publish to Google Play first** (Aurora Store mirrors Google Play)
2. **Ensure the app follows standard Android conventions**:
   - ✅ Proper AndroidManifest.xml
   - ✅ Standard Gradle build
   - ✅ Target SDK 34
   - ✅ Proper signing configuration
3. **For F-Droid variant**: Apps published on F-Droid are also accessible via Aurora Store's F-Droid repository integration

## Admin Fee System

The app implements a 4% admin fee on all cryptocurrency trades and deposits:

- **Trades**: When a trade is completed, 4% of the cryptocurrency amount is sent to the admin wallet, and 96% goes to the buyer
- **Deposits**: When a deposit is confirmed, 4% is transferred to the admin wallet, and 96% is credited to the user's account
- **Transparency**: The fee is clearly displayed to users before every transaction
- **Configuration**: Admin wallet addresses are configurable in Settings and in `AdminWalletConfig.kt`

## Testing

Run unit tests:
```bash
./gradlew test
```

Run all tests:
```bash
./gradlew check
```
