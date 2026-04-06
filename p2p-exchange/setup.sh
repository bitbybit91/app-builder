#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_DIR"

echo "==> Installing Python dependencies..."
pip install -r requirements.txt

echo "==> Creating session directory..."
mkdir -p flask_session

if [ ! -f .env ]; then
    echo "==> Creating .env from .env.example..."
    cp .env.example .env
    echo "IMPORTANT: Edit .env and set SECRET_KEY before running in production!"
fi

echo "==> Initialising database..."
python - <<'PYEOF'
import os, sys
sys.path.insert(0, '.')
os.environ.setdefault('FLASK_ENV', 'development')
from app import create_app
from database import init_db
app = create_app()
with app.app_context():
    init_db()
print("Database initialised.")
PYEOF

echo "==> Setup complete."
echo "Run with: gunicorn -w 4 -b 127.0.0.1:8000 'app:create_app()'"
