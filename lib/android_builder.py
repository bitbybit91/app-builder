"""
android_builder.py — Configure and build the Android AAB and APK artifacts.

Handles build.gradle configuration, signing setup, AndroidManifest permissions,
and invokes `flutter build appbundle` / `flutter build apk`.
"""
from __future__ import annotations

import logging
import os
import re
import subprocess
import time
from pathlib import Path
from typing import List, Optional

logger = logging.getLogger(__name__)

# ── Gradle template fragments ─────────────────────────────────────────────────

_KEY_PROPERTIES_TPL = """\
storePassword={keystore_password}
keyPassword={key_password}
keyAlias={keystore_alias}
storeFile={keystore_path}
"""

_SIGNING_CONFIG_BLOCK = """
    signingConfigs {
        release {
            def keystoreProperties = new Properties()
            def keystorePropertiesFile = rootProject.file('key.properties')
            if (keystorePropertiesFile.exists()) {
                keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
            }
            keyAlias       keystoreProperties['keyAlias']
            keyPassword    keystoreProperties['keyPassword']
            storeFile      keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword  keystoreProperties['storePassword']
        }
    }
"""


class AndroidBuilder:
    """Build signed (or unsigned) Android AAB and APK artifacts."""

    def __init__(self, config: dict) -> None:
        self._config = config
        self._android_cfg: dict = config.get("android", {})
        self._app_cfg: dict = config.get("app", {})
        self._build_cfg: dict = config.get("build", {})
        self._env_cfg: dict = config.get("environment", {})
        self._max_retries: int = int(self._env_cfg.get("max_retries", 3))
        self._retry_delay: int = int(self._env_cfg.get("retry_delay_seconds", 5))
        self._timeout: int = int(self._env_cfg.get("subprocess_timeout", 600))

    # ── Public API ────────────────────────────────────────────────────────────

    def build(self, app_path: Path, output_dir: Path) -> dict:
        """Configure and build Android artifacts.

        Returns a dict with paths to produced artifacts.
        Raises :class:`RuntimeError` on failure.
        """
        logger.info("=== Android Build ===")

        self._configure_build_gradle(app_path)
        self._configure_manifest(app_path)
        if self._has_signing_config():
            self._write_key_properties(app_path)

        if self._build_cfg.get("clean_before_build", True):
            self._flutter_clean(app_path)

        artifacts: dict = {}

        # Build AAB
        aab_path = self._build_aab(app_path)
        if aab_path:
            dest = output_dir / aab_path.name
            output_dir.mkdir(parents=True, exist_ok=True)
            import shutil
            shutil.copy2(str(aab_path), str(dest))
            artifacts["aab"] = str(dest)
            logger.info("  AAB → %s (%.1f MB)", dest, dest.stat().st_size / 1e6)

        # Build APK
        apk_path = self._build_apk(app_path)
        if apk_path:
            dest = output_dir / apk_path.name
            import shutil
            shutil.copy2(str(apk_path), str(dest))
            artifacts["apk"] = str(dest)
            logger.info("  APK → %s (%.1f MB)", dest, dest.stat().st_size / 1e6)

        if not artifacts:
            raise RuntimeError("Android build produced no artifacts")

        return artifacts

    # ── Configuration helpers ─────────────────────────────────────────────────

    def _configure_build_gradle(self, app_path: Path) -> None:
        """Patch android/app/build.gradle with config values."""
        gradle_path = app_path / "android" / "app" / "build.gradle"
        if not gradle_path.exists():
            logger.warning("android/app/build.gradle not found — skipping Gradle config")
            return

        content = gradle_path.read_text(encoding="utf-8")
        original = content

        content = _replace_gradle_value(content, "applicationId", f'"{self._app_cfg.get("bundle_id", "com.example.app")}"')
        content = _replace_gradle_value(content, "versionCode", str(self._app_cfg.get("build_number", 1)))
        content = _replace_gradle_value(content, "versionName", f'"{self._app_cfg.get("version", "1.0.0")}"')
        content = _replace_gradle_value(content, "minSdkVersion", str(self._android_cfg.get("min_sdk_version", 21)))
        content = _replace_gradle_value(content, "targetSdkVersion", str(self._android_cfg.get("target_sdk_version", 34)))
        content = _replace_gradle_value(content, "compileSdkVersion", str(self._android_cfg.get("compile_sdk_version", 34)))

        if self._android_cfg.get("enable_multidex", False):
            if "multiDexEnabled" not in content:
                content = content.replace(
                    "defaultConfig {",
                    "defaultConfig {\n        multiDexEnabled true",
                    1,
                )

        # Inject signing config if keystore is configured
        if self._has_signing_config() and "signingConfigs" not in content:
            content = content.replace(
                "android {",
                "android {" + _SIGNING_CONFIG_BLOCK,
                1,
            )
            # Apply release signing
            content = re.sub(
                r"(buildTypes\s*\{[^}]*release\s*\{)",
                r"\1\n            signingConfig signingConfigs.release",
                content,
                flags=re.DOTALL,
            )

        if content != original:
            gradle_path.write_text(content, encoding="utf-8")
            logger.info("  android/app/build.gradle updated")
        else:
            logger.info("  android/app/build.gradle — no changes needed")

    def _configure_manifest(self, app_path: Path) -> None:
        """Add extra permissions to AndroidManifest.xml."""
        manifest_path = app_path / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
        if not manifest_path.exists():
            logger.warning("AndroidManifest.xml not found — skipping permissions config")
            return

        content = manifest_path.read_text(encoding="utf-8")
        extra_perms: List[str] = self._android_cfg.get("extra_permissions", [])
        changed = False
        for perm in extra_perms:
            tag = f'<uses-permission android:name="{perm}"/>'
            if tag not in content:
                content = content.replace(
                    "<manifest",
                    f'<manifest',
                    1,
                )
                # Insert before first <application tag
                content = content.replace(
                    "<application",
                    f'{tag}\n    <application',
                    1,
                )
                changed = True

        if changed:
            manifest_path.write_text(content, encoding="utf-8")
            logger.info("  AndroidManifest.xml updated with permissions")

    def _write_key_properties(self, app_path: Path) -> None:
        """Write android/key.properties for signing."""
        props = _KEY_PROPERTIES_TPL.format(
            keystore_password=self._android_cfg.get("keystore_password", ""),
            key_password=self._android_cfg.get("key_password", ""),
            keystore_alias=self._android_cfg.get("keystore_alias", ""),
            keystore_path=self._android_cfg.get("keystore_path", ""),
        )
        key_props = app_path / "android" / "key.properties"
        key_props.write_text(props, encoding="utf-8")
        logger.info("  android/key.properties written")

    # ── Build steps ───────────────────────────────────────────────────────────

    def _flutter_clean(self, app_path: Path) -> None:
        logger.info("Running flutter clean …")
        subprocess.run(
            ["flutter", "clean"],
            cwd=str(app_path),
            capture_output=True,
            timeout=120,
        )

    def _build_aab(self, app_path: Path) -> Optional[Path]:
        """Build the release AAB and return its path."""
        mode = self._build_cfg.get("mode", "release")
        cmd = ["flutter", "build", "appbundle", f"--{mode}"]
        cmd += self._extra_flags()

        logger.info("Building AAB (%s) …", mode)
        self._run_with_retry(cmd, app_path, "flutter build appbundle")

        candidate = app_path / "build" / "app" / "outputs" / "bundle" / f"{mode}" / f"app-{mode}.aab"
        if candidate.exists():
            return candidate

        # Fallback glob
        matches = list((app_path / "build").rglob("*.aab"))
        if matches:
            return matches[0]
        logger.warning("AAB not found after build")
        return None

    def _build_apk(self, app_path: Path) -> Optional[Path]:
        """Build the release APK and return its path."""
        mode = self._build_cfg.get("mode", "release")
        cmd = ["flutter", "build", "apk", f"--{mode}"]
        cmd += self._extra_flags()

        logger.info("Building APK (%s) …", mode)
        self._run_with_retry(cmd, app_path, "flutter build apk")

        candidate = app_path / "build" / "app" / "outputs" / "flutter-apk" / f"app-{mode}.apk"
        if candidate.exists():
            return candidate

        matches = list((app_path / "build").rglob("*.apk"))
        if matches:
            return matches[0]
        logger.warning("APK not found after build")
        return None

    # ── Utilities ─────────────────────────────────────────────────────────────

    def _has_signing_config(self) -> bool:
        return bool(self._android_cfg.get("keystore_path"))

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


# ── Gradle helpers ────────────────────────────────────────────────────────────

def _replace_gradle_value(content: str, key: str, value: str) -> str:
    """Replace a key value pair in a Gradle file, or add it if missing."""
    pattern = rf"(\b{re.escape(key)}\s+)[^\n]+"
    replacement = rf"\g<1>{value}"
    new_content, count = re.subn(pattern, replacement, content)
    if count == 0:
        logger.debug("Gradle key %r not found — not injected", key)
    return new_content
