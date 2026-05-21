# CapitalMonero

A free and open-source Monero cryptocurrency utility app for Android.

- **FOSS only** — no Google Play Services, Firebase, AdMob, or Crashlytics
- **Jetpack Compose** UI with Material3
- **minSdk 26** (Android 8.0+), targetSdk 34
- **Kotlin 1.9.24**, AGP 8.4.2, Gradle 8.8

---

## Requirements

| Tool | Version |
|------|---------|
| JDK | 17+ |
| Android Studio | Hedgehog (2023.1.1) or newer |
| Gradle | 8.8 (via wrapper) |
| Android SDK | compileSdk 34, minSdk 26 |

---

## Getting Started

```bash
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder
./gradlew assembleDebug
```

Install on a connected device or emulator:

```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## Project Structure

```
app-builder/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/capitalmonero/app/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   └── ui/
│   │   │   │       ├── CapitalMoneroApp.kt      # Navigation graph
│   │   │   │       ├── home/
│   │   │   │       │   ├── HomeScreen.kt
│   │   │   │       │   └── HomeViewModel.kt
│   │   │   │       ├── about/
│   │   │   │       │   └── AboutScreen.kt
│   │   │   │       └── theme/
│   │   │   │           ├── Theme.kt
│   │   │   │           └── Typography.kt
│   │   │   └── res/
│   │   ├── test/                                # Unit tests
│   │   └── androidTest/                         # Instrumented tests
│   ├── build.gradle.kts
│   └── proguard-rules.pro
├── gradle/
│   ├── libs.versions.toml                       # Version catalog
│   └── wrapper/
├── scripts/
│   ├── setup_signing.py                         # CI signing setup
│   └── verify_release_ready.py                  # Pre-flight checks
├── metadata/
│   └── com.capitalmonero.app.yml                # F-Droid metadata
├── codemagic.yaml                               # Codemagic CI/CD
└── .github/workflows/
    ├── android-ci.yml                           # GitHub Actions CI
    └── fdroid-check.yml                         # F-Droid lint
```

---

## Building

### Debug build

```bash
./gradlew assembleDebug
```

### Release build (requires signing)

1. Copy the signing template:
   ```bash
   cp key.properties.template keys.properties
   ```
2. Edit `keys.properties` with your keystore details (never commit this file).
3. Build:
   ```bash
   ./gradlew assembleRelease bundleRelease
   ```

---

## Signing

### Local signing

1. Generate a keystore (one-time):
   ```bash
   keytool -genkey -v -keystore release.keystore \
     -alias capitalmonero -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Fill in `keys.properties`:
   ```properties
   storeFile=../release.keystore
   storePassword=YOUR_STORE_PASSWORD
   keyAlias=capitalmonero
   keyPassword=YOUR_KEY_PASSWORD
   ```

### CI signing (GitHub Actions / Codemagic)

Encode your keystore as base64:
```bash
base64 -w 0 release.keystore
```

Add the following secrets to GitHub (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `CM_KEYSTORE` | Base64-encoded keystore |
| `CM_KEYSTORE_PASSWORD` | Keystore password |
| `CM_KEY_ALIAS` | Key alias |
| `CM_KEY_PASSWORD` | Key password |

For Codemagic, create a variable group named `release_signing` with the same keys.

---

## Testing

### Unit tests

```bash
./gradlew test
```

### Instrumented tests (requires a connected device/emulator)

```bash
./gradlew connectedAndroidTest
```

### Lint

```bash
./gradlew lint
```

---

## CI/CD

### GitHub Actions

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `android-ci.yml` | push to main/master, PRs, version tags | lint, unit-test, build-debug, build-release |
| `fdroid-check.yml` | changes to `metadata/` | F-Droid metadata lint |

Release APKs are built automatically on version tags matching `v*.*.*`.

### Codemagic

`codemagic.yaml` defines a full release pipeline including signing, tests, lint,
APK + AAB artifacts, and optional Telegram notifications.

---

## F-Droid

F-Droid metadata is at `metadata/com.capitalmonero.app.yml`.

To submit to F-Droid, open a pull request to
[fdroiddata](https://gitlab.com/fdroid/fdroiddata) adding this file.

---

## Architecture

- **UI**: Jetpack Compose + Material3
- **State management**: `StateFlow` + `ViewModel` (no external state library)
- **Navigation**: Jetpack Navigation Compose
- **Async**: Kotlin Coroutines
- **DI**: None (manual construction for simplicity; add Hilt if needed)

---

## Contributing

1. Fork the repo and create a feature branch.
2. Run `./gradlew lint test` before submitting a PR.
3. PRs require passing CI checks.

---

## License

GPL-3.0-or-later — see [LICENSE](LICENSE) (to be added).
