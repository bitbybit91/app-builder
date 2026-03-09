#!/usr/bin/env python3
"""
app_builder.py — Autonomous Flutter/Dart mobile app build system.

Usage:
    python app_builder.py --config config.yaml
    python app_builder.py --config config.yaml --skip-ios
    python app_builder.py --config config.yaml --output-dir ./my-output

Exit codes:
    0 — build succeeded
    1 — build failed (see log for details)
    2 — invalid arguments / config
"""
from __future__ import annotations

import argparse
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import yaml

# ── Logging setup ─────────────────────────────────────────────────────────────

try:
    from colorama import Fore, Style, init as colorama_init
    colorama_init(autoreset=True)
    _HAS_COLORAMA = True
except ImportError:
    _HAS_COLORAMA = False


class _ColorFormatter(logging.Formatter):
    """A log formatter that adds colour when colorama is available."""

    _LEVEL_COLORS = {
        logging.DEBUG:    "",
        logging.INFO:     "",
        logging.WARNING:  "",
        logging.ERROR:    "",
        logging.CRITICAL: "",
    }

    def format(self, record: logging.LogRecord) -> str:
        msg = super().format(record)
        if not _HAS_COLORAMA:
            return msg
        if record.levelno >= logging.ERROR:
            return Fore.RED + msg + Style.RESET_ALL
        if record.levelno == logging.WARNING:
            return Fore.YELLOW + msg + Style.RESET_ALL
        if record.levelno == logging.INFO and msg.startswith("==="):
            return Fore.CYAN + msg + Style.RESET_ALL
        return msg


def _setup_logging(
    level: str, log_file: Optional[Path], colored: bool
) -> logging.Logger:
    root = logging.getLogger()
    root.setLevel(getattr(logging, level.upper(), logging.INFO))

    fmt = "%(asctime)s [%(levelname)s] %(message)s"
    date_fmt = "%H:%M:%S"

    # Console handler
    ch = logging.StreamHandler(sys.stdout)
    ch.setFormatter(
        _ColorFormatter(fmt, datefmt=date_fmt) if colored else logging.Formatter(fmt, datefmt=date_fmt)
    )
    root.addHandler(ch)

    # File handler
    if log_file:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        fh = logging.FileHandler(str(log_file), encoding="utf-8")
        fh.setFormatter(logging.Formatter(fmt, datefmt=date_fmt))
        root.addHandler(fh)

    return logging.getLogger(__name__)


# ── CLI ───────────────────────────────────────────────────────────────────────

def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="app_builder",
        description="Autonomous Flutter/Dart mobile app build system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--config", "-c",
        default="config.yaml",
        metavar="FILE",
        help="Path to YAML config file (default: config.yaml)",
    )
    parser.add_argument(
        "--output-dir", "-o",
        metavar="DIR",
        help="Override build.output_dir from config",
    )
    parser.add_argument(
        "--skip-android",
        action="store_true",
        help="Skip Android build",
    )
    parser.add_argument(
        "--skip-ios",
        action="store_true",
        help="Skip iOS build",
    )
    parser.add_argument(
        "--skip-validation",
        action="store_true",
        help="Skip pre-build environment validation (not recommended)",
    )
    parser.add_argument(
        "--no-clean",
        action="store_true",
        help="Skip `flutter clean` before building",
    )
    parser.add_argument(
        "--log-level",
        default=None,
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Override logging.level from config",
    )
    return parser.parse_args()


# ── Config loading ────────────────────────────────────────────────────────────

