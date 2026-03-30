#!/usr/bin/env python3
"""
panel-server.py — HTTP server for the Magoradesk APK Build Panel.

Endpoints:
  GET  /               → serve /var/www/apk-panel/index.html
  GET  /builds/<file>  → serve APK files from /var/www/apk-panel/builds/
  POST /api/build      → trigger build.sh in the background
  GET  /api/status     → JSON status (building, last_build, last_result, apk_url, log)
  GET  /api/builds     → JSON list of available APK filenames
"""

import http.server
import json
import os
import subprocess
import threading
import time
from datetime import datetime
from pathlib import Path

PANEL_ROOT = Path("/var/www/apk-panel")
BUILDS_DIR = PANEL_ROOT / "builds"
LOG_DIR = Path("/var/log/app-builder")
BUILD_SCRIPT = Path(__file__).parent / "build.sh"
BIND_HOST = "0.0.0.0"
BIND_PORT = 8080

# ---------------------------------------------------------------------------
# Shared state (protected by a lock)
# ---------------------------------------------------------------------------
_state_lock = threading.Lock()
_state = {
    "building": False,
    "last_build": None,      # ISO timestamp string
    "last_result": None,     # "success" or "failure"
    "apk_url": None,         # relative URL to latest APK
}


def _latest_log_lines(n: int = 50) -> list[str]:
    """Return the last *n* lines of the most recent build log."""
    try:
        logs = sorted(LOG_DIR.glob("build-*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
        if not logs:
            return []
        with open(logs[0], "r", errors="replace") as fh:
            return fh.readlines()[-n:]
    except Exception:
        return []


def _run_build() -> None:
    """Execute build.sh and update shared state when done."""
    with _state_lock:
        _state["building"] = True

    result = subprocess.run(
        ["bash", str(BUILD_SCRIPT)],
        capture_output=False,  # output goes to its own log file via tee
        text=True,
    )

    latest_apk = BUILDS_DIR / "magoradesk-debug-latest.apk"
    with _state_lock:
        _state["building"] = False
        _state["last_build"] = datetime.utcnow().isoformat() + "Z"
        _state["last_result"] = "success" if result.returncode == 0 else "failure"
        _state["apk_url"] = "/builds/magoradesk-debug-latest.apk" if latest_apk.exists() else None


# ---------------------------------------------------------------------------
# Request handler
# ---------------------------------------------------------------------------
class PanelHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # silence default access log noise
        pass

    # ---- routing -----------------------------------------------------------
    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self._serve_file(PANEL_ROOT / "index.html", "text/html")
        elif self.path.startswith("/builds/"):
            fname = Path(self.path[len("/builds/"):])
            self._serve_file(BUILDS_DIR / fname.name, "application/vnd.android.package-archive")
        elif self.path == "/api/status":
            self._serve_status()
        elif self.path == "/api/builds":
            self._serve_builds()
        else:
            self._not_found()

    def do_POST(self):
        if self.path == "/api/build":
            self._trigger_build()
        else:
            self._not_found()

    # ---- handlers ----------------------------------------------------------
    def _serve_file(self, path: Path, content_type: str) -> None:
        if not path.is_file():
            self._not_found()
            return
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _serve_status(self) -> None:
        with _state_lock:
            payload = dict(_state)
        payload["log"] = "".join(_latest_log_lines(50))
        self._json_response(payload)

    def _serve_builds(self) -> None:
        BUILDS_DIR.mkdir(parents=True, exist_ok=True)
        apks = sorted(
            (p.name for p in BUILDS_DIR.glob("*.apk")),
            reverse=True,
        )
        self._json_response(apks)

    def _trigger_build(self) -> None:
        with _state_lock:
            if _state["building"]:
                self._json_response({"error": "A build is already in progress."}, status=409)
                return
        threading.Thread(target=_run_build, daemon=True).start()
        self._json_response({"status": "Build triggered."}, status=202)

    # ---- helpers -----------------------------------------------------------
    def _json_response(self, payload, status: int = 200) -> None:
        body = json.dumps(payload, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _not_found(self) -> None:
        self._json_response({"error": "Not found."}, status=404)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    BUILDS_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    server = http.server.ThreadingHTTPServer((BIND_HOST, BIND_PORT), PanelHandler)
    print(f"Magoradesk Build Panel listening on http://{BIND_HOST}:{BIND_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.server_close()
