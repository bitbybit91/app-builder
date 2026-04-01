# app-builder

> Autonomous Flutter mobile-app build system **+** production-ready P2P cryptocurrency exchange app (CapitalMonero).

This monorepo contains two major components that live on separate feature branches:

| Branch | Component | Description |
|--------|-----------|-------------|
| `copilot/create-capitalmonero-app` | **CapitalMonero Flutter App** | Full-featured P2P crypto exchange mobile app (Android & iOS) |
| `copilot/create-autonomous-python-build-system` | **Autonomous Build System** | Python CLI that clones, resolves, builds, signs, and reports on Flutter apps end-to-end |

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Building](#building)
6. [Running](#running)
7. [Testing](#testing)
8. [Deployment](#deployment)
9. [Project Structure](#project-structure)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### CapitalMonero Flutter App

A peer-to-peer cryptocurrency exchange mobile application supporting Monero (XMR) and Bitcoin (BTC) trading. Built with **Flutter** using clean architecture principles.

**Key features:**

- P2P trading — create and accept buy/sell offers for XMR and BTC
- Integrated wallets — deposit, withdraw, and view transaction history
- Encrypted messaging — PGP-encrypted peer-to-peer chat
- Authentication — username/password + TOTP two-factor authentication + BIP39 mnemonic recovery
- Advanced search — filter offers by coin, payment method, currency, country
- Reputation system — user feedback and trust scores
- Admin dashboard — user management, dispute resolution, statistics
- Multi-language — 12 locales (EN, ES, FR, DE, KO, ZH, JA, PT, TH, SV, DA, NB)
- Material 3 design — light and dark themes with color seed `#6750A4`

**Architecture:** Clean Architecture with BLoC state management, GoRouter navigation, Dio HTTP client, GetIt dependency injection, and Drift local database.

### Autonomous Build System

A Python CLI (`app_builder.py`) that automates every step of building a Flutter app from source:

1. Validate environment (Flutter SDK, Android SDK, Xcode, Java, CocoaPods)
2. Clone multiple Git repositories (main app + dependency packages + tools)
3. Generate SHA-256 file manifests with 100% coverage enforcement
4. Rewrite `pubspec.yaml` with local `path:` references for dependencies
5. Run `build_runner`, ARB localization generation, and custom scripts
6. Validate assets (icons, splash screens, fonts)
7. Build Android artifacts (AAB for Google Play + APK for direct install)
8. Build iOS artifacts (IPA via Xcode)
9. Generate Fastlane configuration for store deployment
10. Run post-build validation and produce HTML + JSON reports

---

## Prerequisites

### CapitalMonero Flutter App

| Tool | Required Version | Notes |
|------|-----------------|-------|
| **Flutter SDK** | `>=3.0.0` | Specified in `pubspec.yaml` (`environment.flutter`) |
| **Dart SDK** | `>=3.0.0 <4.0.0` | Specified in `pubspec.yaml` (`environment.sdk`) |
| **Android SDK** | Compile SDK `34`, Min SDK `21`, Target SDK `34` | Specified in `android/app/build.gradle` |
| **Gradle** | `8.3` (wrapper) | Specified in `android/gradle/wrapper/gradle-wrapper.properties` |
| **Android Gradle Plugin** | `8.2.2` | Specified in `android/build.gradle` and `android/settings.gradle` |
| **Kotlin** | `1.9.22` | Specified in `android/build.gradle` |
| **Java** | `1.8+` (compile) / `11+` (Gradle) | `compileOptions` in `android/app/build.gradle` |
| **Xcode** | `14.0+` | Required for iOS builds (macOS only) |
| **CocoaPods** | Latest | Required for iOS builds |
| **iOS Deployment Target** | `14.0` | Specified in `ios/Podfile` and `ios/Runner/Info.plist` |

#### Platform-specific setup

<details>
<summary><strong>macOS</strong></summary>

```bash
# Install Flutter (via Homebrew)
brew install --cask flutter

# Install Xcode from the Mac App Store, then:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Install CocoaPods
sudo gem install cocoapods

# Install Android Studio (includes Android SDK)
brew install --cask android-studio

# Accept Android licenses
flutter doctor --android-licenses
```

</details>

<details>
<summary><strong>Linux</strong></summary>

```bash
# Install Flutter manually
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Install Android SDK via Android Studio or command-line tools
# https://developer.android.com/studio#command-tools

# Accept Android licenses
flutter doctor --android-licenses

# Note: iOS builds are not supported on Linux
```

</details>

<details>
<summary><strong>Windows</strong></summary>

```powershell
# Install Flutter (via Chocolatey)
choco install flutter

# Install Android Studio from https://developer.android.com/studio

# Accept Android licenses
flutter doctor --android-licenses

# Note: iOS builds are not supported on Windows
```

</details>

### Autonomous Build System

| Tool | Required Version | Notes |
|------|-----------------|-------|
| **Python** | `3.9+` | Runs `app_builder.py` |
| **Flutter SDK** | `>=3.10.0` | Specified in `config.yaml` (`environment.flutter_min_version`) |
| **Java** | `11+` | Specified in `config.yaml` (`environment.java_min_version`) |
| **Xcode** | `14.0+` | macOS only; specified in `config.yaml` (`environment.xcode_min_version`) |
| **Ruby** | `2.7+` | Optional; only required if Fastlane is enabled |
| **Git** | Latest | Required for repository cloning |

**Python dependencies** (from `requirements.txt`):

| Package | Version |
|---------|---------|
| PyYAML | `>=6.0` |
| Jinja2 | `>=3.1.0` |
| colorama | `>=0.4.6` |
| tqdm | `>=4.65.0` |
| GitPython | `>=3.1.40` |

---

## Installation

### CapitalMonero Flutter App

```bash
# Clone the repository
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder

# Switch to the Flutter app branch
git checkout copilot/create-capitalmonero-app

# Install Flutter dependencies
flutter pub get

# Generate code (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# (iOS only) Install CocoaPods dependencies
cd ios && pod install && cd ..
```

### Autonomous Build System

```bash
# Clone the repository
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder

# Switch to the build system branch
git checkout copilot/create-autonomous-python-build-system

# Install Python dependencies
pip install -r requirements.txt
```

---

## Configuration

### CapitalMonero Flutter App

#### Environment Variables / `.env` Files

The app reads API configuration from `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'https://api.capitalmonero.com/api/v1';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
```

To change the API endpoint, edit `lib/core/constants/api_constants.dart` before building.

Alternatively, use `--dart-define` to pass values at build time:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

#### Android Signing (`android/key.properties`)

For release builds, create `android/key.properties`:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-your-keystore.jks>
```

> **Note:** This file is listed in `.gitignore` and must not be committed.

#### Gradle JVM Settings (`android/gradle.properties`)

```properties
org.gradle.jvmargs=-Xmx4G
android.useAndroidX=true
android.enableJetifier=true
```

#### iOS Signing

Configure signing in Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target → **Signing & Capabilities**
3. Set your Team, Bundle Identifier (`com.capitalmonero.app`), and provisioning profile

#### Localization (`l10n.yaml`)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Supported locales: `en`, `es`, `fr`, `de`, `ko`, `zh`, `ja`, `pt`, `th`, `sv`, `da`, `nb`

### Autonomous Build System (`config.yaml`)

The build system is driven by a single YAML configuration file. Key sections:

| Section | Purpose | Key Fields |
|---------|---------|------------|
| `repos` | Git repositories to clone | `url`, `branch`, `type` (`main_app` / `dependency` / `tool`), `local_name`, `package_name` |
| `app` | App metadata | `name`, `bundle_id`, `version`, `build_number` |
| `android` | Android build config | `min_sdk_version: 21`, `target_sdk_version: 34`, `compile_sdk_version: 34`, keystore paths |
| `ios` | iOS build config | `team_id`, `provisioning_profile`, `deployment_target` (default `"13.0"` in template; CapitalMonero uses `"14.0"`), `export_method` |
| `build` | Build options | `mode: release`, `output_dir: ./output`, `clean_before_build: true` |
| `fastlane` | Store deployment | `enabled: false`, `android_package`, `ios_app_identifier`, API key paths |
| `environment` | Tool version requirements | `flutter_min_version: "3.10.0"`, `java_min_version: "11"`, `xcode_min_version: "14.0"` |
| `logging` | Log settings | `level: INFO`, `log_file: build.log`, `colored_console: true` |

Example minimal `config.yaml`:

```yaml
repos:
  - url: https://github.com/AgoraDesk-LocalMonero/agoradesk-app-foss
    branch: main
    type: main_app
    local_name: agoradesk-app-foss

app:
  name: AgoraDesk
  bundle_id: com.agoradesk.app
  version: 1.0.0
  build_number: 1

build:
  mode: release
  output_dir: ./output
  clean_before_build: true
  build_android: true
  build_ios: false
```

---

## Building

### CapitalMonero Flutter App

#### Code Generation (required before building)

```bash
# Generate freezed, json_serializable, and drift code
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n
```

#### Android

```bash
# Debug APK (default flavor)
flutter build apk --debug

# Release APK — production flavor
flutter build apk --flavor production --release

# Release APK — staging flavor
flutter build apk --flavor staging --release

# Release App Bundle (AAB) — production (for Google Play)
flutter build appbundle --flavor production --release

# Release App Bundle (AAB) — staging
flutter build appbundle --flavor staging --release
```

| Flavor | Application ID | Version Name Suffix |
|--------|----------------|---------------------|
| `production` | `com.capitalmonero.app` | _(none)_ |
| `staging` | `com.capitalmonero.app.staging` | `-staging` |

**Release build features** (from `android/app/build.gradle`):
- R8/ProGuard minification enabled (`minifyEnabled true`)
- Resource shrinking enabled (`shrinkResources true`)
- ProGuard rules in `android/app/proguard-rules.pro`
- MultiDex enabled

#### iOS (macOS only)

```bash
# Install pods first
cd ios && pod install && cd ..

# Debug build
flutter build ios --debug --no-codesign

# Release build (requires signing)
flutter build ios --release

# Build IPA for distribution
flutter build ipa --release
```

#### Clean Build

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

### Autonomous Build System

```bash
# Full build (Android + iOS)
python app_builder.py --config config.yaml

# Android only
python app_builder.py --config config.yaml --skip-ios

# iOS only
python app_builder.py --config config.yaml --skip-android

# Custom output directory
python app_builder.py --config config.yaml --output-dir ./my-output

# Skip pre-build validation
python app_builder.py --config config.yaml --skip-validation

# Skip flutter clean
python app_builder.py --config config.yaml --no-clean

# Verbose logging
python app_builder.py --config config.yaml --log-level DEBUG
```

| CLI Flag | Description |
|----------|-------------|
| `--config FILE` | Path to YAML config file (required) |
| `--output-dir DIR` | Override output directory (default: `./output`) |
| `--skip-android` | Skip Android build |
| `--skip-ios` | Skip iOS build |
| `--skip-validation` | Skip pre-build validation checks |
| `--no-clean` | Skip `flutter clean` step |
| `--log-level` | `DEBUG`, `INFO`, `WARNING`, or `ERROR` (default: from config) |

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0` | Build succeeded |
| `1` | Build failed (see log for details) |
| `2` | Invalid arguments or config |

---

## Running

### CapitalMonero Flutter App

```bash
# Run on connected device/emulator (debug mode)
flutter run

# Run production flavor
flutter run --flavor production

# Run staging flavor
flutter run --flavor staging

# Run with a specific device
flutter devices                     # list devices
flutter run -d <device-id>

# Run with hot reload enabled (default in debug)
flutter run --flavor production --debug

# Run with dart-define overrides
flutter run --dart-define=API_BASE_URL=https://staging-api.capitalmonero.com/api/v1
```

### Autonomous Build System

```bash
# Dry run: validate environment and configuration
python app_builder.py --config config.yaml --skip-android --skip-ios --log-level DEBUG
```

---

## Testing

### CapitalMonero Flutter App

The project includes test infrastructure with the following dev dependencies:

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Widget and unit testing framework |
| `bloc_test` | `^9.1.5` | BLoC state management testing |
| `mocktail` | `^1.0.3` | Mocking library (no code generation) |
| `flutter_lints` | `^3.0.1` | Lint rules for code quality |

#### Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart

# Run tests matching a name pattern
flutter test --name "should emit authenticated state"
```

#### Static Analysis

```bash
# Run Dart analyzer with project lint rules (analysis_options.yaml)
flutter analyze

# Format code
dart format lib/ test/
```

The project uses `analysis_options.yaml` extending `package:flutter_lints/flutter.yaml` with 29 additional lint rules. Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis.

### Autonomous Build System

```bash
# Validate Python syntax
python -m py_compile app_builder.py

# Run with debug logging to verify behavior
python app_builder.py --config config.yaml --log-level DEBUG --skip-android --skip-ios
```

---

## Deployment

### Android — Google Play Store

1. **Create a signing keystore:**

   ```bash
   keytool -genkey -v -keystore ~/capitalmonero-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias capitalmonero
   ```

2. **Configure `android/key.properties`** (see [Configuration](#android-signing-androidkeyproperties))

3. **Build a signed App Bundle:**

   ```bash
   flutter build appbundle --flavor production --release
   ```

4. **Output:** `build/app/outputs/bundle/productionRelease/app-production-release.aab`

5. **Upload** the `.aab` to the [Google Play Console](https://play.google.com/console/)

### Android — Direct APK Distribution

```bash
flutter build apk --flavor production --release
```

Output: `build/app/outputs/flutter-apk/app-production-release.apk`

### iOS — App Store

1. **Configure signing** in Xcode (see [Configuration](#ios-signing))

2. **Build an IPA:**

   ```bash
   flutter build ipa --release
   ```

3. **Output:** `build/ios/ipa/CapitalMonero.ipa`

4. **Upload** via Xcode Organizer or `xcrun altool`

### Fastlane (via Build System)

Set `fastlane.enabled: true` in `config.yaml` and provide:

| Field | Description |
|-------|-------------|
| `google_play_json_key` | Path to Google Play service account JSON key |
| `app_store_connect_key_id` | App Store Connect API Key ID |
| `app_store_connect_issuer_id` | App Store Connect Issuer ID |
| `app_store_connect_key_filepath` | Path to `.p8` API key file |

```bash
python app_builder.py --config config.yaml
```

The build system generates Fastlane `Appfile` and `Fastfile` for automated store submissions.

---

## Project Structure

### CapitalMonero Flutter App

```
copilot/create-capitalmonero-app
├── pubspec.yaml                              # Flutter dependencies & metadata
├── analysis_options.yaml                     # Dart linter rules (29 rules)
├── l10n.yaml                                 # Localization config
├── lib/
│   ├── main.dart                             # App entry point (DI setup + runApp)
│   ├── app/
│   │   ├── app.dart                          # MaterialApp.router + BLoC providers
│   │   ├── router.dart                       # GoRouter with 12 routes
│   │   └── theme.dart                        # Material 3 light/dark themes
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart            # Base URL, timeouts, retries
│   │   │   └── app_constants.dart            # App name, version, supported coins/fiat
│   │   ├── di/
│   │   │   └── injection.dart                # GetIt DI container setup
│   │   ├── errors/
│   │   │   ├── exceptions.dart               # Custom exception types
│   │   │   └── failures.dart                 # Domain failure models
│   │   ├── network/
│   │   │   ├── api_client.dart               # Dio wrapper (GET/POST/PUT/DELETE/PATCH)
│   │   │   ├── api_endpoints.dart            # REST endpoint paths
│   │   │   └── interceptors/
│   │   │       └── auth_interceptor.dart     # JWT auth header injection
│   │   ├── security/
│   │   │   ├── mnemonic_service.dart         # BIP39 mnemonic generation/validation
│   │   │   ├── pgp_service.dart              # PGP encryption for messages
│   │   │   ├── session_manager.dart          # Auth session lifecycle
│   │   │   └── totp_service.dart             # TOTP 2FA code generation/verification
│   │   └── utils/
│   │       ├── formatters.dart               # Display formatters
│   │       └── validators.dart               # Input validation
│   ├── features/                             # Feature modules (Clean Architecture)
│   │   ├── auth/                             # Login, registration, 2FA
│   │   ├── trading/                          # Buy/sell offers, trade execution
│   │   ├── wallet/                           # XMR & BTC wallet management
│   │   ├── messaging/                        # PGP-encrypted P2P chat
│   │   ├── profile/                          # User profiles & reputation
│   │   ├── search/                           # Offer search & filtering
│   │   ├── notifications/                    # Push notification management
│   │   └── admin/                            # Admin dashboard & moderation
│   │       Each feature follows:
│   │       ├── data/
│   │       │   ├── datasources/              # Remote API data sources
│   │       │   ├── models/                   # JSON-serializable data models
│   │       │   └── repositories/             # Repository implementations
│   │       ├── domain/
│   │       │   ├── entities/                 # Core business entities
│   │       │   ├── repositories/             # Repository interfaces
│   │       │   └── usecases/                 # Business logic use cases
│   │       └── presentation/
│   │           ├── bloc/                     # BLoC state management
│   │           └── pages/                    # UI pages (widgets)
│   ├── shared/
│   │   ├── extensions/                       # Dart extension methods
│   │   ├── models/                           # Shared data models (pagination)
│   │   └── widgets/                          # Reusable UI components
│   └── l10n/                                 # ARB localization files (12 languages)
│       ├── app_en.arb                        # English (template)
│       ├── app_es.arb                        # Spanish
│       ├── app_fr.arb                        # French
│       ├── app_de.arb                        # German
│       ├── app_ko.arb                        # Korean
│       ├── app_zh.arb                        # Chinese
│       ├── app_ja.arb                        # Japanese
│       ├── app_pt.arb                        # Portuguese
│       ├── app_th.arb                        # Thai
│       ├── app_sv.arb                        # Swedish
│       ├── app_da.arb                        # Danish
│       └── app_nb.arb                        # Norwegian Bokmål
├── android/
│   ├── build.gradle                          # Root Gradle config (AGP 8.2.2, Kotlin 1.9.22)
│   ├── settings.gradle                       # Plugin management & module includes
│   ├── gradle.properties                     # JVM args (-Xmx4G), AndroidX
│   ├── gradle/wrapper/
│   │   └── gradle-wrapper.properties         # Gradle 8.3 distribution
│   └── app/
│       ├── build.gradle                      # App module: flavors, signing, ProGuard
│       ├── proguard-rules.pro                # R8 keep rules (Flutter, BouncyCastle, Gson)
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml        # Permissions, activity config
│           │   ├── kotlin/.../MainActivity.kt # Android entry point
│           │   └── res/                       # Drawables, styles, launch screens
│           ├── debug/AndroidManifest.xml
│           └── profile/AndroidManifest.xml
└── ios/
    ├── Podfile                               # CocoaPods (platform :ios, '14.0')
    ├── Runner.xcodeproj/                     # Xcode project
    ├── Runner.xcworkspace/                   # Xcode workspace
    └── Runner/
        ├── AppDelegate.swift                 # iOS app delegate
        ├── Info.plist                         # App config (camera, Face ID permissions)
        ├── Assets.xcassets/                   # App icons
        └── Base.lproj/                       # Storyboards
```

### Autonomous Build System

```
copilot/create-autonomous-python-build-system
├── app_builder.py                            # Main CLI entry point & build orchestrator
├── config.yaml                               # Build configuration template
├── requirements.txt                          # Python dependencies (5 packages)
├── lib/
│   ├── __init__.py
│   ├── environment_setup.py                  # SDK version validation
│   ├── repo_manager.py                       # Git clone & file manifest generation
│   ├── dependency_resolver.py                # pubspec.yaml path: rewriting
│   ├── code_generator.py                     # build_runner & ARB code generation
│   ├── android_builder.py                    # Gradle AAB/APK builds & signing
│   ├── ios_builder.py                        # Xcode IPA builds
│   ├── asset_processor.py                    # Icon, splash screen, font validation
│   ├── fastlane_manager.py                   # Fastlane Appfile/Fastfile generation
│   ├── validator.py                          # Pre/post-build validation checks
│   └── report_generator.py                   # HTML + JSON build reports
└── templates/
    ├── __init__.py
    └── report.html                           # Jinja2 HTML report template
```

---

## Troubleshooting

### Flutter App

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails with version conflicts | Run `flutter pub upgrade --major-versions` then `flutter pub get` |
| Generated files missing (`.g.dart`, `.freezed.dart`) | Run `dart run build_runner build --delete-conflicting-outputs` |
| Localization files not generated | Run `flutter gen-l10n` and verify `l10n.yaml` exists |
| `flutter doctor` shows Android license issues | Run `flutter doctor --android-licenses` and accept all |
| iOS Pod install fails | Run `cd ios && pod deintegrate && pod install && cd ..` |
| iOS deployment target mismatch | Ensure `IPHONEOS_DEPLOYMENT_TARGET` is `14.0` in Xcode build settings |
| Android build OOM | Increase heap in `android/gradle.properties`: `org.gradle.jvmargs=-Xmx4G` (already set) |
| `Execution failed for task ':app:minifyReleaseWithR8'` | Check ProGuard rules in `android/app/proguard-rules.pro` |
| MultiDex errors on older devices | Already enabled (`multiDexEnabled true` in `android/app/build.gradle`) |
| `key.properties` not found for release build | Create `android/key.properties` with your keystore details (see [Configuration](#android-signing-androidkeyproperties)) |
| Build fails after switching branches | Run `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs` |
| Camera/biometric permissions denied at runtime | Check `AndroidManifest.xml` and `ios/Runner/Info.plist` for permission declarations |

### Build System

| Problem | Solution |
|---------|----------|
| `ModuleNotFoundError: No module named 'yaml'` | Run `pip install -r requirements.txt` |
| Git clone fails | Check network connectivity and repository access permissions |
| `flutter` not found | Ensure Flutter is on your `PATH` and run `flutter doctor` |
| Build times out | Increase `subprocess_timeout` in `config.yaml` (default: `600` seconds) |
| iOS build skipped on Linux/Windows | iOS builds require macOS with Xcode; this is expected behavior |
| Manifest verification fails | Ensure all files are present and unmodified since cloning |
| Colorama import warning | Install with `pip install colorama>=0.4.6` (optional, for colored output) |

### General

```bash
# Verify Flutter environment
flutter doctor -v

# Check Dart SDK version
dart --version

# Check Android SDK setup
sdkmanager --list

# Check Xcode version (macOS only)
xcodebuild -version

# Check Python version (build system)
python3 --version
```
