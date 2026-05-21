#!/usr/bin/env python3
"""
setup_signing.py — Decode release keystore from environment variables.

Required environment variables:
  CM_KEYSTORE          Base64-encoded keystore file
  CM_KEYSTORE_PASSWORD Keystore password
  CM_KEY_ALIAS         Key alias
  CM_KEY_PASSWORD      Key password

Outputs:
  ./release.keystore   Decoded keystore file
  ./keys.properties    Signing config consumed by app/build.gradle.kts
"""

import base64
import os
import sys


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        print(
            f"ERROR: Required environment variable '{name}' is not set or empty.\n"
            f"  Please configure it in your CI variable group 'release_signing'.\n"
            f"  See README.md § Signing for instructions.",
            file=sys.stderr,
        )
        sys.exit(1)
    return value


def main() -> None:
    cm_keystore_b64 = require_env("CM_KEYSTORE")
    cm_keystore_password = require_env("CM_KEYSTORE_PASSWORD")
    cm_key_alias = require_env("CM_KEY_ALIAS")
    cm_key_password = require_env("CM_KEY_PASSWORD")

    # Decode keystore
    try:
        keystore_bytes = base64.b64decode(cm_keystore_b64)
    except Exception as exc:
        print(
            f"ERROR: Failed to base64-decode CM_KEYSTORE: {exc}\n"
            "  Ensure the value is a valid base64-encoded keystore file.",
            file=sys.stderr,
        )
        sys.exit(1)

    keystore_path = os.path.join(os.path.dirname(__file__), "..", "release.keystore")
    keystore_path = os.path.normpath(keystore_path)

    with open(keystore_path, "wb") as f:
        f.write(keystore_bytes)

    print(f"✓ Keystore written to: {keystore_path}")

    # Write keys.properties
    keys_props_path = os.path.join(os.path.dirname(__file__), "..", "keys.properties")
    keys_props_path = os.path.normpath(keys_props_path)

    with open(keys_props_path, "w") as f:
        f.write(f"storeFile=../release.keystore\n")
        f.write(f"storePassword={cm_keystore_password}\n")
        f.write(f"keyAlias={cm_key_alias}\n")
        f.write(f"keyPassword={cm_key_password}\n")

    print(f"✓ keys.properties written to: {keys_props_path}")


if __name__ == "__main__":
    main()