def _load_config(config_path: Path) -> dict:
    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}", file=sys.stderr)
        sys.exit(2)
    try:
        with open(config_path, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        print(f"ERROR: Invalid YAML in {config_path}: {exc}", file=sys.stderr)
        sys.exit(2)
    if not isinstance(data, dict):
        print(f"ERROR: Config file {config_path} must be a YAML mapping", file=sys.stderr)
        sys.exit(2)
    return data


# ── Main pipeline ─────────────────────────────────────────────────────────────

def main() -> int:
    args = _parse_args()
    config_path = Path(args.config).resolve()
    config = _load_config(config_path)

    # Apply CLI overrides to config
    if args.output_dir:
        config.setdefault("build", {})["output_dir"] = args.output_dir
    if args.no_clean:
        config.setdefault("build", {})["clean_before_build"] = False
    if args.skip_android:
        config.setdefault("build", {})["build_android"] = False
    if args.skip_ios:
        config.setdefault("build", {})["build_ios"] = False

    build_cfg: dict = config.get("build", {})
    log_cfg: dict = config.get("logging", {})
    log_level = args.log_level or log_cfg.get("level", "INFO")
    output_dir = Path(build_cfg.get("output_dir", "./output")).resolve()
    log_file = output_dir / log_cfg.get("log_file", "build.log")
    colored = log_cfg.get("colored_console", True)

    logger = _setup_logging(log_level, log_file, colored)
    logger.info("=== app_builder — Autonomous Flutter Build System ===")
    logger.info("Config: %s", config_path)
    logger.info("Output: %s", output_dir)

    start_time = datetime.now(timezone.utc)

    # Workspace directory — next to the config file
    workspace = config_path.parent / "repos"

    # Late imports (after logging is set up)
    from lib.repo_manager import RepoManager
    from lib.dependency_resolver import DependencyResolver
    from lib.code_generator import CodeGenerator
    from lib.android_builder import AndroidBuilder
    from lib.ios_builder import iOSBuilder
    from lib.asset_processor import AssetProcessor
    from lib.fastlane_manager import FastlaneManager
    from lib.validator import Validator
    from lib.report_generator import ReportGenerator

    artifacts: dict = {}
    manifest = None
    pre_report = None
    post_report = None
    asset_report: dict = {}

    try:
        # ── 1. Environment validation ─────────────────────────────────────────
        validator = Validator(config)
        if not args.skip_validation:
            pre_report = validator.pre_build()
            if not pre_report.passed:
                logger.error("Pre-build validation failed. Fix errors above and re-run.")
                # Still continue — build may partially work; full abort is opt-in.
        else:
            logger.warning("Pre-build validation skipped (--skip-validation)")
            from lib.validator import ValidationReport
            pre_report = ValidationReport(phase="pre-build")

        # ── 2. Clone repositories ─────────────────────────────────────────────
        logger.info("=== Repository Cloning ===")
        repo_manager = RepoManager(config, workspace)
        cloned = repo_manager.clone_all()

        # ── 3. Build file manifest ────────────────────────────────────────────
        logger.info("=== Building File Manifest ===")
        manifest = repo_manager.build_manifest(cloned)
        repo_manager.save_manifest(manifest, output_dir)

        # ── 4. Resolve dependencies ───────────────────────────────────────────
        logger.info("=== Dependency Resolution ===")
        app_path = repo_manager.get_main_app_path(cloned)
        dep_paths = repo_manager.get_dependency_paths(cloned)
        resolver = DependencyResolver(config)
        resolver.resolve(app_path, dep_paths)

        # ── 5. Code generation ────────────────────────────────────────────────
        logger.info("=== Code Generation ===")
        tool_paths = {
            repo_cfg.get("local_name", ""): cloned[repo_cfg["local_name"]]
            for repo_cfg in config.get("repos", [])
            if repo_cfg.get("type") == "tool" and repo_cfg.get("local_name") in cloned
        }
        code_gen = CodeGenerator(config)
        code_gen.run_all(app_path, tool_paths)

        # ── 6. Asset processing ───────────────────────────────────────────────
        logger.info("=== Asset Processing ===")
        asset_proc = AssetProcessor(config)
        asset_report = asset_proc.process(app_path)

        # ── 7. Fastlane setup ─────────────────────────────────────────────────
        fl_manager = FastlaneManager(config)
        fl_manager.setup(app_path)

        # ── 8. Android build ──────────────────────────────────────────────────
        if build_cfg.get("build_android", True):
            android_builder = AndroidBuilder(config)
            android_artifacts = android_builder.build(app_path, output_dir / "android")
            artifacts.update(android_artifacts)
        else:
            logger.info("Android build skipped (build_android=false)")

        # ── 9. iOS build ──────────────────────────────────────────────────────
        if build_cfg.get("build_ios", True):
            ios_builder = iOSBuilder(config)
            ios_artifacts = ios_builder.build(app_path, output_dir / "ios")
            artifacts.update(ios_artifacts)
        else:
            logger.info("iOS build skipped (build_ios=false)")

        # ── 10. Post-build validation ─────────────────────────────────────────
        logger.info("=== Post-Build Validation ===")
        post_report = validator.post_build(manifest, artifacts)

    except KeyboardInterrupt:
        logger.warning("Build interrupted by user")
        return 1
    except Exception as exc:  # noqa: BLE001
        logger.exception("Build failed with unhandled exception: %s", exc)
        post_report = None

    # ── 11. Generate report ───────────────────────────────────────────────────
    logger.info("=== Generating Reports ===")
    if manifest is not None:
        validation_summary: dict = {}
        if pre_report and post_report:
            validation_summary = validator.generate_report(pre_report, post_report)
        elif pre_report:
            from lib.validator import ValidationReport
            validation_summary = validator.generate_report(
                pre_report, ValidationReport(phase="post-build")
            )

        report_gen = ReportGenerator(config)
        report_paths = report_gen.generate(
            output_dir=output_dir,
            manifest=manifest,
            validation_report=validation_summary,
            artifacts=artifacts,
            start_time=start_time,
            asset_report=asset_report,
        )
        logger.info("Report: %s", report_paths.get("html", ""))

    # ── Final status ──────────────────────────────────────────────────────────
    overall_ok = (
        post_report is not None
        and post_report.passed
        and bool(artifacts)
    )

    if overall_ok:
        logger.info("=== BUILD SUCCEEDED ===")
        for k, v in artifacts.items():
            logger.info("  %s → %s", k.upper(), v)
        return 0
    else:
        logger.error("=== BUILD FAILED ===")
        if post_report:
            for err in post_report.errors:
                logger.error("  %s", err)
        return 1


if __name__ == "__main__":
    sys.exit(main())
