# Magoradesk — app-builder

Flutter Android application, automatically built and signed via Codemagic CI/CD.

---

## Quick start (local)

```bash
# 1. Install Flutter 3.22.2 stable: https://docs.flutter.dev/get-started/install
flutter pub get
flutter run          # debug on device/emulator
flutter build apk    # debug APK
```

---

## Release Build via Codemagic

Automated, signed release APKs are produced by Codemagic on every push to
`main` or on tags matching `v*.*.*` — **zero manual steps required**.

### How it works

1. Codemagic reads [`codemagic.yaml`](codemagic.yaml) at the repo root.
2. The `flutter-release-apk` workflow runs:
   - `python3 scripts/setup_signing.py` — decodes the keystore from a
     Codemagic secret env var and writes `android/key.properties`.
   - `flutter pub get` → `flutter analyze` → `flutter test` (non-blocking).
   - `flutter build apk --release --split-per-abi` + universal APK.
3. Signed APKs and the R8 mapping file are uploaded as artifacts.
4. Build result notification sent to the configured email address.

### Setup (one-time)

See **[CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md)** for step-by-step instructions,
including how to generate a keystore, encode it in base64, and add the required
environment variables in the Codemagic UI.

### Required environment variables (Codemagic UI)

| Variable | Purpose |
|---|---|
| `CM_KEYSTORE` | Base64-encoded JKS keystore |
| `CM_KEYSTORE_PASSWORD` | Keystore store password |
| `CM_KEY_ALIAS` | Signing key alias |
| `CM_KEY_PASSWORD` | Signing key password |
| `CM_NOTIFY_EMAIL` | (optional) Email for build notifications |

### Trigger a release

```bash
# Push to main
git push origin main

# Or create a version tag
git tag v1.0.0 && git push origin v1.0.0
```

### Verify locally

```bash
python3 scripts/verify_release_ready.py
```

---

## Project structure

```
├── lib/                    Dart source files
│   └── main.dart
├── android/                Android project
│   ├── app/
│   │   ├── build.gradle    App-level Gradle build (signing wired)
│   │   ├── proguard-rules.pro
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/magoradesk/app/MainActivity.kt
│   ├── key.properties.template   Template for local signing
│   └── build.gradle        Top-level Gradle build
├── scripts/
│   ├── setup_signing.py    CI signing setup (run by Codemagic pre-build)
│   └── verify_release_ready.py   Pre-flight readiness check
├── codemagic.yaml          Codemagic CI/CD pipeline
├── CODEMAGIC_SETUP.md      Detailed setup guide
└── pubspec.yaml            Flutter project manifest
```

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/setup_signing.py` | Decodes keystore, writes `key.properties` |
| `scripts/verify_release_ready.py` | Validates everything is ready for release |
