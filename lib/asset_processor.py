"""
asset_processor.py — Validate and process assets: icons, splash screens,
                      fonts, images, and all files referenced in pubspec.yaml.
"""
from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, List, Tuple

import yaml

logger = logging.getLogger(__name__)

# Required Android adaptive icon sizes (density → pixel size)
_ANDROID_ICON_SIZES: Dict[str, int] = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Required iOS App Icon sizes (points × scale → pixel size)
_IOS_ICON_SIZES: List[Tuple[str, int]] = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("ItunesArtwork@2x.png", 1024),
]


class AssetProcessor:
    """Validate assets and track them in the manifest."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._warnings: List[str] = []
        self._errors: List[str] = []

    # ── Public API ────────────────────────────────────────────────────────────

    def process(self, app_path: Path) -> dict:
        """Validate and process all assets in *app_path*.

        Returns a report dict with counts and any warnings / errors.
        """
        logger.info("=== Asset Processing ===")
        report: dict = {
            "referenced_assets": 0,
            "missing_assets": [],
            "android_icons": {},
            "ios_icons": {},
            "warnings": [],
            "errors": [],
        }

        pubspec_assets = self._collect_pubspec_assets(app_path)
        report["referenced_assets"] = len(pubspec_assets)

        missing = self._verify_referenced_assets(app_path, pubspec_assets)
        report["missing_assets"] = missing
        if missing:
            for m in missing:
                logger.warning("  Missing asset: %s", m)
            self._warnings.append(f"{len(missing)} asset(s) referenced in pubspec.yaml are missing")

        report["android_icons"] = self._check_android_icons(app_path)
        report["ios_icons"] = self._check_ios_icons(app_path)

        report["warnings"] = self._warnings
        report["errors"] = self._errors
        logger.info(
            "  Assets: %d referenced, %d missing",
            report["referenced_assets"],
            len(report["missing_assets"]),
        )
        return report

    # ── Private helpers ───────────────────────────────────────────────────────

    def _collect_pubspec_assets(self, app_path: Path) -> List[str]:
        """Return list of asset paths declared in pubspec.yaml."""
        pubspec_path = app_path / "pubspec.yaml"
        if not pubspec_path.exists():
            return []
        try:
            data = yaml.safe_load(pubspec_path.read_text(encoding="utf-8")) or {}
        except yaml.YAMLError:
            return []

        flutter_section: dict = data.get("flutter", {}) or {}
        raw_assets: list = flutter_section.get("assets", []) or []
        assets: List[str] = []
        for entry in raw_assets:
            if isinstance(entry, str):
                assets.append(entry)
        return assets

    def _verify_referenced_assets(
        self, app_path: Path, assets: List[str]
    ) -> List[str]:
        """Return list of declared assets that do not exist on disk."""
        missing: List[str] = []
        for asset_path in assets:
            full_path = app_path / asset_path
            # Directories are allowed (Flutter picks up all files within)
            if not full_path.exists():
                missing.append(asset_path)
        return missing

    def _check_android_icons(self, app_path: Path) -> dict:
        """Check Android launcher icon densities."""
        res_dir = app_path / "android" / "app" / "src" / "main" / "res"
        result: dict = {}
        if not res_dir.exists():
            return result

        for density, expected_size in _ANDROID_ICON_SIZES.items():
            icon_dir = res_dir / density
            if not icon_dir.exists():
                result[density] = "missing directory"
                self._warnings.append(f"Android icon directory missing: {density}")
                continue
            # Look for ic_launcher.png
            icon = icon_dir / "ic_launcher.png"
            if icon.exists():
                result[density] = f"present ({icon.stat().st_size} bytes)"
            else:
                # Try foreground/background adaptive icons
                fg = icon_dir / "ic_launcher_foreground.png"
                bg = icon_dir / "ic_launcher_background.png"
                if fg.exists() and bg.exists():
                    result[density] = "adaptive icon present"
                else:
                    result[density] = "ic_launcher.png missing"
                    self._warnings.append(
                        f"Android icon missing for density: {density}"
                    )

        return result

    def _check_ios_icons(self, app_path: Path) -> dict:
        """Check iOS App Icon set."""
        appiconset = (
            app_path / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
        )
        result: dict = {}
        if not appiconset.exists():
            self._warnings.append("iOS AppIcon.appiconset not found")
            return result

        for filename, _expected_px in _IOS_ICON_SIZES:
            icon_file = appiconset / filename
            if icon_file.exists():
                result[filename] = f"present ({icon_file.stat().st_size} bytes)"
            else:
                result[filename] = "missing"
                self._warnings.append(f"iOS icon missing: {filename}")

        return result
