"""
validator.py — Pre-build and post-build validation.

Pre-build: checks that Flutter SDK, Android SDK, Xcode (macOS), and other
           required tools are present and meet minimum versions.
Post-build: verifies build artifacts exist and are structurally valid (ZIP),
            and confirms 100% file manifest coverage.
"""
from __future__ import annotations

import logging
import platform
import shutil
import subprocess
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional

from .environment_setup import EnvironmentSetup

logger = logging.getLogger(__name__)


@dataclass
class ValidationReport:
    """Result of a validation pass."""

    phase: str                        # "pre-build" | "post-build"
    passed: bool = True
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    details: dict = field(default_factory=dict)

    def fail(self, msg: str) -> None:
        self.passed = False
        self.errors.append(msg)
        logger.error("VALIDATION ERROR: %s", msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)
        logger.warning("VALIDATION WARNING: %s", msg)


class Validator:
    """Validate the build environment and produced artifacts."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._is_macos = platform.system() == "Darwin"

    # ── Public API ────────────────────────────────────────────────────────────

    def pre_build(self) -> ValidationReport:
        """Run pre-build environment checks."""
        report = ValidationReport(phase="pre-build")
        logger.info("=== Pre-Build Validation ===")

        env_setup = EnvironmentSetup(self._config)
        env_report = env_setup.check()

        if not env_report.all_required_met:
            for err in env_report.errors:
                report.fail(err)
        for warn in env_report.warnings:
            report.warn(warn)

        report.details["environment"] = {
            t.name: {"installed": t.installed, "version": t.version}
            for t in env_report.tools
        }

        # Validate config file completeness
        self._validate_config(report)

        if report.passed:
            logger.info("  Pre-build validation PASSED")
        else:
            logger.error("  Pre-build validation FAILED — see errors above")
        return report

    def post_build(
        self,
        manifest,
        artifacts: dict,
    ) -> ValidationReport:
        """Run post-build artifact checks.

        *manifest* is a :class:`~lib.repo_manager.RepoManifest` instance.
        *artifacts* is a dict with optional 'aab', 'apk', and 'ipa' keys.
        """
        report = ValidationReport(phase="post-build")
        logger.info("=== Post-Build Validation ===")

        # 1. Manifest coverage
        if not manifest.verify():
            report.fail(
                f"File manifest mismatch: {manifest.total_files} tracked vs "
                f"{manifest.filesystem_count} on disk"
            )
        else:
            logger.info("  ✔ File manifest: %d / %d files accounted for",
                        manifest.total_files, manifest.filesystem_count)

        # 2. Artifact checks
        for artifact_type in ("aab", "apk", "ipa"):
            path_str: Optional[str] = artifacts.get(artifact_type)
            if path_str:
                self._validate_artifact(report, Path(path_str), artifact_type)

        if not any(artifacts.get(k) for k in ("aab", "apk", "ipa")):
            report.fail("No build artifacts were produced")

        if report.passed:
            logger.info("  Post-build validation PASSED")
        else:
            logger.error("  Post-build validation FAILED — see errors above")

        report.details["artifacts"] = {k: v for k, v in artifacts.items() if v}
        return report

    # ── Private helpers ───────────────────────────────────────────────────────

    def _validate_config(self, report: ValidationReport) -> None:
        """Check that the config contains required fields."""
        app = self._config.get("app", {})
        if not app.get("bundle_id"):
            report.warn("app.bundle_id is not set in config.yaml")
        if not app.get("version"):
            report.warn("app.version is not set in config.yaml")
        if not self._config.get("repos"):
            report.fail("No repos defined in config.yaml")

    def _validate_artifact(
        self, report: ValidationReport, path: Path, artifact_type: str
    ) -> None:
        """Check that *path* exists and has a valid ZIP structure."""
        if not path.exists():
            report.fail(f"{artifact_type.upper()} not found: {path}")
            return

        size = path.stat().st_size
        if size < 1024:
            report.fail(f"{artifact_type.upper()} is suspiciously small ({size} bytes): {path}")
            return

        logger.info("  ✔ %s: %s (%.1f MB)", artifact_type.upper(), path.name, size / 1e6)

        # AAB, APK, and IPA are ZIP-based
        try:
            with zipfile.ZipFile(str(path), "r") as zf:
                names = zf.namelist()
            report.details[artifact_type] = {
                "path": str(path),
                "size_bytes": size,
                "zip_entries": len(names),
            }
            logger.info("    ZIP entries: %d", len(names))
        except zipfile.BadZipFile:
            report.fail(f"{artifact_type.upper()} is not a valid ZIP archive: {path}")
        except Exception as exc:
            report.warn(f"Could not inspect {artifact_type.upper()} ZIP: {exc}")

    def generate_report(
        self, pre_report: ValidationReport, post_report: ValidationReport
    ) -> dict:
        """Merge pre and post reports into a single summary dict."""
        return {
            "pre_build": {
                "passed": pre_report.passed,
                "errors": pre_report.errors,
                "warnings": pre_report.warnings,
                "details": pre_report.details,
            },
            "post_build": {
                "passed": post_report.passed,
                "errors": post_report.errors,
                "warnings": post_report.warnings,
                "details": post_report.details,
            },
            "overall_passed": pre_report.passed and post_report.passed,
        }
