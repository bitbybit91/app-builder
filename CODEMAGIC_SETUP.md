# Magoradesk — Codemagic Setup Guide

This document explains every environment variable needed for automated
signed-APK delivery and how to configure them in the Codemagic UI.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.22.2 (stable) |
| Dart | bundled with Flutter 3.22.2 |
| Java | 17 (Temurin) |
| Gradle | 8.4 (via wrapper) |
| AGP | 8.3.2 |

---

## Step 1 — Generate a release keystore (one-time)

If you do not already have a keystore, generate one with:

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias magoradesk_key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Magoradesk, OU=Dev, O=Magoradesk, L=City, S=State, C=US"
```

> ⚠️ Keep `release.keystore` safe. Losing it means you cannot update your app on Google Play.

---

## Step 2 — Base64-encode the keystore

```bash
# Linux / macOS
base64 -w 0 release.keystore > release.keystore.b64
cat release.keystore.b64
```

Copy the **entire single-line** output — this is the value for `CM_KEYSTORE`.

---

## Step 3 — Create a variable group in Codemagic

1. Open [https://codemagic.io](https://codemagic.io) → your app → **Environment variables**.
2. Click **+ Add variable group** → name it **`magoradesk_signing`**.
3. Add the following variables (mark all as **Secret**):

| Variable name | Value | Secret |
|---|---|---|
| `CM_KEYSTORE` | Base64-encoded keystore (from Step 2) | ✅ Yes |
| `CM_KEYSTORE_PASSWORD` | Store password | ✅ Yes |
| `CM_KEY_ALIAS` | `magoradesk_key` (or your alias) | ✅ Yes |
| `CM_KEY_PASSWORD` | Key password | ✅ Yes |

4. Add the following **optional** variables for notifications:

| Variable name | Value | Secret |
|---|---|---|
| `CM_NOTIFY_EMAIL` | your@email.com | No |
| `CM_TELEGRAM_BOT_TOKEN` | Telegram bot token | ✅ Yes |
| `CM_TELEGRAM_CHAT_ID` | Telegram chat/channel ID | No |

5. In the **`flutter-release-apk`** workflow settings, under **Environment** → **Variable groups**, add `magoradesk_signing`.

---

## Step 4 — Connect the repository

1. In Codemagic, click **+ Add application**.
2. Choose your Git provider (GitHub / GitLab / Bitbucket) and select `bitbybit91/app-builder`.
3. Select **Flutter App** as the project type.
4. Codemagic auto-detects `codemagic.yaml` — select the **`flutter-release-apk`** workflow.

---

## Step 5 — Trigger a build

Push to `main` or create a tag:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

Codemagic picks up the push/tag, runs `setup_signing.py`, builds the APK,
signs it, and makes all artifacts available for download.

---

## How signing works (internals)

```
CM_KEYSTORE ──base64-decode──▶ android/app/keystore.jks
CM_KEYSTORE_PASSWORD  ─┐
CM_KEY_ALIAS          ─┼─▶ android/key.properties
CM_KEY_PASSWORD       ─┘
                           │
                           ▼
              android/app/build.gradle reads key.properties
                           │
                           ▼
              flutter build apk --release  →  signed APK
```

The keystore file and `key.properties` are **never committed to git** —
they exist only in the ephemeral Codemagic build container.

---

## Local development (optional)

To sign a release APK locally:

```bash
# 1. Copy the template
cp android/key.properties.template android/key.properties

# 2. Edit android/key.properties with your real values
nano android/key.properties

# 3. Place your keystore at android/app/keystore.jks
cp /path/to/release.keystore android/app/keystore.jks

# 4. Build
flutter build apk --release --split-per-abi
```

`android/key.properties` and `android/app/keystore.jks` are in `.gitignore`
and will NOT be committed.

---

## Verification

Run the pre-flight check locally:

```bash
python3 scripts/verify_release_ready.py
```

It prints a ✅ / ❌ report and exits 0 only if all checks pass.
