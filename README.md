# app_builder — Autonomous Flutter/Dart Mobile App Build System

> **Zero-touch, fully autonomous build pipeline** — takes a Flutter/Dart app
> ecosystem (multiple companion repos) and produces signed Android AAB, Android
> APK, and iOS IPA artifacts ready for upload to Google Play Store and Apple
> App Store. Every single file is tracked; the build fails if anything is
> unaccounted for.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Architecture](#architecture)
7. [Output Files](#output-files)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Overview

`app_builder.py` is a fully autonomous Python build system designed for the
**AgoraDesk / LocalMonero** Flutter ecosystem (and any similar multi-repo
Flutter project). It:

| Step | What happens |
|------|--------------|
| 1 | Validates the host environment (Flutter SDK, Android SDK, Xcode, etc.) |
| 2 | Clones **all** source repos (main app + dependencies + tools) |
| 3 | Builds a **SHA-256 file manifest** — every file tracked, none skipped |
| 4 | Rewrites `pubspec.yaml` to use local `path:` references for companion packages |
| 5 | Runs `flutter pub get` to resolve all dependencies |
| 6 | Runs code generation (`build_runner`, ARB/locale tools, custom scripts) |
| 7 | Validates and processes assets (icons, splash, fonts, images) |
| 8 | Configures `android/app/build.gradle`, `AndroidManifest.xml`, signing |
| 9 | Builds signed Android **AAB** (Google Play) and **APK** (direct install) |
| 10 | Configures Xcode project, runs `pod install` (macOS only) |
| 11 | Builds signed iOS **IPA** (App Store) |
| 12 | Generates Fastlane config for automated store deployment (optional) |
| 13 | Runs post-build validation — verifies 100% file coverage + artifact integrity |
| 14 | Produces a **full HTML + JSON build report** |

---

## Prerequisites

### All platforms (required)

| Tool | Minimum version | Install |
|------|----------------|---------|
| Python | 3.9 | <https://www.python.org/downloads/> |
| Git | any | <https://git-scm.com/downloads> |
| Flutter SDK | 3.10.0 | <https://flutter.dev/docs/get-started/install> |
| Java JDK | 11 | <https://adoptium.net/> |
| Android SDK | API 34 | [Android Studio](https://developer.android.com/studio) |

### macOS only (for iOS builds)

| Tool | Minimum version | Install |
|------|----------------|---------|
| Xcode | 14.0 | Mac App Store |
| CocoaPods | 1.12 | `sudo gem install cocoapods` |

### Optional (for automated store deployment)

| Tool | Install |
|------|---------|
| Ruby | `brew install ruby` / `apt install ruby` |
| Fastlane | `gem install fastlane` |

---

## Installation

```bash
# 1. Clone this repo
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Verify your environment
python app_builder.py --skip-validation --skip-android --skip-ios --config config.yaml
```

---

## Configuration

All settings live in a single YAML file. The default `config.yaml` is
pre-configured for the AgoraDesk ecosystem. Copy and edit it for your own
project:

```bash
cp config.yaml my_app.yaml
```

### Key sections

#### `repos` — Source repositories

```yaml
repos:
  - url: https://github.com/MyOrg/my-flutter-app
    branch: main
    type: main_app          # main_app | dependency | tool
    local_name: my-flutter-app

  - url: https://github.com/MyOrg/my-flutter-widget
    branch: main
    type: dependency
    local_name: my-flutter-widget
    package_name: my_flutter_widget  # must match pubspec.yaml name
```

- `type: main_app` — the Flutter project to build (exactly one required)
- `type: dependency` — local Flutter packages; wired via `path:` in pubspec.yaml
- `type: tool` — Dart CLI tools used during the build (e.g. locale generators)

#### `app` — App metadata

```yaml
app:
  name: MyApp
  bundle_id: com.mycompany.myapp
  version: 2.3.1
  build_number: 42
```

#### `android` — Android configuration

```yaml
android:
  min_sdk_version: 21
  target_sdk_version: 34
  compile_sdk_version: 34
  keystore_path: /path/to/release.jks
  keystore_alias: my_key
  keystore_password: "secret"
  key_password: "secret"
  extra_permissions:
    - android.permission.INTERNET
    - android.permission.CAMERA
  enable_proguard: false
  enable_multidex: true
```

> **Signing:** Leave `keystore_path` empty for an unsigned build. The AAB/APK
> will still be produced but cannot be uploaded to Google Play without signing.

#### `ios` — iOS configuration

```yaml
ios:
  team_id: ABCDE12345
  provisioning_profile: "MyApp Distribution"
  signing_identity: "iPhone Distribution: My Company (ABCDE12345)"
  deployment_target: "13.0"
  capabilities:
    - push_notifications
  export_method: app-store   # app-store | ad-hoc | enterprise | development
```

> **macOS required:** iOS builds are automatically skipped on Linux/Windows.
> All Xcode configuration files are generated so you can run the build on a
> Mac afterwards.

#### `build` — Build options

```yaml
build:
  mode: release              # release | debug | profile
  output_dir: ./output
  clean_before_build: true
  build_android: true
  build_ios: true
  dart_defines:
    SOME_FLAG: "true"
  extra_flutter_flags: []
```

#### `fastlane` — Automated store deployment

```yaml
fastlane:
  enabled: true
  android_package: com.mycompany.myapp
  ios_app_identifier: com.mycompany.myapp
  google_play_json_key: /path/to/google-play-key.json
  app_store_connect_key_id: ABCDE12345
  app_store_connect_issuer_id: 12345678-1234-1234-1234-123456789012
  app_store_connect_key_filepath: /path/to/AuthKey_ABCDE12345.p8
```

---

## Usage

### Basic — build everything

```bash
python app_builder.py --config config.yaml
```

### Skip iOS (Linux / Windows)

```bash
python app_builder.py --config config.yaml --skip-ios
```

### Skip Android

```bash
python app_builder.py --config config.yaml --skip-android
```

### Custom output directory

```bash
python app_builder.py --config config.yaml --output-dir /tmp/my-build
```

### Verbose logging

```bash
python app_builder.py --config config.yaml --log-level DEBUG
```

### Skip environment validation (not recommended)

```bash
python app_builder.py --config config.yaml --skip-validation
```

### All options

```
usage: app_builder [-h] [--config FILE] [--output-dir DIR]
                   [--skip-android] [--skip-ios]
                   [--skip-validation] [--no-clean]
                   [--log-level {DEBUG,INFO,WARNING,ERROR}]
```

---

## Architecture

```
app_builder.py              ← Main entry point (CLI + orchestration)
config.yaml                 ← Configuration template
requirements.txt            ← Python dependencies
README.md                   ← This file

lib/
  __init__.py
  environment_setup.py      ← Detect/validate Flutter, Android SDK, Xcode …
  repo_manager.py           ← Clone repos, SHA-256 file manifest, zero-skip
  dependency_resolver.py    ← Rewrite pubspec.yaml, run flutter pub get
  code_generator.py         ← build_runner, ARB generation, custom scripts
  android_builder.py        ← Configure Gradle/Manifest, build AAB + APK
  ios_builder.py            ← Configure Xcode, pod install, build IPA
  asset_processor.py        ← Validate icons, splash, referenced assets
  fastlane_manager.py       ← Generate Fastlane Fastfile / Appfile
  validator.py              ← Pre/post build validation, artifact checks
  report_generator.py       ← HTML + JSON build reports (Jinja2)

templates/
  __init__.py
  report.html               ← Jinja2 HTML report template
```

---

## Output Files

After a successful build, `output/` (or your `--output-dir`) contains:

```
output/
  build.log                 ← Full build log
  file_manifest.json        ← SHA-256 manifest of every file from every repo
  build_report.html         ← Full HTML build report (open in a browser)
  build_report.json         ← Machine-readable JSON report
  android/
    app-release.aab         ← Signed Android App Bundle (Google Play)
    app-release.apk         ← Signed APK (direct install / testing)
  ios/
    Runner.ipa              ← Signed iOS IPA (App Store Connect)
```

---

## Troubleshooting

### `flutter: command not found`

Add the Flutter SDK `bin/` directory to your `PATH`:

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

### `Android SDK not found`

Set `ANDROID_SDK_ROOT` or `ANDROID_HOME`:

```bash
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
```

### `pod install` fails

```bash
gem install cocoapods
pod repo update
```

### `flutter pub get` fails for local dependencies

Ensure the `package_name` in `config.yaml` exactly matches the `name:` field
in the dependency's `pubspec.yaml`.

### Build manifest mismatch

The build will abort if `file_manifest.json` count differs from the actual
filesystem count. This typically means:

- A `.git` directory contains unexpected non-hidden files (rare)
- A concurrent process created / deleted files during the build

Run with `--log-level DEBUG` for full detail.

### iOS build on non-macOS

iOS builds are automatically skipped. The script still generates:
- `ios/ExportOptions.plist` — export configuration
- Patched `ios/Runner.xcodeproj/project.pbxproj` — Xcode settings

Transfer the cloned/configured workspace to a Mac and run:

```bash
cd repos/agoradesk-app-foss
pod install --project-directory=ios
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

---

## FAQ

**Q: Does this work with apps other than AgoraDesk?**
Yes. Edit `config.yaml` to point to your repos and set your app metadata.
The only requirement is that the main app is a Flutter project with a
`pubspec.yaml`.

**Q: Can I run it multiple times (idempotency)?**
Yes. The script pulls the latest changes if a repo is already cloned.
Enable `build.clean_before_build: true` (default) to ensure a clean build.

**Q: What if a dependency is not on GitHub?**
Any Git URL is supported. Set `url:` to any accessible remote.

**Q: Does it handle private repos?**
Yes — Git uses your existing SSH keys or HTTPS credentials. Ensure your
environment has access to the private repos before running.

**Q: Can I use it in CI/CD?**
Yes. The script returns exit code `0` on success and `1` on failure, and
writes a full log to `output/build.log`. Example GitHub Actions step:

```yaml
- name: Build Flutter App
  run: python app_builder.py --config config.yaml --skip-ios
```

**Q: How do I sign the Android APK/AAB?**
Create a keystore with `keytool`, then set `android.keystore_path`,
`android.keystore_alias`, and passwords in `config.yaml`.

```bash
keytool -genkey -v -keystore release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my_key
```
