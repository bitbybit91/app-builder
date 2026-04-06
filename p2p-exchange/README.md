# P2P XMR Exchange

A peer-to-peer Monero exchange platform. Trade XMR directly with other users, no KYC required.

## Requirements

- Python 3.11+
- monero-wallet-rpc running on 127.0.0.1:18082
- Apache (reverse proxy, port 80 → Gunicorn 8000)
- Tor (optional, for .onion hidden service)

## Quick Start

```bash
cd p2p-exchange
cp .env.example .env
# Edit .env: set SECRET_KEY
bash setup.sh
gunicorn -w 4 -b 127.0.0.1:8000 'app:create_app()'
```

## Configuration

All configuration is via environment variables (see `.env.example`):

| Variable | Default | Description |
|---|---|---|
| SECRET_KEY | dev key | Flask secret key (CHANGE IN PRODUCTION) |
| DATABASE_PATH | exchange.db | SQLite database file path |
| SESSION_FILE_DIR | flask_session/ | Server-side session storage directory |
| MONERO_RPC_URL | http://127.0.0.1:18082/json_rpc | Monero wallet RPC endpoint |
| COINGECKO_CACHE_TTL | 300 | CoinGecko price cache TTL in seconds |

## Architecture

- `app.py` — Flask application factory, all routes
- `config.py` — Configuration classes
- `database.py` — SQLite database helpers (raw SQL, no ORM)
- `monero_rpc.py` — Monero wallet RPC client
- `coingecko.py` — CoinGecko price API with caching
- `templates/` — Jinja2 HTML templates (dark theme)

## Running Tests

```bash
cd p2p-exchange
pytest tests/ -v
```

## Deploy

See `deploy/` for Apache config, systemd service, Dockerfile, and Tor hidden service config.
