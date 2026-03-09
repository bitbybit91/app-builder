"""
report_generator.py — Generate HTML and JSON build reports.

The HTML report is rendered from ``templates/report.html`` (Jinja2).
The JSON report is a machine-readable companion file.
"""
from __future__ import annotations

import json
import logging
import platform
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class ReportGenerator:
    """Produce HTML and JSON build reports."""

    def __init__(self, config: dict) -> None:
        self._config = config
        # Locate the templates directory relative to this file
        self._template_dir = Path(__file__).parent.parent / "templates"

    # ── Public API ────────────────────────────────────────────────────────────

    def generate(
        self,
        output_dir: Path,
        manifest,
        validation_report: dict,
        artifacts: dict,
        start_time: datetime,
        asset_report: Optional[dict] = None,
    ) -> dict:
        """Render both HTML and JSON reports into *output_dir*.

        Returns a dict with ``html`` and ``json`` keys pointing to the files.
        """
        output_dir.mkdir(parents=True, exist_ok=True)
        end_time = datetime.now(timezone.utc)
        duration_s = (end_time - start_time).total_seconds()

        context = self._build_context(
            manifest=manifest,
            validation_report=validation_report,
            artifacts=artifacts,
            start_time=start_time,
            end_time=end_time,
            duration_s=duration_s,
            asset_report=asset_report or {},
        )

        json_path = self._write_json(output_dir, context)
        html_path = self._write_html(output_dir, context)

        logger.info("  Build report (HTML) → %s", html_path)
        logger.info("  Build report (JSON) → %s", json_path)
        return {"html": str(html_path), "json": str(json_path)}

    # ── Builders ──────────────────────────────────────────────────────────────

    def _build_context(
        self,
        manifest,
        validation_report: dict,
        artifacts: dict,
        start_time: datetime,
        end_time: datetime,
        duration_s: float,
        asset_report: dict,
    ) -> dict:
        """Assemble the template context / JSON payload."""
        flutter_version = self._flutter_version()
        overall_passed = validation_report.get("overall_passed", False)
        status = "PASSED" if overall_passed else "FAILED"

        # Summarise file types
        type_counts: Dict[str, int] = {}
        for record in manifest.files:
            type_counts[record.file_type] = type_counts.get(record.file_type, 0) + 1

        return {
            "app_name": self._config.get("app", {}).get("name", "Unknown"),
            "app_version": self._config.get("app", {}).get("version", ""),
            "build_number": self._config.get("app", {}).get("build_number", ""),
            "status": status,
            "status_class": "success" if overall_passed else "danger",
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "duration_s": round(duration_s, 1),
            "duration_human": _format_duration(duration_s),
            "platform_os": platform.system(),
            "flutter_version": flutter_version,
            "repos": [r.get("local_name", r["url"]) for r in self._config.get("repos", [])],
            "total_files": manifest.total_files,
            "total_bytes": manifest.total_bytes,
            "total_mb": round(manifest.total_bytes / (1024 * 1024), 2),
            "filesystem_count": manifest.filesystem_count,
            "manifest_ok": manifest.verify(),
            "file_type_counts": type_counts,
            "files": [
                {
                    "path": f.path,
                    "size": f.size,
                    "sha256": f.sha256,
                    "type": f.file_type,
                    "repo": f.repo,
                }
                for f in manifest.files
            ],
            "artifacts": artifacts,
            "validation": validation_report,
            "asset_report": asset_report,
            "warnings": (
                validation_report.get("pre_build", {}).get("warnings", [])
                + validation_report.get("post_build", {}).get("warnings", [])
            ),
            "errors": (
                validation_report.get("pre_build", {}).get("errors", [])
                + validation_report.get("post_build", {}).get("errors", [])
            ),
        }

    def _write_json(self, output_dir: Path, context: dict) -> Path:
        """Write the JSON report (serialisable subset of context)."""
        dest = output_dir / "build_report.json"
        # Exclude the full file list from JSON to keep it manageable
        json_context = {k: v for k, v in context.items() if k != "files"}
        dest.write_text(json.dumps(json_context, indent=2, default=str), encoding="utf-8")
        return dest

    def _write_html(self, output_dir: Path, context: dict) -> Path:
        """Render the Jinja2 HTML template and write to disk."""
        dest = output_dir / "build_report.html"
        try:
            from jinja2 import Environment, FileSystemLoader, select_autoescape

            env = Environment(
                loader=FileSystemLoader(str(self._template_dir)),
                autoescape=select_autoescape(["html"]),
            )
            template = env.get_template("report.html")
            html = template.render(**context)
            dest.write_text(html, encoding="utf-8")
        except Exception as exc:
            logger.warning("Jinja2 rendering failed (%s) — writing fallback HTML", exc)
            dest.write_text(self._fallback_html(context), encoding="utf-8")
        return dest

    # ── Utilities ─────────────────────────────────────────────────────────────

    @staticmethod
    def _flutter_version() -> str:
        try:
            result = subprocess.run(
                ["flutter", "--version"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            import re
            m = re.search(r"Flutter\s+([\d.]+)", result.stdout)
            return m.group(1) if m else "unknown"
        except Exception:
            return "unknown"

    @staticmethod
    def _fallback_html(context: dict) -> str:
        """Minimal HTML report when Jinja2 rendering fails."""
        status = context.get("status", "UNKNOWN")
        color = "#28a745" if status == "PASSED" else "#dc3545"
        files_html = "".join(
            f"<tr><td>{f['path']}</td><td>{f['size']}</td>"
            f"<td>{f['type']}</td><td>{f['repo']}</td></tr>"
            for f in context.get("files", [])[:500]
        )
        return f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Build Report — {context.get('app_name')}</title>
<style>
body{{font-family:sans-serif;margin:2rem;}}
h1{{color:{color};}}
table{{border-collapse:collapse;width:100%;font-size:.85rem;}}
th,td{{border:1px solid #ccc;padding:4px 8px;text-align:left;}}
th{{background:#f4f4f4;}}
.badge{{padding:2px 8px;border-radius:4px;color:#fff;background:{color};}}
</style>
</head>
<body>
<h1>Build Report <span class="badge">{status}</span></h1>
<p><b>App:</b> {context.get('app_name')} {context.get('app_version')} ({context.get('build_number')})</p>
<p><b>Duration:</b> {context.get('duration_human')}</p>
<p><b>Files tracked:</b> {context.get('total_files')} | <b>Filesystem:</b> {context.get('filesystem_count')} | <b>Match:</b> {context.get('manifest_ok')}</p>
<h2>Artifacts</h2>
<ul>{"".join(f"<li>{k}: {v}</li>" for k,v in context.get('artifacts',{{}}).items())}</ul>
<h2>Errors</h2>
<ul>{"".join(f"<li style='color:red'>{e}</li>" for e in context.get('errors',[]))}</ul>
<h2>Warnings</h2>
<ul>{"".join(f"<li style='color:orange'>{w}</li>" for w in context.get('warnings',[]))}</ul>
<h2>File Manifest (first 500)</h2>
<table><tr><th>Path</th><th>Size</th><th>Type</th><th>Repo</th></tr>{files_html}</table>
</body></html>"""


def _format_duration(seconds: float) -> str:
    """Return a human-readable duration string."""
    if seconds < 60:
        return f"{seconds:.0f}s"
    minutes, secs = divmod(seconds, 60)
    if minutes < 60:
        return f"{minutes:.0f}m {secs:.0f}s"
    hours, minutes = divmod(minutes, 60)
    return f"{hours:.0f}h {minutes:.0f}m"
