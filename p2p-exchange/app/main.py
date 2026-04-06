#!/usr/bin/env python3
"""
P2P Exchange — Application Entry Point
=======================================
Run directly for development:
    python -m app.main

Production (Gunicorn):
    gunicorn 'app.main:app' --bind 0.0.0.0:8000 --workers 4
"""

from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=app.config.get('DEBUG', False),
    )
