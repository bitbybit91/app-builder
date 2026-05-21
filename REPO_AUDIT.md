# Repository Audit — CapitalMonero

**Audit Date:** 2024-06
**Auditor:** Automated Engineering Agent
**Branch:** copilot/audit-and-fix-repository-branches

---

## 1. Branch Inventory

| Branch | Description | Build Status |
|--------|-------------|--------------|
| `copilot/audit-and-fix-repository-branches` | Primary working branch (this scaffold) | ✅ Scaffolded |

> Only one branch was found in the remote at audit time.

---

## 2. Pre-Scaffold State

### Directory Tree (before scaffold)

```
app-builder/
├── .github/
│   └── workflows/
│       └── build.yml        ← Flutter-based workflow (incorrect for Kotlin/Android)
└── README.md                ← Placeholder ("magoradesk")
```

### Issues Found

| # | Severity | Category | Issue |
|---|----------|----------|-------|
| 1 | CRITICAL | Build | No Android project files existed (no Gradle, no source code) |
| 2 | CRITICAL | Build | Existing workflow used Flutter, not Android/Kotlin |
| 3 | HIGH | Documentation | README was a single-word placeholder |
| 4 | HIGH | Signing | No signing configuration or scripts |
| 5 | HIGH | CI/CD | No Android-compatible CI pipeline |
| 6 | HIGH | F-Droid | No F-Droid metadata |
| 7 | MEDIUM | License | No LICENSE file committed |
| 8 | MEDIUM | Security | No .gitignore (keystores could be accidentally committed) |
| 9 | LOW | Submodules | No .gitmodules (nothing to fix) |

---

## 3. Scaffold Applied

### What Was Created

- **Android Project** (`settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts`)
  - AGP 8.4.2, Kotlin 1.9.24, Compose BOM 2024.06.00
  - JDK 17 toolchain
  - Version Catalogs (`gradle/libs.versions.toml`)
  - Gradle 8.8 wrapper
  - FOSS-only dependencies (no Google Play Services, Firebase, AdMob)

- **App Source** (`app/src/main/java/com/capitalmonero/app/`)
  - `MainActivity.kt` (Compose entry point, edge-to-edge)
  - `CapitalMoneroApp.kt` (navigation graph)
  - `HomeScreen.kt` + `HomeViewModel.kt` (StateFlow, Coroutines)
  - `AboutScreen.kt`
  - Theme with Monero orange color scheme

- **Resources**
  - Adaptive icon (foreground + background + monochrome) — API 26+ only (matches minSdk)
  - `strings.xml`, `themes.xml`, `colors.xml`
  - `network_security_config.xml` (cleartext disabled)
  - `data_extraction_rules.xml`, `backup_rules.xml` (Android 12+)
  - `AndroidManifest.xml` (minimum permissions: INTERNET, ACCESS_NETWORK_STATE)

- **Tests**
  - `HomeViewModelTest.kt` — 4 unit tests covering ViewModel state
  - `MainActivityTest.kt` — 2 instrumented smoke tests

- **Signing**
  - `scripts/setup_signing.py` — decodes CM_KEYSTORE env var to release.keystore + keys.properties
  - `scripts/verify_release_ready.py` — pre-flight checks (JDK, Gradle, signing, submodules)
  - `key.properties.template` — committed template (keys.properties is gitignored)

- **CI/CD**
  - `.github/workflows/android-ci.yml` — lint, unit-test, build-debug, build-release (on tag)
  - `.github/workflows/fdroid-check.yml` — F-Droid metadata linting on PR
  - `codemagic.yaml` — full release pipeline with signing, test, lint, APK+AAB artifacts

- **F-Droid**
  - `metadata/com.capitalmonero.app.yml` — F-Droid build recipe

- **Infrastructure**
  - `.gitignore` — covers *.keystore, *.jks, keys.properties, build/, .gradle/, .idea/
  - `README.md` — end-to-end developer guide

---

## 4. Remaining Manual Steps

1. **Generate a release keystore** and encode it as base64 for CI secrets.
2. **Add GitHub Secrets**: `CM_KEYSTORE`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`.
3. **Add a Codemagic variable group** `release_signing` with the same keys.
4. **Add a LICENSE file** (GPL-3.0-or-later recommended to match F-Droid metadata).
5. **Generate PNG mipmaps** from the vector icon (needed for stores): use Android Studio's Image Asset Studio.
6. **Submit to F-Droid** by opening a PR to [fdroiddata](https://gitlab.com/fdroid/fdroiddata) adding `metadata/com.capitalmonero.app.yml`.
7. **Tag `v1.0.0`** to trigger the first release build.

---

## 5. Security Notes

- No hardcoded secrets were found (repo was near-empty before scaffold).
- Cleartext HTTP is disabled in `network_security_config.xml`.
- `keys.properties` and `*.keystore` are gitignored.
- ProGuard/R8 is enabled for release builds.
