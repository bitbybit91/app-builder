#!/usr/bin/env python3
"""
scripts/verify_release_ready.py
────────────────────────────────
Comprehensive pre-flight check that the repository is ready for a signed
release APK build via Codemagic.

Exit code
─────────
  0  All checks passed — green build expected.
  1  One or more checks failed — see report for details.

Usage
─────
  python3 scripts/verify_release_ready.py
  python3 scripts/verify_release_ready.py --skip-build-dry-run
"""

import argparse
import json
import logging
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

# ── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
)
log = logging.getLogger("verify")

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
ANDROID_DIR = REPO_ROOT / "android"
APP_BUILD_GRADLE = ANDROID_DIR / "app" / "build.gradle"
MANIFEST_PATH = ANDROID_DIR / "app" / "src" / "main" / "AndroidManifest.xml"
PUBSPEC_PATH = REPO_ROOT / "pubspec.yaml"
KEY_PROPS_TEMPLATE = ANDROID_DIR / "key.properties.template"
CODEMAGIC_YAML = REPO_ROOT / "codemagic.yaml"
SETUP_SIGNING_SCRIPT = REPO_ROOT / "scripts" / "setup_signing.py"
GRADLEW = ANDROID_DIR / "gradlew"

# Environment variables that must be referenced (not hardcoded) in CI config
REQUIRED_ENV_VARS_IN_CI = [
    "CM_KEYSTORE",
    "CM_KEYSTORE_PASSWORD",
    "CM_KEY_ALIAS",
    "CM_KEY_PASSWORD",
]

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"


class CheckResult(NamedTuple):
    name: str
    passed: bool
    message: str


results: list[CheckResult] = []


def check(name: str, passed: bool, message: str = "") -> bool:
    icon = f"{GREEN}✅{RESET}" if passed else f"{RED}❌{RESET}"
    label = f"{icon} {name}"
    if message:
        label += f": {message}"
    log.info(label)
    results.append(CheckResult(name, passed, message))
    return passed


