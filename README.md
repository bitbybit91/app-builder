# CapitalMonero

**Peer-to-peer cryptocurrency exchange** — a cross-platform Flutter application for trading Monero (XMR) and Bitcoin (BTC) directly between users.

| | |
|---|---|
| **Package (Android)** | `com.capitalmonero.app` |
| **Bundle ID (iOS)** | `com.capitalmonero.app` |
| **Flutter SDK** | `>=3.10.0` |
| **Dart SDK** | `>=3.0.0 <4.0.0` |
| **Min Android SDK** | 21 |
| **Target / Compile Android SDK** | 34 |
| **iOS Deployment Target** | 14.0 |

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Build Commands](#build-commands)
- [Code Generation](#code-generation)
- [Testing](#testing)
- [Linting & Analysis](#linting--analysis)
- [Low-Resource Machine Settings](#low-resource-machine-settings)
- [API Endpoints](#api-endpoints)
- [Flavors](#flavors)
- [Dependencies](#dependencies)

---

## Features

| Feature | Description |
|---|---|
| **Auth** | Username/password login, registration, TOTP-based 2FA, mnemonic (BIP39) recovery, PIN/biometric lock, auto session timeout (60 min) |
| **Offers** | Create/browse buy/sell offers for XMR and BTC, filter by coin, payment method, currency, country, infinite-scroll pagination |
| **Trades** | Escrow-based trade flow (open → paid → completed), trade chat, cancel, dispute resolution |
| **Wallet** | XMR/BTC balances, deposit address generation, withdrawal, transaction history |
| **Profile** | Reputation score, trust levels (Unproven → High), trade count, feedback, public profiles |
| **Notifications** | Push notifications (Firebase), in-app notification center, mark as read |
| **Settings** | Biometric auth toggle, PIN management, 2FA setup, dark mode, about/legal |

---

## Architecture

Clean Architecture with three layers per feature:

```
Presentation  →  Domain  →  Data
(BLoC/Cubit)     (UseCases, Entities, Repo Interfaces)   (Repo Impls, DataSources, Models)
```

| Concern | Library |
|---|---|
| State management | `flutter_bloc` (BLoC pattern) |
| Navigation | `go_router` (declarative, deep-link support) |
| HTTP client | `dio` (with auth interceptor for automatic token refresh) |
| Dependency injection | `get_it` (manual registration in `lib/core/di/injection.dart`) |
| Local database | `drift` (SQLite) |
| Secure storage | `flutter_secure_storage` (tokens, PIN, mnemonics) |
| Error handling | `dartz` (`Either<Failure, T>`) |
| Serialization | `json_serializable` + `freezed` |
| Encryption | `pointycastle` (PGP), `bip39` (mnemonic generation) |

---

## Project Structure

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # Root widget (MultiBlocProvider + MaterialApp.router)
│   └── router.dart                    # GoRouter route definitions
├── core/
│   ├── constants/
│   │   ├── api_constants.dart         # API base URL + all endpoint paths
│   │   └── app_constants.dart         # App-wide constants (timeouts, limits, crypto codes)
│   ├── di/
│   │   └── injection.dart            # GetIt service registration
│   ├── error/
│   │   ├── exceptions.dart           # ServerException, CacheException, etc.
│   │   └── failures.dart             # Failure types for Either returns
│   ├── network/
│   │   ├── api_client.dart           # Dio wrapper (GET/POST/PUT/PATCH/DELETE)
│   │   └── auth_interceptor.dart     # Auto-attach Bearer token + 401 refresh logic
│   ├── storage/
│   │   └── secure_storage_service.dart  # Encrypted key-value storage
│   ├── theme/
│   │   ├── app_theme.dart            # Light/dark Material 3 themes
│   │   └── app_text_styles.dart      # Typography constants
│   ├── usecases/
│   │   └── usecase.dart              # UseCase<Type, Params> base class
│   └── widgets/
│       ├── empty_state.dart          # Empty-list placeholder
│       ├── error_view.dart           # Error + retry widget
│       └── loading_indicator.dart    # Centered spinner
└── features/
    ├── auth/           # Login, Register, 2FA
    ├── offers/         # Browse & create buy/sell offers
    ├── trades/         # Active trade management + chat
    ├── wallet/         # XMR/BTC wallet balances & transactions
    ├── profile/        # User reputation & feedback
    ├── notifications/  # Push + in-app notifications
    ├── home/           # Bottom-nav shell
    ├── splash/         # Splash / auth-check screen
    └── settings/       # App preferences

android/
├── app/
│   ├── build.gradle              # App-level Gradle (flavors, ProGuard, dexOptions)
│   ├── proguard-rules.pro        # R8/ProGuard keep rules
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/.../MainActivity.kt
├── build.gradle                  # Root Gradle (Kotlin 1.9.22, AGP 8.1.4, GMS 4.4.0)
├── gradle.properties             # JVM args, low-resource Gradle flags
└── settings.gradle               # Plugin management

ios/
├── Podfile                       # CocoaPods (platform :ios, '14.0')
├── Runner/
│   ├── AppDelegate.swift
│   └── Info.plist                # Camera/FaceID/Photo permissions
└── Runner.xcodeproj/
```

Each feature follows the same internal layout:

```
feature/
├── data/
│   ├── datasources/     # Remote data source (API calls)
│   ├── models/          # JSON-serializable models
│   └── repositories/    # Repository implementation
├── domain/
│   ├── entities/        # Pure domain objects
│   ├── repositories/    # Abstract repository interface
│   └── usecases/        # Single-responsibility use cases
└── presentation/
    ├── bloc/            # BLoC + Events + States
    ├── pages/           # Full-screen widgets
    └── widgets/         # Feature-specific components
```

---

## Prerequisites

| Tool | Minimum Version | Install |
|---|---|---|
| **Flutter SDK** | 3.10.0+ | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.0.0+ | Included with Flutter |
| **Android Studio** / **Android SDK** | API 34 | [developer.android.com/studio](https://developer.android.com/studio) |
| **JDK** | 17 | [adoptium.net](https://adoptium.net/) |
| **Xcode** (macOS only) | 15+ | Mac App Store |
| **CocoaPods** (macOS only) | 1.14+ | `sudo gem install cocoapods` |
| **Git** | 2.x | [git-scm.com](https://git-scm.com/) |

Verify your setup:

```bash
flutter doctor -v
```

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. iOS-only — install CocoaPods dependencies

```bash
cd ios
pod install
cd ..
```

### 4. (Optional) Run code generation

If you modify models, entities, or DI configuration:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For low-resource machines, add the flag:

```bash
dart run build_runner build --delete-conflicting-outputs --low-resources-mode
```

---

## Configuration

### API Base URL

The API endpoint is defined in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'https://api.capitalmonero.com/api/v1';
static const String wsUrl  = 'wss://api.capitalmonero.com/ws';
```

To change the backend URL, edit this file directly. No `.env` file is used.

### Android Configuration

**`android/gradle.properties`** — Gradle JVM & build flags:

```properties
org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=384m -XX:+UseSerialGC
org.gradle.parallel=false
org.gradle.workers.max=2
org.gradle.caching=true
org.gradle.configureondemand=true
org.gradle.daemon=false
android.enableJetifier=true
android.useAndroidX=true
kotlin.daemon.jvmargs=-Xmx768m -XX:+UseSerialGC
kotlin.incremental=true
```

**`android/app/build.gradle`** — Key settings:

| Setting | Value |
|---|---|
| `namespace` | `com.capitalmonero.app` |
| `applicationId` | `com.capitalmonero.app` |
| `compileSdk` | 34 |
| `minSdkVersion` | 21 |
| `targetSdkVersion` | 34 |
| `multiDexEnabled` | true |
| `dexOptions.javaMaxHeapSize` | `768m` |
| Kotlin version | 1.9.22 |
| AGP version | 8.1.4 |

**Release build** has R8 minification and resource shrinking enabled via ProGuard rules in `android/app/proguard-rules.pro`.

### iOS Configuration

**`ios/Podfile`** — minimum deployment target:

```ruby
platform :ios, '14.0'
```

**`ios/Runner/Info.plist`** — declared permissions:

| Key | Description |
|---|---|
| `NSCameraUsageDescription` | QR code scanning for crypto addresses |
| `NSFaceIDUsageDescription` | Biometric account security |
| `NSPhotoLibraryUsageDescription` | Share trade screenshots |

### Build YAML (`build.yaml`)

Code generation options for `json_serializable` and `freezed`:

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          any_map: true
          checked: true
          explicit_to_json: true
      freezed:
        options:
          from_json: true
          to_json: true
```

### Localization (`l10n.yaml`)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### Analysis (`analysis_options.yaml`)

Uses `package:flutter_lints/flutter.yaml` as base with additional rules:

- `prefer_const_constructors`, `prefer_const_declarations`
- `avoid_print`, `prefer_single_quotes`
- `prefer_final_locals`, `sort_constructors_first`
- Generated files excluded: `*.g.dart`, `*.freezed.dart`, `*.config.dart`

---

## Build Commands

### Run in Debug Mode

```bash
# Android (production flavor)
flutter run --flavor production -t lib/main.dart

# iOS
flutter run -t lib/main.dart
```

### Build Debug APK

```bash
flutter build apk --debug --flavor production -t lib/main.dart
```

Output: `build/app/outputs/flutter-apk/app-production-debug.apk`

### Build Release APK

```bash
flutter build apk --release --flavor production -t lib/main.dart
```

Output: `build/app/outputs/flutter-apk/app-production-release.apk`

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release --flavor production -t lib/main.dart
```

Output: `build/app/outputs/bundle/productionRelease/app-production-release.aab`

### Build F-Droid Flavor APK

```bash
flutter build apk --release --flavor fdroid -t lib/main.dart
```

### Build iOS (Release, No Code-Sign)

```bash
flutter build ios --release --no-codesign -t lib/main.dart
```

### Build iOS (Archive for App Store)

```bash
flutter build ipa --release -t lib/main.dart
```

### Clean Build Artifacts

```bash
flutter clean
flutter pub get
```

### Deploy to Physical Android Device via ADB

```bash
# List connected devices
adb devices -l

# Install debug APK
adb install -r build/app/outputs/flutter-apk/app-production-debug.apk

# Launch the app
adb shell am start -n com.capitalmonero.app/.MainActivity
```

---

## Code Generation

This project uses `build_runner` with `json_serializable`, `freezed`, `drift_dev`, `injectable_generator`, and `copy_with_extension_gen`.

### Full rebuild

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Watch mode (re-generates on file changes)

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Low-resource mode

For machines with limited RAM (≤ 4 GB):

```bash
dart run build_runner build --delete-conflicting-outputs --low-resources-mode
```

Generated file patterns (excluded from version control via `.gitignore`):

- `*.g.dart` — `json_serializable` / `drift`
- `*.freezed.dart` — `freezed`
- `*.config.dart` — `injectable`
- `*.mocks.dart` — `mockito`

---

## Testing

### Run all tests

```bash
flutter test
```

### Run tests with coverage

```bash
flutter test --coverage
```

### Run a specific test file

```bash
flutter test test/features/auth/domain/usecases/login_usecase_test.dart
```

### Run tests without fetching packages (faster re-runs)

```bash
flutter test --no-pub
```

---

## Linting & Analysis

### Analyze code

```bash
flutter analyze
```

### Analyze without failing on info-level issues

```bash
flutter analyze --no-fatal-infos
```

### Format code

```bash
dart format lib/ test/
```

### Check formatting without modifying files

```bash
dart format --set-exit-if-changed lib/ test/
```

---

## Low-Resource Machine Settings

This project is configured for development on resource-constrained hardware. Before running build commands, set these environment variables:

### Windows (CMD)

```cmd
SET DART_VM_OPTIONS=--old_gen_heap_size=512
SET GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
SET JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC
```

### Windows (PowerShell)

```powershell
$env:DART_VM_OPTIONS = "--old_gen_heap_size=512"
$env:GRADLE_OPTS = "-Xmx512m -Dfile.encoding=UTF-8"
$env:JAVA_TOOL_OPTIONS = "-Xmx768m -XX:+UseSerialGC"
```

### Linux / macOS

```bash
export DART_VM_OPTIONS="--old_gen_heap_size=512"
export GRADLE_OPTS="-Xmx512m -Dfile.encoding=UTF-8"
export JAVA_TOOL_OPTIONS="-Xmx768m -XX:+UseSerialGC"
```

**Key Gradle settings already applied** in `android/gradle.properties`:

| Setting | Value | Why |
|---|---|---|
| `org.gradle.jvmargs` | `-Xmx1536m -XX:MaxMetaspaceSize=384m -XX:+UseSerialGC` | Cap Gradle JVM heap, use serial GC |
| `org.gradle.daemon` | `false` | No persistent daemon = no idle RAM drain |
| `org.gradle.parallel` | `false` | Avoid parallel task memory spikes |
| `org.gradle.workers.max` | `2` | Limit concurrent workers |
| `kotlin.daemon.jvmargs` | `-Xmx768m -XX:+UseSerialGC` | Cap Kotlin compiler heap |
| `dexOptions.javaMaxHeapSize` | `768m` | Cap R8/D8 dex compiler heap |

**Tip:** Always use `--no-daemon` with Gradle commands to avoid leftover JVM processes:

```bash
# Direct Gradle usage (if needed)
cd android && ./gradlew assembleProductionDebug --no-daemon
```

---

## API Endpoints

Base URL: `https://api.capitalmonero.com/api/v1`

| Category | Endpoint | Method |
|---|---|---|
| **Auth** | `/auth/login` | POST |
| | `/auth/register` | POST |
| | `/auth/logout` | POST |
| | `/auth/refresh` | POST |
| | `/auth/verify-otp` | POST |
| | `/auth/2fa/enable` | POST |
| | `/auth/2fa/disable` | POST |
| **Offers** | `/offers` | GET / POST |
| | `/offers/my` | GET |
| | `/offers/{id}` | GET / PUT / DELETE |
| **Trades** | `/trades` | GET / POST |
| | `/trades/{id}` | GET |
| | `/trades/{id}/messages` | GET / POST |
| | `/trades/{id}/release` | POST |
| | `/trades/{id}/cancel` | POST |
| | `/trades/{id}/dispute` | POST |
| **Wallet** | `/wallet/balances` | GET |
| | `/wallet/deposit` | POST |
| | `/wallet/withdraw` | POST |
| | `/wallet/transactions` | GET |
| **Profile** | `/profile` | GET / PUT |
| | `/users/{username}` | GET |
| | `/users/{username}/feedback` | GET / POST |
| **Notifications** | `/notifications` | GET |
| | `/notifications/{id}/read` | POST |
| **Search** | `/search` | GET |
| | `/payment-methods` | GET |
| | `/currencies` | GET |
| | `/countries` | GET |

---

## Flavors

Two product flavors are configured in `android/app/build.gradle`:

| Flavor | Purpose | Build Command |
|---|---|---|
| `production` | Google Play / standard distribution | `flutter build apk --flavor production` |
| `fdroid` | F-Droid (no Google Services) | `flutter build apk --flavor fdroid` |

Both use the `distribution` flavor dimension.

---

## Dependencies

### Runtime

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^8.1.3 | BLoC state management |
| `go_router` | ^13.0.0 | Declarative routing |
| `dio` | ^5.4.0 | HTTP client |
| `get_it` | ^7.6.4 | Service locator DI |
| `injectable` | ^2.3.2 | DI code generation annotations |
| `flutter_secure_storage` | ^9.0.0 | Encrypted key-value store |
| `drift` | ^2.14.0 | SQLite ORM |
| `sqlite3_flutter_libs` | ^0.5.18 | SQLite native bindings |
| `dartz` | ^0.10.1 | Functional types (Either) |
| `equatable` | ^2.0.5 | Value equality |
| `json_annotation` | ^4.8.1 | JSON serialization annotations |
| `freezed_annotation` | ^2.4.1 | Immutable model annotations |
| `firebase_core` | ^2.24.2 | Firebase initialization |
| `firebase_messaging` | ^14.7.9 | Push notifications |
| `pointycastle` | ^3.7.4 | Cryptography (PGP) |
| `bip39` | ^1.0.6 | Mnemonic word generation |
| `encrypt` | ^5.0.3 | AES encryption |
| `local_auth` | ^2.1.7 | Biometric authentication |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `mobile_scanner` | ^3.5.5 | QR code scanning |
| `cached_network_image` | ^3.3.0 | Image caching |
| `connectivity_plus` | ^5.0.2 | Network state |
| `path_provider` | ^2.1.1 | File system paths |
| `image_picker` | ^1.0.5 | Camera/gallery access |
| `permission_handler` | ^11.1.0 | Runtime permissions |
| `url_launcher` | ^6.2.1 | Open URLs |
| `share_plus` | ^7.2.1 | Share content |
| `timeago` | ^3.6.0 | Relative time formatting |
| `google_fonts` | ^6.1.0 | Google Fonts integration |
| `flutter_svg` | ^2.0.9 | SVG rendering |
| `shimmer` | ^3.0.0 | Loading shimmer effects |
| `pull_to_refresh` | ^2.0.0 | Pull-to-refresh |
| `logger` | ^2.0.2 | Structured logging |
| `uuid` | ^4.2.1 | UUID generation |
| `intl` | ^0.19.0 | Internationalization |
| `package_info_plus` | ^5.0.1 | App version info |
| `device_info_plus` | ^9.1.1 | Device metadata |
| `copy_with_extension` | ^5.0.4 | copyWith generation annotations |

### Dev / Build

| Package | Version | Purpose |
|---|---|---|
| `flutter_lints` | ^3.0.1 | Lint rules |
| `build_runner` | ^2.4.7 | Code generation runner |
| `json_serializable` | ^6.7.1 | JSON serialization codegen |
| `freezed` | ^2.4.5 | Immutable model codegen |
| `injectable_generator` | ^2.4.1 | DI codegen |
| `drift_dev` | ^2.14.0 | Drift (SQLite) codegen |
| `mockito` | ^5.4.3 | Mock generation for tests |
| `bloc_test` | ^9.1.5 | BLoC testing utilities |
| `copy_with_extension_gen` | ^5.0.4 | copyWith codegen |

---

## License

Proprietary. All rights reserved.
