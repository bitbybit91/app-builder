"""
dependency_resolver.py — Rewrite pubspec.yaml dependency entries to use local
                          path: references for companion repos, then run
                          `flutter pub get` to resolve everything.
"""
from __future__ import annotations

import logging
import re
import subprocess
import time
from pathlib import Path
from typing import Dict, List

import yaml

logger = logging.getLogger(__name__)


class DependencyResolver:
    """Wire local repo paths into pubspec.yaml and resolve all dependencies."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._env_cfg = config.get("environment", {})
        self._max_retries: int = int(self._env_cfg.get("max_retries", 3))
        self._retry_delay: int = int(self._env_cfg.get("retry_delay_seconds", 5))
        self._timeout: int = int(self._env_cfg.get("subprocess_timeout", 600))

    # ── Public API ────────────────────────────────────────────────────────────

    def resolve(self, app_path: Path, dependency_paths: Dict[str, Path]) -> None:
        """
        Rewrite *app_path*/pubspec.yaml to use local path references for
        *dependency_paths* (mapping of package_name → local path), then run
        ``flutter pub get``.

        Raises :class:`RuntimeError` if pub get fails after all retries.
        """
        pubspec_path = app_path / "pubspec.yaml"
        if not pubspec_path.exists():
            raise RuntimeError(f"pubspec.yaml not found at {pubspec_path}")

        if dependency_paths:
            logger.info("Rewriting pubspec.yaml dependency paths …")
            self._rewrite_pubspec(pubspec_path, dependency_paths)
        else:
            logger.info("No local dependencies to wire — skipping pubspec rewrite")

        logger.info("Running `flutter pub get` …")
        self._pub_get(app_path)

        logger.info("Validating dependency resolution …")
        self._validate(app_path)

    # ── Private helpers ───────────────────────────────────────────────────────

    def _rewrite_pubspec(
        self, pubspec_path: Path, dependency_paths: Dict[str, Path]
    ) -> None:
        """Replace hosted / git dependency entries with local ``path:`` entries."""
        raw = pubspec_path.read_text(encoding="utf-8")

        # Back up original
        backup = pubspec_path.with_suffix(".yaml.orig")
        if not backup.exists():
            backup.write_text(raw, encoding="utf-8")
            logger.debug("  pubspec.yaml backed up → %s", backup)

        data = yaml.safe_load(raw)

        changed = False
        for section in ("dependencies", "dev_dependencies"):
            pkg_section: dict = data.get(section, {}) or {}
            for pkg_name, local_path in dependency_paths.items():
                if pkg_name in pkg_section:
                    old_val = pkg_section[pkg_name]
                    new_val = {"path": str(local_path)}
                    pkg_section[pkg_name] = new_val
                    logger.info(
                        "  Wired %s: %s → path: %s",
                        pkg_name,
                        _summarise(old_val),
                        local_path,
                    )
                    changed = True

        if not changed:
            logger.info("  No matching dependencies found in pubspec.yaml")
            return

        # Re-serialise, preserving a clean YAML structure
        updated_yaml = yaml.dump(data, default_flow_style=False, allow_unicode=True, sort_keys=False)
        pubspec_path.write_text(updated_yaml, encoding="utf-8")
        logger.info("  pubspec.yaml updated")

    def _pub_get(self, app_path: Path) -> None:
        """Run ``flutter pub get`` with retry logic."""
        for attempt in range(1, self._max_retries + 1):
            logger.debug("  flutter pub get — attempt %d/%d", attempt, self._max_retries)
            result = subprocess.run(
                ["flutter", "pub", "get"],
                cwd=str(app_path),
                capture_output=True,
                text=True,
                timeout=self._timeout,
            )
            if result.returncode == 0:
                logger.info("  flutter pub get — success")
                return
            logger.warning(
                "  flutter pub get attempt %d/%d failed:\n%s",
                attempt,
                self._max_retries,
                result.stderr[:1000],
            )
            if attempt < self._max_retries:
                delay = self._retry_delay * (2 ** (attempt - 1))
                logger.info("  Retrying in %d s …", delay)
                time.sleep(delay)

        raise RuntimeError(
            f"flutter pub get failed after {self._max_retries} attempts. "
            "See log for details."
        )

    def _validate(self, app_path: Path) -> None:
        """Run ``flutter pub deps`` to confirm all deps resolved."""
        result = subprocess.run(
            ["flutter", "pub", "deps"],
            cwd=str(app_path),
            capture_output=True,
            text=True,
            timeout=self._timeout,
        )
        if result.returncode != 0:
            raise RuntimeError(
                "flutter pub deps validation failed:\n" + result.stderr[:2000]
            )
        logger.info("  All dependencies resolved successfully")

    # ── Utility ───────────────────────────────────────────────────────────────

    def parse_pubspec_dependencies(self, app_path: Path) -> Dict[str, object]:
        """Return the merged dependencies + dev_dependencies from pubspec.yaml."""
        pubspec_path = app_path / "pubspec.yaml"
        if not pubspec_path.exists():
            return {}
        data = yaml.safe_load(pubspec_path.read_text(encoding="utf-8")) or {}
        deps: Dict[str, object] = {}
        deps.update(data.get("dependencies", {}) or {})
        deps.update(data.get("dev_dependencies", {}) or {})
        return deps


def _summarise(value: object) -> str:
    """Return a short string summary of a pubspec dependency value."""
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        if "version" in value:
            return f"^{value['version']}"
        if "git" in value:
            return f"git: {value['git'].get('url', '?')}"
        if "path" in value:
            return f"path: {value['path']}"
    return str(value)