def run_cmd(
    cmd: list[str],
    cwd: Path | None = None,
    timeout: int = 120,
) -> tuple[int, str, str]:
    """Run a command and return (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.returncode, result.stdout, result.stderr
    except FileNotFoundError:
        return -1, "", f"Command not found: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return -2, "", f"Command timed out after {timeout}s: {' '.join(cmd)}"


# ── Individual checks ────────────────────────────────────────────────────────

def check_tool_versions() -> None:
    log.info("\n─── Tool versions ───────────────────────────────────────────")

    # Flutter
    rc, stdout, _ = run_cmd(["flutter", "--version"])
    if rc == 0:
        version_line = stdout.splitlines()[0] if stdout else "unknown"
        check("Flutter installed", True, version_line)
    else:
        check("Flutter installed", False, "flutter not found on PATH")

    # Dart
    rc, stdout, _ = run_cmd(["dart", "--version"])
    check("Dart installed", rc == 0, stdout.strip() if rc == 0 else "dart not found")

    # Java
    rc, _, stderr = run_cmd(["java", "-version"])
    version = stderr.splitlines()[0] if stderr else "unknown"
    check("Java installed", rc == 0, version)

    # Gradle (via wrapper)
    if GRADLEW.exists():
        rc, stdout, _ = run_cmd(
            [str(GRADLEW), "--version", "--no-daemon"],
            cwd=ANDROID_DIR,
            timeout=60,
        )
        if rc == 0:
            for line in stdout.splitlines():
                if "Gradle" in line:
                    check("Gradle wrapper", True, line.strip())
                    break
        else:
            check("Gradle wrapper", False, "gradlew --version failed")
    else:
        check("Gradle wrapper (gradlew)", False, f"Not found at {GRADLEW}")


def check_pubspec() -> None:
    log.info("\n─── pubspec.yaml ────────────────────────────────────────────")

    if not PUBSPEC_PATH.exists():
        check("pubspec.yaml exists", False, str(PUBSPEC_PATH))
        return
    check("pubspec.yaml exists", True)

    content = PUBSPEC_PATH.read_text(encoding="utf-8")

    # Must have a name
    check("pubspec: name field", bool(re.search(r"^name:\s+\S+", content, re.M)))

    # Must have sdk environment
    check("pubspec: sdk constraint", "sdk:" in content)

    # Must reference flutter sdk
    check("pubspec: flutter sdk dep", "sdk: flutter" in content)

    # Must NOT contain hardcoded secrets
    for secret_pattern in ["password:", "secret:", "api_key:"]:
        if re.search(rf"^\s*{re.escape(secret_pattern)}", content, re.I | re.M):
            check(
                f"pubspec: no hardcoded {secret_pattern}",
                False,
                "Possible secret found — move to env vars",
            )


def check_build_gradle() -> None:
    log.info("\n─── android/app/build.gradle ────────────────────────────────")

    if not APP_BUILD_GRADLE.exists():
        check("build.gradle exists", False)
        return
    check("build.gradle exists", True)

    content = APP_BUILD_GRADLE.read_text(encoding="utf-8")

    # minSdkVersion >= 21 (Google Play requirement)
    m = re.search(r"minSdkVersion\s+(\d+)", content)
    if m:
        min_sdk = int(m.group(1))
        check("minSdkVersion >= 21", min_sdk >= 21, f"Found {min_sdk}")
    else:
        check("minSdkVersion defined", False)

    # targetSdkVersion
    m = re.search(r"targetSdkVersion\s+(\d+)", content)
    if m:
        target_sdk = int(m.group(1))
        check("targetSdkVersion >= 33", target_sdk >= 33, f"Found {target_sdk}")
    else:
        check("targetSdkVersion defined", False)

    # compileSdkVersion
    check("compileSdkVersion defined", "compileSdkVersion" in content)

    # MultiDex
    check("multiDexEnabled", "multiDexEnabled true" in content)

    # Desugaring
    check("coreLibraryDesugaring", "coreLibraryDesugaringEnabled true" in content)

    # Signing config references env vars via key.properties
    check(
        "signing: reads key.properties",
        "key.properties" in content,
    )

    # R8 / minification
    check("R8 minification enabled", "minifyEnabled true" in content)

    # ABI splits
    check("ABI splits configured", "splits {" in content)


def check_manifest() -> None:
    log.info("\n─── AndroidManifest.xml ─────────────────────────────────────")

    if not MANIFEST_PATH.exists():
        check("AndroidManifest.xml exists", False)
        return
    check("AndroidManifest.xml exists", True)

    content = MANIFEST_PATH.read_text(encoding="utf-8")

    check("INTERNET permission", "android.permission.INTERNET" in content)
    check("android:exported on MainActivity", 'android:exported="true"' in content)
    check("android:label set", "android:label=" in content)
    check("android:icon set", "android:icon=" in content)
    check("networkSecurityConfig", "networkSecurityConfig" in content)
    check("queries block (Android 11+)", "<queries>" in content)
    check("flutterEmbedding meta-data", "flutterEmbedding" in content)


def check_codemagic_yaml() -> None:
    log.info("\n─── codemagic.yaml ──────────────────────────────────────────")

    if not CODEMAGIC_YAML.exists():
        check("codemagic.yaml exists", False)
        return
    check("codemagic.yaml exists", True)

    content = CODEMAGIC_YAML.read_text(encoding="utf-8")

    check("flutter-release-apk workflow", "flutter-release-apk" in content)
    check("flutter build apk --release", "flutter build apk --release" in content)
    check("setup_signing.py pre-build", "setup_signing.py" in content)
    check("artifact patterns", "artifacts:" in content)
    check("triggering on main branch", "main" in content and "triggering" in content)

    for env_var in REQUIRED_ENV_VARS_IN_CI:
        check(
            f"codemagic.yaml references {env_var}",
            env_var in content,
        )


def check_env_vars_not_hardcoded() -> None:
    log.info("\n─── Security: no hardcoded secrets ──────────────────────────")

    # Scan all tracked files for hardcoded passwords/secrets
    rc, stdout, _ = run_cmd(
        ["git", "ls-files"],
        cwd=REPO_ROOT,
    )
    if rc != 0:
        check("git ls-files", False, "Could not list tracked files")
        return

    secret_patterns = [
        re.compile(r'storePassword\s*=\s*["\']?\w{4,}', re.I),
        re.compile(r'keyPassword\s*=\s*["\']?\w{4,}', re.I),
        re.compile(r'CM_KEYSTORE\s*=\s*[A-Za-z0-9+/]{20,}'),
    ]

    found_secrets = []
    for filepath in stdout.splitlines():
        path = REPO_ROOT / filepath
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pattern in secret_patterns:
            if pattern.search(text):
                # Exclude template and script files which legitimately reference names
                if "template" not in filepath and "setup_signing" not in filepath:
                    found_secrets.append(filepath)
                    break

    check(
        "No hardcoded secrets in tracked files",
        len(found_secrets) == 0,
        f"Suspicious files: {found_secrets}" if found_secrets else "",
    )


def check_key_properties_not_tracked() -> None:
    log.info("\n─── key.properties not in git ───────────────────────────────")

    rc, stdout, _ = run_cmd(["git", "ls-files", "android/key.properties"], cwd=REPO_ROOT)
    tracked = stdout.strip() != ""
    check(
        "android/key.properties NOT tracked by git",
        not tracked,
        "Remove with: git rm --cached android/key.properties" if tracked else "",
    )

    # Check .gitignore
    gitignore = REPO_ROOT / ".gitignore"
    if gitignore.exists():
        gi_content = gitignore.read_text(encoding="utf-8")
        check("key.properties in .gitignore", "key.properties" in gi_content)
    else:
        check("key.properties in .gitignore", False, ".gitignore not found")


def check_flutter_analyze() -> None:
    log.info("\n─── flutter analyze ─────────────────────────────────────────")

    rc, stdout, stderr = run_cmd(
        ["flutter", "analyze", "--no-pub"],
        cwd=REPO_ROOT,
        timeout=180,
    )
    if rc == -1:
        check("flutter analyze", False, "flutter not found")
        return

    output = (stdout + stderr).strip()
    error_count = output.count(" error ")
    warning_count = output.count(" warning ")

    passed = rc == 0 or error_count == 0
    summary = f"{error_count} errors, {warning_count} warnings"
    check("flutter analyze (no errors)", passed, summary)


def check_gradle_dry_run(skip: bool) -> None:
    log.info("\n─── Gradle dry run ──────────────────────────────────────────")

    if skip:
        log.info(f"{YELLOW}⏭  Skipped (--skip-build-dry-run){RESET}")
        return

    if not GRADLEW.exists():
        check("gradlew exists", False)
        return

    rc, stdout, stderr = run_cmd(
        [str(GRADLEW), ":app:assembleRelease", "--dry-run", "--no-daemon"],
        cwd=ANDROID_DIR,
        timeout=120,
    )
    passed = rc == 0
    check(
        "Gradle assembleRelease --dry-run",
        passed,
        "OK" if passed else f"Exit {rc} — see output above",
    )
    if not passed and stderr:
        log.info(stderr[-2000:])  # Print last 2 KB of stderr


# ── Report ────────────────────────────────────────────────────────────────────

def print_report() -> int:
    log.info("\n══════════════════════════════════════════════════════════════")
    log.info("  READINESS REPORT")
    log.info("══════════════════════════════════════════════════════════════")

    passed = [r for r in results if r.passed]
    failed = [r for r in results if not r.passed]

    log.info(f"  {GREEN}Passed{RESET}: {len(passed)}/{len(results)}")
    if failed:
        log.info(f"  {RED}Failed{RESET}: {len(failed)}/{len(results)}")
        log.info("")
        for r in failed:
            log.info(f"  {RED}❌{RESET} {r.name}" + (f" — {r.message}" if r.message else ""))

    log.info("══════════════════════════════════════════════════════════════")
    if not failed:
        log.info(f"  {GREEN}✅  Repository is RELEASE READY for Codemagic.{RESET}")
    else:
        log.info(f"  {RED}❌  {len(failed)} check(s) failed. Fix before pushing.{RESET}")
    log.info("══════════════════════════════════════════════════════════════\n")

    return 0 if not failed else 1


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Verify release readiness for Codemagic.")
    parser.add_argument(
        "--skip-build-dry-run",
        action="store_true",
        help="Skip the Gradle assembleRelease --dry-run step (faster).",
    )
    args = parser.parse_args()

    log.info("══════════════════════════════════════════════════════════════")
    log.info("  Magoradesk — Release Readiness Verification")
    log.info(f"  Repo root: {REPO_ROOT}")
    log.info("══════════════════════════════════════════════════════════════")

    check_tool_versions()
    check_pubspec()
    check_build_gradle()
    check_manifest()
    check_codemagic_yaml()
    check_env_vars_not_hardcoded()
    check_key_properties_not_tracked()
    check_flutter_analyze()
    check_gradle_dry_run(args.skip_build_dry_run)

    sys.exit(print_report())


if __name__ == "__main__":
    main()
