# P2P Exchange

**No-KYC, non-custodial peer-to-peer cryptocurrency exchange for Monero (XMR) trading.**

A fully self-hosted platform where users can create buy/sell offers, trade XMR directly with each other using any fiat payment method, and communicate via end-to-end encrypted chat — all without registration, identity verification, or centralized custody of funds. Deployable on both clearnet (Apache HTTP, port 80) and Tor hidden service (.onion).

| | |
|---|---|
| **Backend** | Python 3.12 (Flask) |
| **Frontend** | Vanilla HTML5 / CSS3 / JavaScript (no frameworks — fast over Tor) |
| **Database** | SQLite (development) / PostgreSQL (production) |
| **Web Server** | Apache2 + Gunicorn (reverse proxy) |
| **Encryption** | X25519 + XChaCha20-Poly1305 (NaCl/libsodium) |
| **Identity** | BIP39 mnemonic → X25519 keypair (no passwords) |
| **Monero RPC** | Configurable multi-endpoint supernode architecture |

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick Start (Development)](#quick-start-development)
  - [Production Setup](#production-setup)
  - [Docker Setup](#docker-setup)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Monero RPC](#monero-rpc)
  - [Database](#database)
  - [Security](#security-configuration)
- [Build & Run Commands](#build--run-commands)
  - [Development](#development)
  - [Production (Gunicorn)](#production-gunicorn)
  - [Docker](#docker)
- [Deployment](#deployment)
  - [Apache Configuration](#apache-configuration)
  - [Tor Hidden Service](#tor-hidden-service)
  - [Systemd Service](#systemd-service)
- [API Reference](#api-reference)
- [Testing](#testing)
- [Security](#security)
- [Troubleshooting](#troubleshooting)

---

## Features

| Feature | Description |
|---|---|
| **No-KYC Trading** | No registration, no email, no phone. Session-based pseudonymous identity. |
| **Non-Custodial Escrow** | Platform never holds private keys. Escrow via on-chain XMR deposits to dedicated subaddresses. |
| **E2E Encrypted Chat** | All trade messages encrypted client-side with NaCl box (X25519 + XChaCha20-Poly1305). Server stores only ciphertext. |
| **BIP39 Identity** | Optional persistent identity backed by a 12-word mnemonic that deterministically generates a keypair. |
| **Reputation System** | Trust scores based on successful trades, response time, dispute rate. Publicly visible on offers. |
| **Dispute Resolution** | Either party can open a dispute. Arbitrator reviews evidence and releases escrowed funds. |
| **Multi-Channel Notifications** | In-app (polling), email (SMTP), Nostr protocol. |
| **Tor-Friendly** | No CDN, no external resources, no analytics. Loads fast over Tor. |
| **Local Trading** | Optional location-based listings for cash-in-person trades. |
| **Multiple Endpoints** | Configurable XMR RPC endpoints with automatic failover. |

---

## Architecture

```
┌──────────────────────────────────────────────┐
│                   Client                     │
│  HTML/CSS/JS + NaCl (client-side encryption) │
└──────────────┬───────────────────────────────┘
               │ HTTP / WebSocket
┌──────────────▼───────────────────────────────┐
│              Apache2 (port 80)               │
│  Reverse proxy → Gunicorn (port 8000)        │
│  Static files served directly                │
└──────────────┬───────────────────────────────┘
               │
┌──────────────▼───────────────────────────────┐
│          Flask Application                    │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐       │
│  │ Routes  │ │Services │ │  Models   │       │
│  │ (API)   │→│(Business│→│(SQLAlchemy│       │
│  │         │ │ Logic)  │ │  ORM)    │        │
│  └─────────┘ └────┬────┘ └─────┬────┘       │
└────────────────────┼────────────┼────────────┘
                     │            │
          ┌──────────▼──┐  ┌─────▼─────┐
          │ Monero RPC  │  │ SQLite /  │
          │ (Daemon +   │  │PostgreSQL │
          │  Wallet)    │  │           │
          └─────────────┘  └───────────┘
```

### Key Design Decisions

- **Non-custodial**: Escrow uses dedicated XMR subaddresses. The wallet RPC handles fund transfers, but users control their own wallets.
- **E2E encryption**: Server stores only ciphertext + nonce + ephemeral public key. Decryption happens exclusively in the browser.
- **No frameworks**: Frontend is vanilla JS for minimal load times over Tor. No React, no Vue, no Angular.
- **Session-based auth**: HMAC-signed tokens. No passwords stored server-side. Optional mnemonic for persistence.

---

## Project Structure

```
p2p-exchange/
├── app/
│   ├── __init__.py              # Flask app factory + security headers
│   ├── main.py                  # Entry point (dev + Gunicorn)
│   ├── config.py                # Configuration from environment
│   ├── models/                  # SQLAlchemy database models
│   │   ├── __init__.py
│   │   ├── user.py              # Pseudonymous user + reputation
│   │   ├── offer.py             # Buy/sell offers
│   │   ├── trade.py             # Active trades + escrow state
│   │   └── message.py           # E2E encrypted messages
│   ├── routes/                  # API endpoints (Flask Blueprints)
│   │   ├── __init__.py
│   │   ├── main_routes.py       # HTML page routes
│   │   ├── auth.py              # Session, mnemonic, BitID
│   │   ├── offers.py            # CRUD offers + filtering
│   │   ├── trades.py            # Trade lifecycle + escrow
│   │   ├── chat.py              # E2E encrypted messaging
│   │   └── wallet.py            # Balance, deposit, withdraw
│   ├── services/                # Business logic
│   │   ├── __init__.py
│   │   ├── encryption.py        # Keypair generation, mnemonic, validation
│   │   ├── xmr.py               # Monero RPC client (multi-endpoint)
│   │   ├── escrow.py            # Non-custodial escrow lifecycle
│   │   ├── reputation.py        # Trust score calculation
│   │   └── notifications.py     # Multi-channel notifications
│   ├── static/                  # Frontend assets (no CDN)
│   │   ├── css/style.css        # Complete stylesheet (dark theme)
│   │   ├── js/app.js            # Client-side JS (session, API, rendering)
│   │   └── img/                 # Images (self-hosted)
│   └── templates/               # Jinja2 HTML templates
│       ├── base.html            # Layout + navbar + footer
│       ├── index.html           # Landing page
│       ├── offers.html          # Offer listing + filters
│       ├── create_offer.html    # Create offer form
│       ├── trade.html           # Trade view + chat
│       ├── chat.html            # Standalone chat
│       ├── wallet.html          # Wallet (balance, deposit, withdraw)
│       ├── profile.html         # Trader profile
│       └── about.html           # About / FAQ
├── deploy/
│   ├── apache.conf              # Apache virtual host (port 80)
│   ├── torrc                    # Tor hidden service config
│   ├── Dockerfile               # Multi-stage Docker build
│   └── docker-compose.yml       # App + PostgreSQL + Tor
├── tests/                       # Test suite
│   ├── conftest.py              # Shared fixtures
│   ├── test_encryption.py       # Keypair, mnemonic, message validation
│   ├── test_auth.py             # Session creation, verification, mnemonic
│   ├── test_offers.py           # CRUD + filtering
│   ├── test_trades.py           # Trade lifecycle + disputes
│   └── test_reputation.py       # Trust score calculation
├── setup.sh                     # Automated setup (dev / production / docker)
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment variable template
└── README.md                    # This file
```

---

## Prerequisites

| Tool | Version | Required For | Install |
|---|---|---|---|
| **Python** | 3.10+ | Backend | [python.org](https://www.python.org/downloads/) |
| **pip** | 21+ | Dependencies | Included with Python |
| **Git** | 2.x | Clone repo | [git-scm.com](https://git-scm.com/) |
| **libsodium** | 1.0.18+ | NaCl encryption | `apt install libsodium-dev` |
| **PostgreSQL** | 14+ | Production DB | `apt install postgresql` |
| **Apache2** | 2.4+ | Web server | `apt install apache2` |
| **Tor** | 0.4+ | Hidden service | `apt install tor` |
| **Docker** | 24+ | Container deploy | [docker.com](https://docs.docker.com/get-docker/) |
| **monero-wallet-rpc** | 0.18+ | Wallet operations | [getmonero.org](https://www.getmonero.org/downloads/) |

Only Python, pip, and libsodium are required for development. Other tools are needed for production deployment.

---

## Installation

### Quick Start (Development)

```bash
# 1. Clone the repository
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder/p2p-exchange

# 2. Run the automated setup
chmod +x setup.sh
./setup.sh --dev

# 3. Start the development server
source venv/bin/activate
python -m app.main
```

Open **http://localhost:5000** in your browser.

#### Manual Setup (step by step)

```bash
# 1. Clone
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder/p2p-exchange

# 2. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate   # Windows

# 3. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# 4. Create .env from template
cp .env.example .env
# Edit .env and set SECRET_KEY, JWT_SECRET_KEY, SESSION_HMAC_KEY to random values

# 5. Initialize the database
FLASK_ENV=development python3 -c "
from app import create_app, db
app = create_app('development')
with app.app_context():
    db.create_all()
"

# 6. Start the dev server
python -m app.main
```

### Production Setup

Requires root access on Ubuntu/Debian:

```bash
# Full production setup: Python + PostgreSQL + Apache + Tor + systemd
sudo ./setup.sh --production
```

This will:
1. Install system packages (Python, Apache, Tor, PostgreSQL, libsodium)
2. Create `/var/www/p2p-exchange/` with virtualenv and dependencies
3. Generate `.env` with random secrets
4. Create PostgreSQL database
5. Initialize database tables
6. Configure Apache reverse proxy (port 80 → Gunicorn 8000)
7. Configure Tor hidden service
8. Create systemd service (`p2p-exchange`)
9. Start all services

### Docker Setup

```bash
# Docker setup: build + run app + PostgreSQL + Tor
./setup.sh --docker

# Or manually:
cp .env.example .env
# Edit .env with your settings
docker compose -f deploy/docker-compose.yml up -d --build
```

---

## Configuration

### Environment Variables

All configuration is via environment variables or a `.env` file. Copy `.env.example` to `.env` and edit:

```bash
cp .env.example .env
```

#### Application

| Variable | Default | Description |
|---|---|---|
| `FLASK_ENV` | `development` | `development`, `production`, or `testing` |
| `SECRET_KEY` | — | Flask secret key (random 64 hex chars) |
| `DEBUG` | `false` | Enable debug mode |

#### Database

| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `sqlite:///p2p_exchange.db` | Database connection string |

Examples:
```bash
# SQLite (development)
DATABASE_URL=sqlite:///p2p_exchange_dev.db

# PostgreSQL (production)
DATABASE_URL=postgresql://p2p:password@localhost:5432/p2p_exchange
```

#### Monero RPC

| Variable | Default | Description |
|---|---|---|
| `XMR_RPC_ENDPOINTS` | `http://node.moneroworld.com:18089` | Comma-separated daemon RPC URLs |
| `XMR_RPC_USER` | — | Daemon RPC username |
| `XMR_RPC_PASSWORD` | — | Daemon RPC password |
| `XMR_WALLET_RPC_URL` | `http://127.0.0.1:18083/json_rpc` | Wallet RPC URL |
| `XMR_WALLET_RPC_USER` | — | Wallet RPC username |
| `XMR_WALLET_RPC_PASSWORD` | — | Wallet RPC password |

#### Security

| Variable | Default | Description |
|---|---|---|
| `SESSION_HMAC_KEY` | — | HMAC key for session token hashing (64 hex chars) |
| `JWT_SECRET_KEY` | — | JWT signing key |
| `JWT_ACCESS_TOKEN_EXPIRES` | `3600` | Access token lifetime (seconds) |
| `JWT_REFRESH_TOKEN_EXPIRES` | `86400` | Refresh token lifetime (seconds) |

#### Rate Limiting

| Variable | Default | Description |
|---|---|---|
| `RATE_LIMIT_DEFAULT` | `100/hour` | Default rate limit |
| `RATE_LIMIT_AUTH` | `20/hour` | Auth endpoint rate limit |
| `RATE_LIMIT_TRADES` | `50/hour` | Trade endpoint rate limit |

#### Escrow

| Variable | Default | Description |
|---|---|---|
| `ESCROW_CONFIRMATIONS_REQUIRED` | `10` | XMR confirmations before trade proceeds |
| `ESCROW_TIMEOUT_HOURS` | `24` | Auto-cancel timeout |
| `ARBITRATION_BOND_PERCENT` | `5` | Bond as % of trade amount |

#### Notifications (Optional)

| Variable | Default | Description |
|---|---|---|
| `SMTP_HOST` | — | SMTP server hostname |
| `SMTP_PORT` | `587` | SMTP port |
| `SMTP_USER` | — | SMTP username |
| `SMTP_PASSWORD` | — | SMTP password |
| `SMTP_FROM` | `noreply@example.onion` | Sender email address |
| `NOSTR_RELAY_URL` | — | Nostr relay URL |
| `NOSTR_PRIVATE_KEY` | — | Nostr private key |

#### Tor

| Variable | Default | Description |
|---|---|---|
| `TOR_ENABLED` | `false` | Enable Tor-specific features |
| `ONION_ADDRESS` | — | Your `.onion` address |

### Monero RPC

The application connects to Monero via JSON-RPC. You need:

1. **Daemon RPC** — for blockchain data (block height, tx verification). Can use public nodes.
2. **Wallet RPC** — for wallet operations (address generation, transfers). Must run locally.

#### Setting up `monero-wallet-rpc`:

```bash
# Start wallet RPC (use --rpc-bind-port to set the port)
monero-wallet-rpc \
  --wallet-file /path/to/wallet \
  --password "your-wallet-password" \
  --rpc-bind-port 18083 \
  --rpc-bind-ip 127.0.0.1 \
  --disable-rpc-login \
  --daemon-address node.moneroworld.com:18089 \
  --trusted-daemon
```

#### Using multiple daemon endpoints (failover):

```bash
XMR_RPC_ENDPOINTS=http://node1.example.com:18089,http://node2.example.com:18081,http://node3.example.com:18089
```

The application automatically shuffles endpoints and fails over to the next one on error.

### Security Configuration

Generate random secrets for production:

```bash
# Generate all three required secrets
python3 -c "import secrets; print('SECRET_KEY=' + secrets.token_hex(32))"
python3 -c "import secrets; print('JWT_SECRET_KEY=' + secrets.token_hex(32))"
python3 -c "import secrets; print('SESSION_HMAC_KEY=' + secrets.token_hex(32))"
```

---

## Build & Run Commands

### Development

```bash
# Activate virtual environment
source venv/bin/activate

# Start Flask dev server (auto-reload, debug mode)
python -m app.main
# → http://localhost:5000

# Or with explicit settings:
FLASK_ENV=development python -m app.main
```

### Production (Gunicorn)

```bash
# Activate virtual environment
source venv/bin/activate

# Start Gunicorn (4 workers, 2 threads each)
gunicorn 'app.main:app' \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --threads 2 \
  --timeout 120 \
  --access-logfile /var/log/p2p-exchange/access.log \
  --error-logfile /var/log/p2p-exchange/error.log

# Start with lower resource usage (small VPS)
gunicorn 'app.main:app' \
  --bind 0.0.0.0:8000 \
  --workers 2 \
  --threads 1 \
  --timeout 120
```

### Docker

```bash
# Build and start all services (app + PostgreSQL + Tor)
docker compose -f deploy/docker-compose.yml up -d --build

# View logs
docker compose -f deploy/docker-compose.yml logs -f

# Stop all services
docker compose -f deploy/docker-compose.yml down

# Rebuild after code changes
docker compose -f deploy/docker-compose.yml up -d --build web

# Shell into the running container
docker exec -it p2p-exchange-web bash

# Database shell
docker exec -it p2p-exchange-db psql -U p2p -d p2p_exchange
```

### Database Management

```bash
# Initialize database (create tables)
FLASK_ENV=development python3 -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.create_all()
"

# Database migrations (if using Flask-Migrate)
flask db init
flask db migrate -m "Initial migration"
flask db upgrade

# Reset database (DESTRUCTIVE)
FLASK_ENV=development python3 -c "
from app import create_app, db
app = create_app()
with app.app_context():
    db.drop_all()
    db.create_all()
"
```

---

## Deployment

### Apache Configuration

The application is designed to run behind Apache as a reverse proxy:

```
Client → Apache (port 80) → Gunicorn (port 8000) → Flask
```

#### Install and configure:

```bash
# Install Apache and required modules
sudo apt install apache2 libapache2-mod-proxy-html
sudo a2enmod proxy proxy_http proxy_wstunnel headers rewrite

# Copy the virtual host config
sudo cp deploy/apache.conf /etc/apache2/sites-available/p2p-exchange.conf

# Edit ServerName to match your domain
sudo nano /etc/apache2/sites-available/p2p-exchange.conf

# Enable site and disable default
sudo a2ensite p2p-exchange
sudo a2dissite 000-default

# Test and reload
sudo apache2ctl configtest
sudo systemctl reload apache2
```

#### Security headers included in `deploy/apache.conf`:

| Header | Value |
|---|---|
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `no-referrer` |
| `Content-Security-Policy` | `default-src 'self'; script-src 'self'; ...` |
| `Permissions-Policy` | `geolocation=(), camera=(), microphone=()` |

### Tor Hidden Service

#### Install and configure:

```bash
# 1. Install Tor
sudo apt install tor

# 2. Add hidden service config to /etc/tor/torrc
sudo bash -c 'cat deploy/torrc >> /etc/tor/torrc'

# 3. Restart Tor
sudo systemctl restart tor

# 4. Get your .onion address
sudo cat /var/lib/tor/p2p-exchange/hostname
# → Example: abcdefghijklmnop.onion

# 5. Set the address in your .env
echo "ONION_ADDRESS=$(sudo cat /var/lib/tor/p2p-exchange/hostname)" >> .env
```

The hidden service maps **port 80 → 127.0.0.1:8000** (Gunicorn). For clearnet + Tor, both Apache and Tor proxy to the same Gunicorn backend.

### Systemd Service

The `setup.sh --production` script creates a systemd service automatically. To manage it manually:

```bash
# Create service file
sudo nano /etc/systemd/system/p2p-exchange.service
# (see setup.sh for the full service definition)

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable p2p-exchange
sudo systemctl start p2p-exchange

# Check status
sudo systemctl status p2p-exchange

# View logs
sudo journalctl -u p2p-exchange -f

# Restart after code changes
sudo systemctl restart p2p-exchange
```

---

## API Reference

Base URL: `http://localhost:5000/api` (dev) or `http://your-domain/api` (production)

### Authentication

| Endpoint | Method | Description |
|---|---|---|
| `/api/auth/session` | POST | Create anonymous session |
| `/api/auth/session/verify` | POST | Verify session token |
| `/api/auth/mnemonic/generate` | POST | Generate 12-word mnemonic |
| `/api/auth/mnemonic/recover` | POST | Recover identity from mnemonic |
| `/api/auth/mnemonic/bind` | POST | Bind mnemonic to existing session |

All authenticated requests use `Authorization: Bearer <session_token>`.

### Offers

| Endpoint | Method | Description |
|---|---|---|
| `/api/offers` | GET | List offers (filterable) |
| `/api/offers` | POST | Create offer (auth required) |
| `/api/offers/<id>` | GET | Get offer details |
| `/api/offers/<id>` | PUT | Update offer (owner only) |
| `/api/offers/<id>` | DELETE | Deactivate offer (owner only) |
| `/api/offers/my` | GET | List my offers (auth required) |
| `/api/offers/payment-methods` | GET | List payment methods |

**Offer filters** (query params): `type`, `currency`, `payment_method`, `country`, `trade_type`, `sort`, `page`, `per_page`

### Trades

| Endpoint | Method | Description |
|---|---|---|
| `/api/trades` | POST | Initiate trade from offer |
| `/api/trades` | GET | List my trades |
| `/api/trades/<id>` | GET | Get trade details |
| `/api/trades/<id>/escrow-funded` | POST | Seller confirms escrow TX |
| `/api/trades/<id>/fiat-sent` | POST | Buyer confirms fiat sent |
| `/api/trades/<id>/fiat-received` | POST | Seller confirms fiat received → release |
| `/api/trades/<id>/cancel` | POST | Cancel trade |
| `/api/trades/<id>/dispute` | POST | Open dispute |

### Chat (E2E Encrypted)

| Endpoint | Method | Description |
|---|---|---|
| `/api/chat/<trade_id>/messages` | GET | Get encrypted messages |
| `/api/chat/<trade_id>/messages` | POST | Send encrypted message |

### Wallet

| Endpoint | Method | Description |
|---|---|---|
| `/api/wallet/balance` | GET | Get XMR balance |
| `/api/wallet/deposit` | POST | Generate deposit address |
| `/api/wallet/withdraw` | POST | Withdraw XMR |
| `/api/wallet/transactions` | GET | Transaction history |
| `/api/wallet/network` | GET | Network status |

---

## Testing

### Run all tests

```bash
source venv/bin/activate
cd p2p-exchange

# Run all tests
pytest

# Run with verbose output
pytest -v

# Run with coverage report
pytest --cov=app --cov-report=term-missing

# Run specific test file
pytest tests/test_encryption.py

# Run specific test class
pytest tests/test_auth.py::TestSessionCreation

# Run specific test
pytest tests/test_offers.py::TestOfferCreation::test_create_offer -v
```

### Test coverage areas

| Test File | Coverage |
|---|---|
| `test_encryption.py` | Keypair generation, BIP39 mnemonic, message validation, session tokens |
| `test_auth.py` | Session creation/verification, mnemonic identity, bind/recover |
| `test_offers.py` | CRUD operations, filtering, pagination, authorization |
| `test_trades.py` | Trade initiation, state transitions, cancellation, disputes |
| `test_reputation.py` | Trust score calculation, trust levels, model properties |

---

## Security

| Area | Implementation |
|---|---|
| **Transport** | HTTPS (clearnet) / Tor E2E encryption (hidden service) |
| **Data at rest** | Chat messages encrypted with NaCl box before storage |
| **Authentication** | HMAC-signed session tokens — no passwords server-side |
| **CSRF** | Flask-WTF CSRF protection on all form endpoints |
| **XSS** | Strict CSP headers; `bleach` for input sanitization |
| **Rate limiting** | Per-IP rate limits on all API endpoints via Flask-Limiter |
| **Headers** | X-Frame-Options, X-Content-Type-Options, Referrer-Policy, CSP |
| **Tor-friendly** | No CAPTCHA, no JS-dependent auth, no external CDN resources |
| **Secrets** | All keys/passwords in `.env` — never hardcoded |

---

## Troubleshooting

### Common Issues

**"Wallet service unavailable"**
→ `monero-wallet-rpc` is not running or not reachable. Start it:
```bash
monero-wallet-rpc --wallet-file /path/to/wallet --rpc-bind-port 18083 --disable-rpc-login
```

**"All XMR RPC endpoints failed"**
→ All configured daemon endpoints are unreachable. Check `XMR_RPC_ENDPOINTS` in `.env` and verify connectivity:
```bash
curl -s http://node.moneroworld.com:18089/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_block_count"}' -H 'Content-Type: application/json'
```

**Database errors on startup**
→ Run database initialization:
```bash
python3 -c "from app import create_app, db; app = create_app(); app.app_context().__enter__(); db.create_all()"
```

**Apache returns 503**
→ Gunicorn is not running. Check the systemd service:
```bash
sudo systemctl status p2p-exchange
sudo journalctl -u p2p-exchange -n 50
```

**Tor hidden service not accessible**
→ Check Tor status and hostname:
```bash
sudo systemctl status tor
sudo cat /var/lib/tor/p2p-exchange/hostname
```

### Log Locations

| Service | Log File |
|---|---|
| Application | `/var/log/p2p-exchange/error.log` |
| Access log | `/var/log/p2p-exchange/access.log` |
| Apache | `/var/log/apache2/p2p-exchange-error.log` |
| Tor | `/var/log/tor/notices.log` |
| Systemd | `journalctl -u p2p-exchange` |

---

## License

Proprietary. All rights reserved.
