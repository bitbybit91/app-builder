"""
code_generator.py — Run code generation tools: build_runner, ARB/locale
                    generation, and any custom generator scripts found in repos.
"""
from __future__ import annotations

import logging
import os
import subprocess
import time
from pathlib import Path
from typing import List, Optional

logger = logging.getLogger(__name__)


class CodeGenerator:
    """Orchestrate all code generation steps for a Flutter/Dart project."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._env_cfg = config.get("environment", {})
        self._max_retries: int = int(self._env_cfg.get("max_retries", 3))
        self._retry_delay: int = int(self._env_cfg.get("retry_delay_seconds", 5))
        self._timeout: int = int(self._env_cfg.get("subprocess_timeout", 600))

    # ── Public API ────────────────────────────────────────────────────────────

    def run_all(self, app_path: Path, tool_paths: Optional[dict] = None) -> None:
        """Run all applicable code generation steps for *app_path*.

        *tool_paths* is a mapping of tool repo local_name → Path for any
        companion tool repos (e.g. dart-json-arb-json-converter).
        """
        logger.info("Starting code generation …")

        self._run_build_runner(app_path)
        self._run_arb_generation(app_path, tool_paths or {})
        self._run_custom_generators(app_path)

        logger.info("Code generation complete")

    # ── Private helpers ───────────────────────────────────────────────────────

    def _run_build_runner(self, app_path: Path) -> None:
        """Run ``flutter pub run build_runner build --delete-conflicting-outputs``."""
        # Check if build_runner is listed in pubspec.yaml
        pubspec = app_path / "pubspec.yaml"
        if pubspec.exists() and "build_runner" not in pubspec.read_text(encoding="utf-8"):
            logger.info("build_runner not in pubspec.yaml — skipping")
            return

        logger.info("Running build_runner …")
        cmd = [
            "flutter",
            "pub",
            "run",
            "build_runner",
            "build",
            "--delete-conflicting-outputs",
        ]
        self._run_with_retry(cmd, app_path, "build_runner")

        # Validate some generated files exist
        generated = list(app_path.rglob("*.g.dart")) + list(app_path.rglob("*.freezed.dart"))
        if generated:
            logger.info("  Generated %d file(s) (*.g.dart / *.freezed.dart)", len(generated))
        else:
            logger.info("  No *.g.dart / *.freezed.dart files generated (may be expected)")

    def _run_arb_generation(self, app_path: Path, tool_paths: dict) -> None:
        """Generate ARB locale files if the json-arb converter tool is present."""
        # Look for the dart-json-arb-json-converter tool
        converter_path: Optional[Path] = None
        for local_name, path in tool_paths.items():
            if "arb" in local_name.lower() or "json-converter" in local_name.lower():
                converter_path = path
                break

        if converter_path is None:
            logger.info("ARB converter tool not found — skipping ARB generation")
            return

        # Look for JSON locale files in the main app
        locale_dirs = list(app_path.rglob("assets/locales")) + list(app_path.rglob("assets/i18n"))
        if not locale_dirs:
            logger.info("No locale asset directories found — skipping ARB generation")
            return

        logger.info("Running ARB/locale generation …")
        pubspec = converter_path / "pubspec.yaml"
        if pubspec.exists():
            # Activate and run via dart pub global
            logger.info("  Running dart pub get in converter tool …")
            subprocess.run(
                ["flutter", "pub", "get"],
                cwd=str(converter_path),
                capture_output=True,
                text=True,
                timeout=self._timeout,
            )

        # Run the converter for each locale directory found
        for locale_dir in locale_dirs:
            logger.info("  Processing locales in %s …", locale_dir)
            main_dart = converter_path / "bin" / "main.dart"
            if main_dart.exists():
                cmd = ["dart", str(main_dart), str(locale_dir)]
                result = subprocess.run(
                    cmd,
                    cwd=str(app_path),
                    capture_output=True,
                    text=True,
                    timeout=self._timeout,
                )
                if result.returncode != 0:
                    logger.warning("  ARB generation warning: %s", result.stderr[:500])
                else:
                    logger.info("  ARB generation succeeded for %s", locale_dir)

    def _run_custom_generators(self, app_path: Path) -> None:
        """Run any ``generate.sh`` / ``codegen.sh`` scripts in the app repo."""
        scripts = (
            list(app_path.rglob("generate.sh"))
            + list(app_path.rglob("codegen.sh"))
            + list(app_path.rglob("run_build_runner.sh"))
        )
        if not scripts:
            logger.info("No custom generator scripts found")
            return

        for script in scripts:
            logger.info("Running custom generator: %s", script)
            script.chmod(script.stat().st_mode | 0o111)  # ensure executable
            result = subprocess.run(
                [str(script)],
                cwd=str(script.parent),
                capture_output=True,
                text=True,
                timeout=self._timeout,
            )
            if result.returncode != 0:
                logger.warning(
                    "Custom generator %s returned exit code %d:\n%s",
                    script.name,
                    result.returncode,
                    result.stderr[:500],
                )
            else:
                logger.info("  %s — success", script.name)

    def _run_with_retry(
        self, cmd: List[str], cwd: Path, label: str
    ) -> None:
        """Run *cmd* in *cwd* with retry logic; raise on final failure."""
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
                result.stderr[:1000],
            )
            if attempt < self._max_retries:
                delay = self._retry_delay * (2 ** (attempt - 1))
                logger.info("  Retrying in %d s …", delay)
                time.sleep(delay)

        raise RuntimeError(
            f"{label} failed after {self._max_retries} attempts. See log for details."
        )
