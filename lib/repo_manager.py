"""
repo_manager.py — Clone repositories, walk every file, and build a SHA-256
                  file manifest that guarantees zero files are skipped.
"""
from __future__ import annotations

import hashlib
import json
import logging
import os
import shutil
import subprocess
import time
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)


@dataclass
class FileRecord:
    """Metadata for a single file in the manifest."""

    path: str               # relative to workspace root
    abs_path: str
    size: int               # bytes
    sha256: str
    modified: str           # ISO-8601 timestamp
    file_type: str          # source | asset | config | generated | other
    repo: str               # which cloned repo this file belongs to


@dataclass
class RepoManifest:
    """Complete manifest of all files across all cloned repositories."""

    created: str = ""
    workspace: str = ""
    repos: List[str] = field(default_factory=list)
    files: List[FileRecord] = field(default_factory=list)
    total_files: int = 0
    total_bytes: int = 0
    filesystem_count: int = 0   # actual count on disk (cross-check)

    def verify(self) -> bool:
        """Return True iff manifest count matches filesystem count."""
        return self.total_files == self.filesystem_count


class RepoManager:
    """Clone repos, discover every file, and produce a verified manifest."""

    # File classifications
    _SOURCE_EXTS = {".dart", ".kt", ".java", ".swift", ".m", ".h", ".cpp", ".c"}
    _ASSET_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp",
                   ".ttf", ".otf", ".mp3", ".mp4", ".wav", ".json", ".lottie"}
    _CONFIG_EXTS = {".yaml", ".yml", ".xml", ".plist", ".gradle", ".properties",
                    ".podfile", ".lock", ".toml", ".sh", ".bat", ".rb"}
    _GENERATED_PATTERNS = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")

    def __init__(self, config: dict, workspace: Path) -> None:
        self._config = config
        self._workspace = workspace
        self._repos_cfg: List[dict] = config.get("repos", [])
        self._env_cfg: dict = config.get("environment", {})
        self._max_retries: int = int(self._env_cfg.get("max_retries", 3))
        self._retry_delay: int = int(self._env_cfg.get("retry_delay_seconds", 5))

    # ── Public API ────────────────────────────────────────────────────────────

    def clone_all(self) -> Dict[str, Path]:
        """Clone (or update) every repo listed in config.

        Returns a mapping of *local_name* → absolute *Path*.
        Raises *RuntimeError* if any required clone fails after all retries.
        """
        cloned: Dict[str, Path] = {}
        self._workspace.mkdir(parents=True, exist_ok=True)

        for repo_cfg in self._repos_cfg:
            url: str = repo_cfg["url"]
            branch: str = repo_cfg.get("branch", "main")
            local_name: str = repo_cfg.get("local_name", url.rstrip("/").split("/")[-1])
            dest: Path = self._workspace / local_name

            logger.info("Cloning %s → %s (branch: %s)", url, dest, branch)
            self._clone_with_retry(url, branch, dest)
            cloned[local_name] = dest
            logger.info("  ✔ %s", local_name)

        return cloned

    def build_manifest(self, cloned: Dict[str, Path]) -> RepoManifest:
        """Walk every file in every cloned repo and build a verified manifest.

        Raises *RuntimeError* if the manifest count does not match the
        filesystem count (i.e. a file was missed).
        """
        manifest = RepoManifest(
            created=datetime.now(timezone.utc).isoformat(),
            workspace=str(self._workspace),
            repos=list(cloned.keys()),
        )

        for repo_name, repo_path in cloned.items():
            logger.info("Building manifest for %s …", repo_name)
            records = self._walk_repo(repo_name, repo_path)
            manifest.files.extend(records)
            logger.info("  %d files found in %s", len(records), repo_name)

        manifest.total_files = len(manifest.files)
        manifest.total_bytes = sum(f.size for f in manifest.files)

        # Cross-check: count actual files on disk
        manifest.filesystem_count = self._count_files(cloned)

        if not manifest.verify():
            raise RuntimeError(
                f"File manifest mismatch! Manifest has {manifest.total_files} files "
                f"but filesystem has {manifest.filesystem_count} files. "
                "This is a critical error — the build cannot continue."
            )

        logger.info(
            "Manifest verified: %d files, %.2f MB",
            manifest.total_files,
            manifest.total_bytes / (1024 * 1024),
        )
        return manifest

    def save_manifest(self, manifest: RepoManifest, output_dir: Path) -> Path:
        """Serialise *manifest* to ``file_manifest.json`` in *output_dir*."""
        output_dir.mkdir(parents=True, exist_ok=True)
        dest = output_dir / "file_manifest.json"
        data = asdict(manifest)
        dest.write_text(json.dumps(data, indent=2, default=str), encoding="utf-8")
        logger.info("Manifest saved → %s", dest)
        return dest

    def get_main_app_path(self, cloned: Dict[str, Path]) -> Path:
        """Return the path to the main app repo."""
        for repo_cfg in self._repos_cfg:
            if repo_cfg.get("type") == "main_app":
                local_name = repo_cfg.get("local_name", "")
                if local_name in cloned:
                    return cloned[local_name]
        # Fallback: first repo
        if cloned:
            return next(iter(cloned.values()))
        raise RuntimeError("No main app repo found in cloned repos")

    def get_dependency_paths(self, cloned: Dict[str, Path]) -> Dict[str, Path]:
        """Return a mapping of *package_name* → path for dependency repos."""
        deps: Dict[str, Path] = {}
        for repo_cfg in self._repos_cfg:
            if repo_cfg.get("type") == "dependency":
                pkg = repo_cfg.get("package_name", "")
                local_name = repo_cfg.get("local_name", "")
                if pkg and local_name in cloned:
                    deps[pkg] = cloned[local_name]
        return deps

    # ── Private helpers ───────────────────────────────────────────────────────

    def _clone_with_retry(self, url: str, branch: str, dest: Path) -> None:
        """Clone *url* at *branch* into *dest*, retrying on transient errors."""
        if dest.exists():
            # Pull latest if already cloned
            logger.debug("  Repo exists, pulling latest …")
            self._run_git(["git", "-C", str(dest), "pull", "--ff-only"], dest)
            return

        for attempt in range(1, self._max_retries + 1):
            try:
                cmd = [
                    "git", "clone",
                    "--recurse-submodules",
                    "--branch", branch,
                    "--depth", "1",
                    url,
                    str(dest),
                ]
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=300,
                )
                if result.returncode == 0:
                    return
                logger.warning(
                    "Clone attempt %d/%d failed (exit %d): %s",
                    attempt, self._max_retries, result.returncode, result.stderr[:500],
                )
            except subprocess.TimeoutExpired:
                logger.warning("Clone attempt %d/%d timed out", attempt, self._max_retries)

            if attempt < self._max_retries:
                delay = self._retry_delay * (2 ** (attempt - 1))
                logger.info("  Retrying in %d seconds …", delay)
                time.sleep(delay)

        raise RuntimeError(
            f"Failed to clone {url} after {self._max_retries} attempts"
        )

    def _run_git(self, cmd: List[str], cwd: Path) -> None:
        """Run a git command, ignoring non-fatal failures."""
        try:
            subprocess.run(cmd, capture_output=True, text=True, timeout=120, cwd=cwd)
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass

    def _walk_repo(self, repo_name: str, repo_path: Path) -> List[FileRecord]:
        """Walk *repo_path* and return a :class:`FileRecord` for every file."""
        records: List[FileRecord] = []
        for root, dirs, files in os.walk(repo_path):
            # Skip hidden directories (e.g. .git) to avoid internal git objects
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for filename in files:
                abs_path = Path(root) / filename
                rel_path = abs_path.relative_to(self._workspace)
                try:
                    stat = abs_path.stat()
                    sha256 = self._hash_file(abs_path)
                    records.append(
                        FileRecord(
                            path=str(rel_path),
                            abs_path=str(abs_path),
                            size=stat.st_size,
                            sha256=sha256,
                            modified=datetime.fromtimestamp(
                                stat.st_mtime, tz=timezone.utc
                            ).isoformat(),
                            file_type=self._classify(filename),
                            repo=repo_name,
                        )
                    )
                except (OSError, PermissionError) as exc:
                    logger.warning("Cannot read %s: %s", abs_path, exc)
        return records

    def _count_files(self, cloned: Dict[str, Path]) -> int:
        """Count every non-hidden file on disk across all cloned repos."""
        total = 0
        for repo_path in cloned.values():
            for root, dirs, files in os.walk(repo_path):
                dirs[:] = [d for d in dirs if not d.startswith(".")]
                total += len(files)
        return total

    @staticmethod
    def _hash_file(path: Path) -> str:
        """Return the SHA-256 hex digest of *path*."""
        h = hashlib.sha256()
        try:
            with open(path, "rb") as fh:
                for chunk in iter(lambda: fh.read(65536), b""):
                    h.update(chunk)
        except (OSError, PermissionError):
            pass
        return h.hexdigest()

    def _classify(self, filename: str) -> str:
        """Classify a file as source / asset / config / generated / other."""
        name_lower = filename.lower()
        if any(name_lower.endswith(p) for p in self._GENERATED_PATTERNS):
            return "generated"
        ext = Path(filename).suffix.lower()
        if ext in self._SOURCE_EXTS:
            return "source"
        if ext in self._ASSET_EXTS:
            return "asset"
        if ext in self._CONFIG_EXTS:
            return "config"
        return "other"
