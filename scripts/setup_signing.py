#!/usr/bin/env python3
"""
scripts/setup_signing.py
────────────────────────
Prepares Android release-signing artefacts for the Codemagic CI build.

Required environment variables
───────────────────────────────
  CM_KEYSTORE           Base64-encoded JKS/PKCS12 keystore (no line breaks).
                        Encode locally with:  base64 -w 0 release.keystore
  CM_KEYSTORE_PASSWORD  Password for the keystore store.
  CM_KEY_ALIAS          Alias of the signing key inside the keystore.
  CM_KEY_PASSWORD       Password for the signing key.

Optional
────────
  ANDROID_DIR           Absolute path to the android/ directory.
                        Defaults to  <repo_root>/android
"""

import base64
import logging
import os
import subprocess
import sys
from pathlib import Path

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("setup_signing")

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
ANDROID_DIR = Path(os.environ.get("ANDROID_DIR", REPO_ROOT / "android"))
APP_DIR = ANDROID_DIR / "app"
KEYSTORE_PATH = APP_DIR / "keystore.jks"
KEY_PROPERTIES_PATH = ANDROID_DIR / "key.properties"

REQUIRED_ENV_VARS = [
    "CM_KEYSTORE",
    "CM_KEYSTORE_PASSWORD",
    "CM_KEY_ALIAS",
    "CM_KEY_PASSWORD",
]


def validate_env() -> dict[str, str]:
    """Read and validate all required environment variables."""
    env: dict[str, str] = {}
    missing: list[str] = []
    for var in REQUIRED_ENV_VARS:
        value = os.environ.get(var, "").strip()
        if not value:
            missing.append(var)
        else:
            env[var] = value

    if missing:
        log.error(
            "The following required environment variables are not set:\n  %s\n"
            "See CODEMAGIC_SETUP.md for setup instructions.",
            "\n  ".join(missing),
        )
        sys.exit(1)

    log.info("All required environment variables are present.")
    return env


def decode_keystore(b64_keystore: str, dest: Path) -> None:
    """Decode the base64 keystore and write it to *dest*."""
    try:
        keystore_bytes = base64.b64decode(b64_keystore)
    except Exception as exc:  # noqa: BLE001
        log.error("Failed to base64-decode CM_KEYSTORE: %s", exc)
        sys.exit(1)

    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        dest.write_bytes(keystore_bytes)
    except OSError as exc:
        log.error("Failed to write keystore to %s: %s", dest, exc)
        sys.exit(1)

    log.info("Keystore written to %s (%d bytes).", dest, len(keystore_bytes))


def write_key_properties(env: dict[str, str], keystore_path: Path, dest: Path) -> None:
    """Write android/key.properties from environment variables."""
    content = (
        f"storeFile={keystore_path.as_posix()}\n"
        f"storePassword={env['CM_KEYSTORE_PASSWORD']}\n"
        f"keyAlias={env['CM_KEY_ALIAS']}\n"
        f"keyPassword={env['CM_KEY_PASSWORD']}\n"
    )
    try:
        dest.write_text(content, encoding="utf-8")  # lgtm[py/clear-text-storage-sensitive-data]
        # Restrict permissions: owner read/write only (no group/world access)
        dest.chmod(0o600)
    except OSError as exc:
        log.error("Failed to write key.properties to %s: %s", dest, exc)
        sys.exit(1)

    log.info("key.properties written to %s.", dest)


def validate_keystore(keystore_path: Path, store_password: str, key_alias: str) -> None:
    """Run keytool -list to verify the keystore is valid and the alias exists."""
    keytool = "keytool"
    cmd = [
        keytool,
        "-list",
        "-v",
        "-keystore", str(keystore_path),
        "-storepass", store_password,
        "-alias", key_alias,
    ]

    log.info("Validating keystore with keytool…")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=30,
        )
    except FileNotFoundError:
        log.warning(
            "keytool not found on PATH — skipping keystore validation. "
            "Ensure a JDK is installed on the build machine."
        )
        return
    except subprocess.TimeoutExpired:
        log.error("keytool timed out after 30 seconds.")
        sys.exit(1)

    if result.returncode != 0:
        log.error(
            "keytool validation failed (exit %d).\nstdout:\n%s\nstderr:\n%s",
            result.returncode,
            result.stdout,
            result.stderr,
        )
        sys.exit(1)

    log.info("Keystore validated successfully.")
    # Print certificate fingerprint for audit trail
    for line in result.stdout.splitlines():
        if "SHA" in line or "Alias name" in line or "Valid from" in line:
            log.info("  %s", line.strip())


def main() -> None:
    log.info("=== Magoradesk release-signing setup ===")
    log.info("Repo root  : %s", REPO_ROOT)
    log.info("Android dir: %s", ANDROID_DIR)

    # 1. Validate environment
    env = validate_env()

    # 2. Decode keystore
    decode_keystore(env["CM_KEYSTORE"], KEYSTORE_PATH)

    # 3. Write key.properties
    write_key_properties(env, KEYSTORE_PATH, KEY_PROPERTIES_PATH)

    # 4. Validate keystore
    validate_keystore(KEYSTORE_PATH, env["CM_KEYSTORE_PASSWORD"], env["CM_KEY_ALIAS"])

    log.info("=== Signing setup complete — ready for flutter build apk --release ===")


if __name__ == "__main__":
    main()
