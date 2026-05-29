# CapitalMonero

CapitalMonero is a cross-platform Flutter application implementing a
peer-to-peer cryptocurrency marketplace for **Monero (XMR)** and
**Bitcoin (BTC)**, inspired by AgoraDesk / LocalMonero.

* Buy / sell offers (online & local cash trades)
* Bank transfer, SEPA, Revolut, Wise, cash and crypto payment methods
* Automated escrow with three-way dispute resolution
* PGP-encrypted trade chat and direct messages
* TOTP two-factor authentication and BIP39 recovery phrase
* On-device Monero & Bitcoin wallets with QR deposit codes
* 12 fully translated languages (`en, es, fr, de, ko, zh, ja, pt, th, sv, da, no`)
* Clean architecture (data / domain / presentation) backed by
  [`flutter_bloc`](https://pub.dev/packages/flutter_bloc)
* Either-style error handling via [`dartz`](https://pub.dev/packages/dartz)
* Three Android product flavors: `production`, `staging`, `fdroid`
  (the F-Droid build excludes Firebase entirely)

## Project identity

| Field             | Value                       |
|-------------------|-----------------------------|
| App name          | CapitalMonero               |
| Android package   | `com.capitalmonero.app`     |
| iOS bundle ID     | `com.capitalmonero.app`     |
| Min Android SDK   | 21                          |
| Target SDK        | 34                          |
| iOS deployment    | 14.0                        |
| Flutter           | latest stable 3.x           |

## Building on Low-Specification Hardware

This project was deliberately configured to build on a developer machine
with as little as **4 GB RAM** and a **dual-core 1 GHz CPU** running
Windows 10 x64 (reference machine: DESKTOP-P43AJUM, AMD E1-2100). The
following knobs are pre-baked into the repository:

* `android/gradle.properties` caps the Gradle JVM at 1.5 GB and uses the
  serial GC; `parallel`, `daemon` and `configureondemand` are all tuned for
  a 2-core / 4 GB host.
* `android/app/build.gradle` clamps `dexOptions.javaMaxHeapSize` to 768 MB
  so R8 / proguard finish under tight RAM.
* `flutter_settings.bat` exports memory-friendly `DART_VM_OPTIONS`,
  `GRADLE_OPTS` and `JAVA_TOOL_OPTIONS`.
* `.vscode/settings.json` limits the Dart analyzer to a single worker and
  disables minimap / UI guides / large file watchers.
* The provided `.bat` and `.ps1` scripts always pass `--no-daemon` and
  `--no-pub` so no Gradle daemon hangs around between runs.

### Recommended workflow

1. Close **all** other applications before building (browser, IDE, etc.).
2. Use VS Code, not Android Studio / IntelliJ — those IDEs alone consume
   2 GB+ on this hardware.
3. Plug a real Android phone in via USB. Emulators **do not** fit on
   this host.
4. iOS builds happen exclusively on the GitHub Actions `macos-latest`
   runner (see `.github/workflows/build.yml`).
5. Expected wall-clock times on the reference machine:

   | Step                              | Time          |
   |-----------------------------------|---------------|
   | `flutter pub get`                 | 2–3 minutes   |
   | `dart run build_runner build …`   | 5–10 minutes  |
   | `flutter build apk --debug`       | 15–25 minutes |
   | `flutter build apk --release`     | 25–45 minutes |
   | `flutter test`                    | 5–15 minutes  |

   Run `flutter clean` between flavor switches to avoid OOM errors.

## Prerequisites (Windows 10 x64)

* Flutter SDK on `%PATH%` (`flutter --version` works)
* JDK 17 (Temurin) with `%JAVA_HOME%` set
* Android SDK (Platform 34, Build-Tools 34) with `%ANDROID_HOME%` set
* `adb` reachable from `%PATH%`
* (Optional) Visual Studio Code with the Flutter & Dart extensions

Verify everything with:

```cmd
setup-dev-env.bat
```

## Clone, configure and build

```cmd
git clone https://github.com/capitalmonero/capitalmonero.git
cd capitalmonero

REM 1. Memory-safe environment.
call flutter_settings.bat

REM 2. Resolve dependencies.
flutter pub get

REM 3. Generate localizations.
flutter gen-l10n

REM 4. (Optional) run code generation if you add codegen models.
dart run build_runner build --delete-conflicting-outputs --low-resources-mode

REM 5. Build a debug APK and deploy to a USB device.
deploy-device.bat
```

The interactive menu launcher is `local-build.bat` (or `local-build.ps1`
which adds elapsed-time tracking, memory monitoring, orphan-process
cleanup, and colourised success/failure logging).

### Code signing

Copy `android/key.properties.example` to `android/key.properties` and
edit. Generate a release keystore with JDK 17:

```cmd
keytool -genkey -v -keystore C:\keys\capitalmonero-release.jks ^
    -alias capitalmonero-release -keyalg RSA -keysize 4096 -validity 10000
```

Note: `android/key.properties` and `*.jks` files are git-ignored.

iOS signing is managed via Fastlane Match on CI — see
`ios/fastlane/Fastfile` / `Matchfile`. The Windows host cannot sign or
build iOS.

### Tests and lint

```cmd
flutter analyze --no-pub
flutter test --no-pub --reporter compact
```

The repository ships with 30+ unit/BLoC tests across `test/` covering the
auth, trading, wallet and notifications BLoCs, mnemonic and TOTP services,
the trade-state machine, and form validators.

## Publishing

| Store             | Artifact                            | Recipe                                                                |
|-------------------|-------------------------------------|------------------------------------------------------------------------|
| Google Play       | AAB                                 | `flutter build appbundle --release --flavor production` (CI uploads via `fastlane deploy_internal`) |
| Apple App Store   | IPA (built on macOS CI only)        | `flutter build ipa --release` then `fastlane release` or `fastlane beta` |
| F-Droid           | APK from `fdroid` flavor            | `flutter build apk --release --flavor fdroid` (also driven by `.fdroid.yml`) |
| Samsung Galaxy    | APK or AAB from `production` flavor | `flutter build apk --release --flavor production`                     |
| Amazon Appstore   | APK only                            | `flutter build apk --release --flavor production`                     |

CI (`.github/workflows/build.yml`):

* `test` — analyze + tests on Ubuntu
* `build-android` — three flavor APKs + AAB on Ubuntu
* `build-ios`     — IPA on `macos-latest`

## Directory layout

```
lib/
├── main.dart
├── app/                  # MaterialApp wrapper, GoRouter, theme
├── core/                 # errors, network (dio), security (PGP/TOTP/...)
├── features/
│   ├── auth/             # data/, domain/, presentation/ (+ BLoCs)
│   ├── trading/          # offers, trades, escrow, dispute
│   ├── wallet/           # XMR/BTC balances, deposit, withdraw
│   ├── messaging/        # direct messages with PGP toggle
│   ├── profile/          # public profile, reputation, edit
│   ├── search/           # offer search & filtering
│   ├── notifications/    # in-app notification centre
│   └── admin/            # user moderation, dispute resolution
├── l10n/                 # 12 ARB files + flutter-generated bindings
└── shared/               # MainShell, extensions, shared widgets

test/                     # unit + BLoC tests (30+ cases)
android/                  # build.gradle (3 flavors), gradle.properties, signing
ios/                      # Info.plist (cam/biometrics/encryption), Podfile
.github/workflows/        # build & test pipeline
fastlane/                 # store metadata (English)
android/fastlane/         # Play Store deploy lanes
ios/fastlane/             # App Store / TestFlight lanes
```

## Architecture notes

* **State management** — every BLoC is wired through `get_it` in
  `lib/core/di/injection.dart`; presentation widgets pull from
  `MultiBlocProvider` in `app/app.dart`.
* **Networking** — `core/network/api_client.dart` wraps Dio with bearer
  auth + structured `Either<Failure, T>` error mapping.
* **Security** — `core/security/` houses an RSA-OAEP/SHA256 PGP service,
  RFC 6238 TOTP, a `SessionManager` that locks the app after 1 hour of
  inactivity, biometric/PIN unlock helpers, and BIP39 mnemonic generation
  for account recovery.
* **Data** — repositories are coded against `*DataSource` abstractions.
  The bundled in-memory data sources mean the app boots end-to-end on a
  brand-new phone with no backend, which is essential because we cannot
  emulate this app on the reference Windows host.
* **Errors** — every repository returns `Either<Failure, T>`; BLoCs map
  the `Failure` subclasses to user-visible states (`*Error`,
  `AuthFailureState`, …).

## License

AGPL-3.0-or-later. See `LICENSE` (TODO).
