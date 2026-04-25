# CapitalMonero

> P2P Monero/Bitcoin trading — private, open, uncensorable.

[![Build](https://img.shields.io/github/actions/workflow/status/bitbybit91/app-builder/ci.yml?branch=main&label=build)](https://github.com/bitbybit91/app-builder/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x (stable channel) |
| Dart | 3.x |
| JDK | 17 (Eclipse Temurin recommended) |
| Android SDK | API 34 (build-tools 34.x) |
| ADB | Bundled with Android SDK platform-tools |
| Physical Android device | API 21+ — emulators **not** supported |

---

## Quick Start

```bash
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder
flutter pub get

# Connect a physical Android device (USB debugging on), then:
flutter run --flavor production -t lib/main.dart
```

---

## Low-Spec Build Tips

The target dev machine is a 4 GB RAM Windows 10 laptop. Use the memory-constrained
environment variables below **before** building:

```bat
set DART_VM_OPTIONS=--old_gen_heap_size=512
set GRADLE_OPTS=-Xmx512m -Dfile.encoding=UTF-8
set JAVA_TOOL_OPTIONS=-Xmx768m -XX:+UseSerialGC
```

Additional tips:

- Run `gradlew --no-daemon` or set `org.gradle.daemon=false` (already set in `android/gradle.properties`).
- Kill zombie Java/Dart processes between builds: `taskkill /F /IM java.exe`.
- Use the helper scripts in `scripts/`:
  - `local-build.bat` — Windows CMD wrapper
  - `local-build.ps1` — PowerShell wrapper

---

## Physical Device Deployment

1. Enable **Developer Options** on your Android device.
2. Enable **USB Debugging**.
3. Connect via USB and confirm the RSA fingerprint prompt.
4. Verify the device is listed: `adb devices`
5. Build and install a debug APK:
   ```bash
   flutter build apk --flavor production --debug
   adb install -r build/app/outputs/flutter-apk/app-production-debug.apk
   ```
6. Or deploy directly with Flutter:
   ```bash
   flutter run --flavor production
   ```

---

## iOS CI Note

iOS builds require macOS and Xcode 15+. They are **not** supported on the low-spec Windows
dev machine. iOS artifacts are produced exclusively by the GitHub Actions workflow defined in
`.github/workflows/ci.yml` on a `macos-latest` runner.

```bash
# iOS build (CI only)
flutter build ipa --flavor production --release
```

---

## Build Flavors

| Flavor | App ID | Firebase | Notes |
|--------|--------|----------|-------|
| `production` | `com.capitalmonero.app` | ✅ | Play Store / App Store release |
| `staging` | `com.capitalmonero.app.staging` | ✅ | Internal testing |
| `fdroid` | `com.capitalmonero.app.fdroid` | ❌ | No proprietary SDKs; F-Droid compliant |

The `fdroid` flavor sets `FDROID_BUILD=true` as a `BuildConfig` field. All Firebase and
Google-proprietary SDK usage must be guarded with:

```dart
const bool isFdroid = bool.fromEnvironment('FDROID_BUILD');
if (!isFdroid) { /* Firebase call */ }
```

---

## Publishing

### Google Play Store (AAB)
```bash
flutter build appbundle --flavor production --release
```
Upload `build/app/outputs/bundle/productionRelease/app-production-release.aab` to the Play Console.

### Apple App Store (IPA via CI)
IPA generation runs on the macOS CI runner. The GitHub Actions workflow uploads the artifact
for manual submission via Transporter or Xcode Organizer.

### F-Droid
Include a `.fdroid.yml` metadata file in the repo root. The `fdroid` flavor must pass
`fdroid build` checks — no proprietary SDKs, no Firebase, no closed blobs.

### Samsung Galaxy Store / Amazon Appstore
Both stores accept standard APKs. Build with:
```bash
flutter build apk --flavor production --release --split-per-abi
```

---

## Signing

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 4096 \
     -validity 10000 -alias capitalmonero
   ```
2. Create `android/key.properties` (never commit this file):
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=capitalmonero
   storeFile=../release.jks
   ```
3. The `android/app/build.gradle` reads `key.properties` automatically.
   If the file is absent (e.g., on CI without secrets), the build falls back to debug signing.

---

## Architecture Diagram

```
┌──────────────────────────────────────────────┐
│                Presentation Layer             │
│  Flutter Widgets · BLoC · GoRouter · Themes  │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│               Application Layer              │
│   Use Cases · BLoC Events/States · Mappers   │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│                 Domain Layer                  │
│  Entities · Repository Interfaces · Failures  │
└────────────────────┬─────────────────────────┘
                     │
┌────────────────────▼─────────────────────────┐
│               Data / Infrastructure           │
│  Repository Impls · Drift DB · Dio · Secure  │
│  Storage · Firebase · XMR RPC · Biometrics   │
└──────────────────────────────────────────────┘
```

**Directory structure:**

```
lib/
├── main.dart
├── app/            # App shell, router, theme, DI bootstrap
├── core/           # Errors, network, security, constants, utils
└── features/
    ├── auth/       # Login, biometric, wallet unlock
    ├── trade/      # Trade listing, creation, chat
    ├── wallet/     # Monero/Bitcoin wallet management
    └── settings/   # App preferences, notifications
```

---

## Contributing

1. Fork the repository and create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Branch naming conventions:
   - `feature/<description>` — new functionality
   - `fix/<description>` — bug fixes
   - `chore/<description>` — maintenance, dependency updates
3. **PR Checklist**
   - [ ] `flutter analyze` passes with zero warnings
   - [ ] All existing tests pass (`flutter test`)
   - [ ] New business logic is unit-tested
   - [ ] No `print()` statements
   - [ ] No `// TODO` or `// FIXME` left in submitted code
   - [ ] `CHANGELOG.md` updated under `[Unreleased]`
4. Open a pull request against `main` with a clear description of changes.

---

## License

[MIT](LICENSE) © 2026 CapitalMonero Contributors
