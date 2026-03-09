"""
ios_builder.py — Configure and build the iOS IPA artifact.

Detects macOS, configures Xcode project settings, runs pod install,
and invokes `flutter build ipa`.  On non-macOS systems generates all
config files and prints clear instructions.
"""
from __future__ import annotations

import logging
import os
import plistlib
import platform
import re
import shutil
import subprocess
import time
from pathlib import Path
from typing import List, Optional

logger = logging.getLogger(__name__)

_EXPORT_OPTIONS_TPL = """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>{export_method}</string>
    <key>teamID</key>
    <string>{team_id}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>{signing_style}</string>
</dict>
</plist>
"""


class iOSBuilder:
    """Build signed (or unsigned) iOS IPA artifact."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._ios_cfg: dict = config.get("ios", {})
        self._app_cfg: dict = config.get("app", {})
        self._build_cfg: dict = config.get("build", {})
        self._env_cfg: dict = config.get("environment", {})
        self._is_macos = platform.system() == "Darwin"
        self._max_retries: int = int(self._env_cfg.get("max_retries", 3))
        self._retry_delay: int = int(self._env_cfg.get("retry_delay_seconds", 5))
        self._timeout: int = int(self._env_cfg.get("subprocess_timeout", 600))

    # ── Public API ────────────────────────────────────────────────────────────

    def build(self, app_path: Path, output_dir: Path) -> dict:
        """Configure and build the iOS IPA.

        Returns a dict with artifact paths.  If not on macOS, generates
        config files and returns instructions instead of raising.
        """
        logger.info("=== iOS Build ===")

        # Generate config files regardless of OS
        export_plist = self._write_export_options(app_path)
        self._configure_xcode_project(app_path)

        if not self._is_macos:
            msg = (
                "iOS builds require macOS. Config files have been generated.\n"
                f"  ExportOptions.plist → {export_plist}\n"
                "  Run the following on a Mac:\n"
                f"    cd {app_path}\n"
                f"    pod install --project-directory=ios\n"
                f"    flutter build ipa --release "
                f"--export-options-plist={export_plist}"
            )
            logger.warning(msg)
            return {"instructions": msg, "export_plist": str(export_plist)}

        self._pod_install(app_path)

        if self._build_cfg.get("clean_before_build", True):
            self._flutter_clean(app_path)

        ipa_path = self._build_ipa(app_path, export_plist)

        output_dir.mkdir(parents=True, exist_ok=True)
        if ipa_path:
            dest = output_dir / ipa_path.name
            shutil.copy2(str(ipa_path), str(dest))
            logger.info("  IPA → %s (%.1f MB)", dest, dest.stat().st_size / 1e6)
            return {"ipa": str(dest)}

        raise RuntimeError("iOS build completed but no IPA was produced")

    # ── Configuration ─────────────────────────────────────────────────────────

    def _write_export_options(self, app_path: Path) -> Path:
        """Write ExportOptions.plist and return its path."""
        team_id = self._ios_cfg.get("team_id", "XXXXXXXXXX")
        export_method = self._ios_cfg.get("export_method", "app-store")
        signing_style = "automatic" if not self._ios_cfg.get("provisioning_profile") else "manual"

        plist_content = _EXPORT_OPTIONS_TPL.format(
            export_method=export_method,
            team_id=team_id,
            signing_style=signing_style,
        )
        dest = app_path / "ios" / "ExportOptions.plist"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(plist_content, encoding="utf-8")
        logger.info("  ExportOptions.plist written → %s", dest)
        return dest

    def _configure_xcode_project(self, app_path: Path) -> None:
        """Patch Xcode project settings using ``xcconfig`` or direct plist edits."""
        # Update Info.plist
        info_plist = app_path / "ios" / "Runner" / "Info.plist"
        if info_plist.exists():
            self._patch_info_plist(info_plist)

        # Update project.pbxproj via sed-style substitution if needed
        pbxproj = app_path / "ios" / "Runner.xcodeproj" / "project.pbxproj"
        if pbxproj.exists():
            self._patch_pbxproj(pbxproj)

    def _patch_info_plist(self, plist_path: Path) -> None:
        """Update bundle identifier and version in Info.plist."""
        try:
            with open(plist_path, "rb") as fh:
                data = plistlib.load(fh)
        except Exception as exc:
            logger.warning("Could not parse Info.plist: %s", exc)
            return

        changed = False
        bundle_id = self._app_cfg.get("bundle_id", "")
        version = self._app_cfg.get("version", "")
        build_number = str(self._app_cfg.get("build_number", "1"))

        if bundle_id and data.get("CFBundleIdentifier") not in (bundle_id, "$(PRODUCT_BUNDLE_IDENTIFIER)"):
            data["CFBundleIdentifier"] = bundle_id
            changed = True
        if version and data.get("CFBundleShortVersionString") != version:
            data["CFBundleShortVersionString"] = version
            changed = True
        if data.get("CFBundleVersion") != build_number:
            data["CFBundleVersion"] = build_number
            changed = True

        if changed:
            with open(plist_path, "wb") as fh:
                plistlib.dump(data, fh)
            logger.info("  Info.plist updated")

    def _patch_pbxproj(self, pbxproj_path: Path) -> None:
        """Patch DEVELOPMENT_TEAM and IPHONEOS_DEPLOYMENT_TARGET."""
        content = pbxproj_path.read_text(encoding="utf-8")
        original = content

        team_id = self._ios_cfg.get("team_id", "")
        deploy_target = self._ios_cfg.get("deployment_target", "13.0")

        if team_id:
            content = re.sub(
                r"DEVELOPMENT_TEAM = [^;]+;",
                f"DEVELOPMENT_TEAM = {team_id};",
                content,
            )
        content = re.sub(
            r"IPHONEOS_DEPLOYMENT_TARGET = [^;]+;",
            f"IPHONEOS_DEPLOYMENT_TARGET = {deploy_target};",
            content,
        )

        if content != original:
            pbxproj_path.write_text(content, encoding="utf-8")
            logger.info("  project.pbxproj updated (team ID / deployment target)")

    # ── Build steps ───────────────────────────────────────────────────────────

    def _pod_install(self, app_path: Path) -> None:
        """Run ``pod install`` in the ios directory."""
        ios_dir = app_path / "ios"
        if not ios_dir.exists():
            logger.warning("ios/ directory not found — skipping pod install")
            return
        logger.info("Running pod install …")
        result = subprocess.run(
            ["pod", "install", "--repo-update"],
            cwd=str(ios_dir),
            capture_output=True,
            text=True,
            timeout=self._timeout,
        )
        if result.returncode != 0:
            logger.warning("pod install failed:\n%s", result.stderr[:1000])
        else:
            logger.info("  pod install — success")

    def _flutter_clean(self, app_path: Path) -> None:
        subprocess.run(
            ["flutter", "clean"],
            cwd=str(app_path),
            capture_output=True,
            timeout=120,
        )

    def _build_ipa(self, app_path: Path, export_plist: Path) -> Optional[Path]:
        """Run ``flutter build ipa`` and return the IPA path."""
        mode = self._build_cfg.get("mode", "release")
        cmd = [
            "flutter", "build", "ipa",
            f"--{mode}",
            f"--export-options-plist={export_plist}",
        ]
        cmd += self._extra_flags()

        logger.info("Building IPA (%s) …", mode)
        self._run_with_retry(cmd, app_path, "flutter build ipa")

        # Search for produced IPA
        matches = list((app_path / "build").rglob("*.ipa"))
        if matches:
            return matches[0]
        logger.warning("IPA not found after build")
        return None

    # ── Utilities ─────────────────────────────────────────────────────────────

    def _extra_flags(self) -> List[str]:
        flags: List[str] = []
        for key, val in self._build_cfg.get("dart_defines", {}).items():
            flags.append(f"--dart-define={key}={val}")
        flags += self._build_cfg.get("extra_flutter_flags", [])
        return flags

    def _run_with_retry(self, cmd: List[str], cwd: Path, label: str) -> None:
        for attempt in range(1, self._max_retries + 1):
            result = subprocess.run(
                cmd,
                cwd=str(cwd),
                capture_output=True,
                text=True,
                timeout=self._timeout,
            )
            if result.returncode == 0:
                logger.info("  %s — success", label)
                return
            logger.warning(
                "  %s attempt %d/%d failed (exit %d):\n%s",
                label,
                attempt,
                self._max_retries,
                result.returncode,
                (result.stdout + "\n" + result.stderr)[:2000],
            )
            if attempt < self._max_retries:
                delay = self._retry_delay * (2 ** (attempt - 1))
                logger.info("  Retrying in %d s …", delay)
                time.sleep(delay)

        raise RuntimeError(f"{label} failed after {self._max_retries} attempts")
