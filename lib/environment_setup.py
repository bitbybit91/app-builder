"""
environment_setup.py — Detect, validate, and report on required build tools.

Checks Flutter, Android SDK, Xcode (macOS), Java, Ruby, CocoaPods, Fastlane,
and Git.  Provides actionable install instructions for any missing component.
"""
from __future__ import annotations

import logging
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

logger = logging.getLogger(__name__)


@dataclass
class ToolInfo:
    """Describes the status of a single required tool."""

    name: str
    required: bool
    installed: bool = False
    version: str = ""
    path: str = ""
    meets_minimum: bool = True
    install_cmd: str = ""


@dataclass
class EnvironmentReport:
    """Aggregated result of environment validation."""

    tools: List[ToolInfo] = field(default_factory=list)
    is_macos: bool = False
    is_linux: bool = False
    is_windows: bool = False
    android_sdk_path: str = ""
    flutter_sdk_path: str = ""
    all_required_met: bool = False
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)


def _run(cmd: List[str], timeout: int = 30) -> Tuple[int, str, str]:
    """Run *cmd* and return (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return 1, "", str(exc)


def _parse_semver(version_str: str) -> Tuple[int, int, int]:
    """Extract (major, minor, patch) from a version string."""
    m = re.search(r"(\d+)\.(\d+)\.?(\d*)", version_str)
    if m:
        patch = int(m.group(3)) if m.group(3) else 0
        return int(m.group(1)), int(m.group(2)), patch
    return (0, 0, 0)


def _meets_minimum(actual: str, minimum: str) -> bool:
    """Return True if *actual* version >= *minimum* version."""
    return _parse_semver(actual) >= _parse_semver(minimum)


class EnvironmentSetup:
    """Validate the host environment and provide setup guidance."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._env_cfg = config.get("environment", {})
        self._is_macos = platform.system() == "Darwin"
        self._is_linux = platform.system() == "Linux"
        self._is_windows = platform.system() == "Windows"

    # ── Public API ────────────────────────────────────────────────────────────

    def check(self) -> EnvironmentReport:
        """Run all checks and return an :class:`EnvironmentReport`."""
        report = EnvironmentReport(
            is_macos=self._is_macos,
            is_linux=self._is_linux,
            is_windows=self._is_windows,
        )

        checks = [
            self._check_git,
            self._check_flutter,
            self._check_java,
            self._check_android_sdk,
        ]
        if self._is_macos:
            checks += [self._check_xcode, self._check_cocoapods]
        checks += [self._check_ruby, self._check_fastlane]

        for check_fn in checks:
            tool = check_fn()
            report.tools.append(tool)
            if tool.installed:
                logger.info("  ✔  %-20s %s", tool.name, tool.version)
            else:
                msg = f"  ✘  {tool.name} not found"
                if tool.required:
                    report.errors.append(f"{tool.name} is required but not installed. {tool.install_cmd}")
                    logger.error(msg)
                else:
                    report.warnings.append(f"{tool.name} not installed (optional). {tool.install_cmd}")
                    logger.warning(msg)

            if tool.installed and not tool.meets_minimum:
                report.warnings.append(
                    f"{tool.name} version {tool.version} may be too old. {tool.install_cmd}"
                )
                logger.warning("  ⚠  %s version %s may not meet requirements", tool.name, tool.version)

        # Record SDK paths for callers
        flutter_tool = next((t for t in report.tools if t.name == "Flutter"), None)
        if flutter_tool and flutter_tool.path:
            report.flutter_sdk_path = flutter_tool.path

        android_tool = next((t for t in report.tools if t.name == "Android SDK"), None)
        if android_tool and android_tool.path:
            report.android_sdk_path = android_tool.path

        required_tools = [t for t in report.tools if t.required]
        report.all_required_met = all(t.installed and t.meets_minimum for t in required_tools)
        return report

    def accept_android_licenses(self) -> bool:
        """Accept Android SDK licences non-interactively."""
        sdkmanager = shutil.which("sdkmanager")
        if not sdkmanager:
            logger.warning("sdkmanager not found — cannot auto-accept Android licenses")
            return False
        logger.info("Accepting Android SDK licenses …")
        rc, _, _ = _run(["bash", "-c", f"yes | {sdkmanager} --licenses"], timeout=120)
        if rc != 0:
            logger.warning("Failed to auto-accept Android SDK licenses (exit %d)", rc)
            return False
        logger.info("Android SDK licenses accepted")
        return True

    # ── Individual tool checks ────────────────────────────────────────────────

    def _check_git(self) -> ToolInfo:
        tool = ToolInfo(name="git", required=True,
                        install_cmd="Install Git from https://git-scm.com/downloads")
        path = shutil.which("git")
        if path:
            rc, out, _ = _run(["git", "--version"])
            tool.installed = rc == 0
            tool.path = path
            tool.version = out.replace("git version ", "")
        return tool

    def _check_flutter(self) -> ToolInfo:
        min_ver = self._env_cfg.get("flutter_min_version", "3.10.0")
        install_cmd = (
            "Install Flutter SDK: https://flutter.dev/docs/get-started/install"
        )
        tool = ToolInfo(name="Flutter", required=True, install_cmd=install_cmd)
        path = shutil.which("flutter")
        if path:
            rc, out, _ = _run(["flutter", "--version"], timeout=60)
            tool.installed = rc == 0
            tool.path = path
            m = re.search(r"Flutter\s+([\d.]+)", out)
            if m:
                tool.version = m.group(1)
                tool.meets_minimum = _meets_minimum(tool.version, min_ver)
        return tool

    def _check_java(self) -> ToolInfo:
        min_ver = self._env_cfg.get("java_min_version", "11")
        tool = ToolInfo(
            name="Java",
            required=True,
            install_cmd="Install JDK 11+: https://adoptium.net/",
        )
        path = shutil.which("java")
        if path:
            rc, out, err = _run(["java", "-version"])
            tool.installed = rc == 0
            tool.path = path
            # java -version prints to stderr
            combined = out + " " + err
            m = re.search(r'version "?([\d._]+)"?', combined)
            if m:
                tool.version = m.group(1)
                major = _parse_semver(tool.version)[0]
                # Handle "1.8" style
                if major == 1:
                    major = _parse_semver(tool.version)[1]
                tool.meets_minimum = major >= int(re.match(r"\d+", min_ver).group())
        return tool

    def _check_android_sdk(self) -> ToolInfo:
        tool = ToolInfo(
            name="Android SDK",
            required=True,
            install_cmd=(
                "Install Android SDK via Android Studio: "
                "https://developer.android.com/studio"
            ),
        )
        import os

        sdk_root = (
            os.environ.get("ANDROID_SDK_ROOT")
            or os.environ.get("ANDROID_HOME")
        )
        if sdk_root:
            tool.installed = True
            tool.path = sdk_root
            tool.version = "SDK present"
        else:
            # Try adb as proxy
            path = shutil.which("adb")
            if path:
                rc, out, _ = _run(["adb", "--version"])
                tool.installed = rc == 0
                tool.path = path
                m = re.search(r"Version ([\d.]+)", out)
                if m:
                    tool.version = m.group(1)
        return tool

    def _check_xcode(self) -> ToolInfo:
        tool = ToolInfo(
            name="Xcode",
            required=False,  # only required on macOS for iOS builds
            install_cmd="Install Xcode from the Mac App Store",
        )
        if not self._is_macos:
            return tool
        tool.required = True
        min_ver = self._env_cfg.get("xcode_min_version", "14.0")
        rc, out, _ = _run(["xcodebuild", "-version"], timeout=30)
        if rc == 0:
            tool.installed = True
            tool.path = "/usr/bin/xcodebuild"
            m = re.search(r"Xcode\s+([\d.]+)", out)
            if m:
                tool.version = m.group(1)
                tool.meets_minimum = _meets_minimum(tool.version, min_ver)
        return tool

    def _check_cocoapods(self) -> ToolInfo:
        tool = ToolInfo(
            name="CocoaPods",
            required=False,
            install_cmd="gem install cocoapods",
        )
        if not self._is_macos:
            return tool
        tool.required = True
        path = shutil.which("pod")
        if path:
            rc, out, _ = _run(["pod", "--version"])
            tool.installed = rc == 0
            tool.path = path
            tool.version = out.strip()
        return tool

    def _check_ruby(self) -> ToolInfo:
        min_ver = self._env_cfg.get("ruby_min_version", "2.7")
        tool = ToolInfo(
            name="Ruby",
            required=False,
            install_cmd="Install Ruby: https://www.ruby-lang.org/en/downloads/",
        )
        path = shutil.which("ruby")
        if path:
            rc, out, _ = _run(["ruby", "--version"])
            tool.installed = rc == 0
            tool.path = path
            m = re.search(r"ruby ([\d.]+)", out)
            if m:
                tool.version = m.group(1)
                tool.meets_minimum = _meets_minimum(tool.version, min_ver)
        return tool

    def _check_fastlane(self) -> ToolInfo:
        tool = ToolInfo(
            name="Fastlane",
            required=False,
            install_cmd="gem install fastlane",
        )
        path = shutil.which("fastlane")
        if path:
            rc, out, _ = _run(["fastlane", "--version"], timeout=30)
            tool.installed = rc == 0
            tool.path = path
            m = re.search(r"fastlane\s+([\d.]+)", out, re.IGNORECASE)
            if m:
                tool.version = m.group(1)
        return tool

    # ── Reporting helpers ─────────────────────────────────────────────────────

    @staticmethod
    def print_report(report: EnvironmentReport) -> None:
        """Print a human-readable environment report to stdout."""
        sep = "─" * 60
        print(f"\n{sep}")
        print("  Environment Check")
        print(sep)
        for tool in report.tools:
            status = "✔" if (tool.installed and tool.meets_minimum) else ("⚠" if tool.installed else "✘")
            print(f"  [{status}] {tool.name:<20} {tool.version}")
        print(sep)
        if report.errors:
            print("\n  ERRORS (must fix before building):")
            for e in report.errors:
                print(f"    ✘ {e}")
        if report.warnings:
            print("\n  WARNINGS:")
            for w in report.warnings:
                print(f"    ⚠ {w}")
        print()
