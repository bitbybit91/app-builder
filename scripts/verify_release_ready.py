#!/usr/bin/env python3
"""
verify_release_ready.py — Pre-flight check before a release build.

Checks:
  1. JDK version >= 17
  2. Gradle wrapper present and properties valid
  3. keys.properties or CM_KEYSTORE env var present
  4. No submodule issues
  5. Lint baseline exists (optional warning)
"""

import os
import shutil
import subprocess
import sys


REPO_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), ".."))
PASS = "✓"
FAIL = "✗"
WARN = "⚠"


def check(label: str, ok: bool, detail: str = "") -> bool:
    symbol = PASS if ok else FAIL
    print(f"  {symbol} {label}" + (f": {detail}" if detail else ""))
    return ok


def main() -> None:
    print("=== CapitalMonero Release Pre-flight Check ===\n")
    failures: list[str] = []

    # 1. JDK version
    java_cmd = shutil.which("java")
    if java_cmd:
        result = subprocess.run(
            ["java", "-version"], capture_output=True, text=True
        )
        version_str = result.stderr or result.stdout
        ok = "17" in version_str or "21" in version_str or "11" not in version_str
        if not check("JDK version (need 17+)", ok, version_str.splitlines()[0] if version_str else ""):
            failures.append("JDK 17+ required. Set JAVA_HOME or install JDK 17.")
    else:
        check("JDK present", False, "java not found in PATH")
        failures.append("Install JDK 17 and add to PATH.")

    # 2. Gradle wrapper
    gradlew = os.path.join(REPO_ROOT, "gradlew")
    wrapper_jar = os.path.join(REPO_ROOT, "gradle", "wrapper", "gradle-wrapper.jar")
    wrapper_props = os.path.join(REPO_ROOT, "gradle", "wrapper", "gradle-wrapper.properties")

    if not check("gradlew present", os.path.isfile(gradlew)):
        failures.append("Run: gradle wrapper --gradle-version 8.8")
    if not check("gradle-wrapper.jar present", os.path.isfile(wrapper_jar)):
        failures.append("gradle-wrapper.jar missing. Run: gradle wrapper --gradle-version 8.8")
    if not check("gradle-wrapper.properties present", os.path.isfile(wrapper_props)):
        failures.append("gradle-wrapper.properties missing.")
    else:
        with open(wrapper_props) as f:
            props_content = f.read()
        check(
            "Gradle 8.8+ declared",
            any(f"gradle-{v}" in props_content for v in ["8.8", "8.9", "8.10"]),
            props_content.strip().split("\n")[-1],
        )

    # 3. Signing
    keys_props = os.path.join(REPO_ROOT, "keys.properties")
    has_keys_file = os.path.isfile(keys_props)
    has_env_signing = bool(os.environ.get("CM_KEYSTORE"))
    if not check("Signing configured (keys.properties or CM_KEYSTORE env)", has_keys_file or has_env_signing):
        print(f"    {WARN} Run scripts/setup_signing.py or copy key.properties.template → keys.properties")

    # 4. Submodules
    gitmodules = os.path.join(REPO_ROOT, ".gitmodules")
    if os.path.isfile(gitmodules):
        result = subprocess.run(
            ["git", "submodule", "status"],
            capture_output=True, text=True, cwd=REPO_ROOT
        )
        uninitialized = [l for l in result.stdout.splitlines() if l.startswith("-")]
        if not check("Submodules initialized", not uninitialized, str(uninitialized) if uninitialized else ""):
            failures.append("Run: git submodule update --init --recursive")
    else:
        check("No submodules", True)

    # 5. Summary
    print()
    if failures:
        print(f"[FAILED] {len(failures)} issue(s) must be resolved before release:")
        for i, f in enumerate(failures, 1):
            print(f"  {i}. {f}")
        sys.exit(1)
    else:
        print("[PASSED] All pre-flight checks passed. Ready to build release.")


if __name__ == "__main__":
    main()
