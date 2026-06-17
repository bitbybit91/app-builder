# P2P XMR Exchange

A **no-KYC, non-custodial peer-to-peer cryptocurrency exchange** for Monero (XMR). Fully self-hosted. Works on clearnet and Tor hidden service (.onion). Users trade XMR directly with each other using any fiat payment method.

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://python.org)
[![Flask 3.0](https://img.shields.io/badge/flask-3.0-green.svg)](https://flask.palletsprojects.com)
[![Ubuntu 20.04](https://img.shields.io/badge/ubuntu-20.04-orange.svg)](https://ubuntu.com)

## Features

| Feature | Description |
|---|---|
| **No KYC** | Identity via BIP39 mnemonic phrase — no email, phone, or ID |
| **Non-Custodial** | XMR locked in on-chain escrow subaddress; platform never holds funds |
| **E2E Encrypted Chat** | X25519 + XChaCha20-Poly1305 (NaCl) — only traders can read messages |
| **Any Payment Method** | Bank transfer, cash, mobile money, gift cards — any fiat method |
| **Tor Compatible** | .onion hidden service; zero external CDN dependencies |
| **Reputation System** | New → Bronze → Silver → Gold → Platinum trust tiers |
| **Multi-endpoint XMR** | Configurable Monero RPC with automatic failover |
| **Rate Limited** | Flask-Limiter protection on all API endpoints |
| **CSP Headers** | Content Security Policy + security headers on every response |

---

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │         Users (Browser / Tor)       │
                        └────────────┬────────────────────────┘
                                     │ HTTP/80 or .onion
                        ┌────────────▼────────────────────────┐
                        │         Apache2 Reverse Proxy        │
                        │  (port 80, security headers, static) │
                        └────────────┬────────────────────────┘
                                     │ http://127.0.0.1:8000
                        ┌────────────▼────────────────────────┐
                        │         Gunicorn (WSGI)              │
                        │         4 workers, port 8000         │
                        └────────────┬────────────────────────┘
                                     │
                        ┌────────────▼────────────────────────┐
                        │         Flask Application            │
                        │  Routes: auth / offers / trades /   │
                        │          chat / wallet / main        │
                        └──┬───────────────────────┬──────────┘
                           │                       │
              ┌────────────▼───────┐   ┌──────────▼──────────────┐
              │   PostgreSQL 14     │   │   Monero Wallet RPC      │
              │   (or SQLite dev)   │   │   (multi-endpoint)       │
              └────────────────────┘   └─────────────────────────┘
```

---

## Project Structure

```
p2p-exchange/
├── app/
│   ├── __init__.py              # Flask app factory + security headers
│   ├── main.py                  # Entry point (dev + Gunicorn)
│   ├── config.py                # Configuration from environment
│   ├── models/
│   │   ├── user.py              # Pseudonymous user + reputation
│   │   ├── offer.py             # Buy/sell offers
│   │   ├── trade.py             # Active trades + escrow state machine
│   │   └── message.py           # E2E encrypted messages
│   ├── routes/
│   │   ├── main_routes.py       # HTML page routes
│   │   ├── auth.py              # Session, mnemonic, keypair
│   │   ├── offers.py            # CRUD offers + filtering
│   │   ├── trades.py            # Trade lifecycle + escrow
│   │   ├── chat.py              # E2E encrypted messaging
│   │   └── wallet.py            # Balance, deposit, withdraw
│   ├── services/
│   │   ├── encryption.py        # BIP39 + X25519 + NaCl
│   │   ├── xmr.py               # Monero RPC client (multi-endpoint)
│   │   ├── escrow.py            # Non-custodial escrow lifecycle
│   │   ├── reputation.py        # Trust score calculation
│   │   └── notifications.py     # In-app + SMTP notifications
│   ├── static/
│   │   ├── css/style.css        # Dark theme stylesheet
│   │   └── js/app.js            # Client-side session, API, rendering
│   └── templates/               # Jinja2 HTML templates
├── deploy/
│   ├── apache.conf              # Apache virtual host config
│   ├── torrc                    # Tor hidden service config
│   ├── Dockerfile               # Multi-stage Docker build
│   ├── docker-compose.yml       # App + PostgreSQL + Tor
│   └── p2p-exchange.service     # Systemd unit for Gunicorn
├── tests/
│   ├── conftest.py
│   ├── test_encryption.py
│   ├── test_auth.py
│   ├── test_offers.py
│   ├── test_trades.py
│   └── test_reputation.py
├── setup.sh                     # Automated setup (dev/production/docker)
├── requirements.txt
├── .env.example
└── README.md
```

---

## Quick Start (Development)

```bash
git clone https://github.com/yourname/p2p-exchange.git
cd p2p-exchange
./setup.sh --dev
source venv/bin/activate
flask run
# Visit http://127.0.0.1:5000
```

---

## Ubuntu 20.04 VPS Initial Server Setup

This section covers hardening a fresh Ubuntu 20.04 VPS before deploying the exchange.

### 1.1 Connect and Update

```bash
# Connect as root initially
ssh root@YOUR_VPS_IP

# Update all packages
apt update && apt upgrade -y

# Install essential tools
apt install -y curl wget git vim ufw fail2ban unattended-upgrades
```

### 1.2 Create Non-Root Service User

```bash
# Create p2p user (no login shell for security, but we give bash for setup)
useradd -m -s /bin/bash p2p

# Set a strong password (or use key auth only)
passwd p2p

# Add to sudo group for initial setup
usermod -aG sudo p2p

# Switch to p2p user
su - p2p
```

### 1.3 SSH Hardening

```bash
# Edit SSH config (as root)
sudo vim /etc/ssh/sshd_config
```

Modify these settings:

```ini
# Change default port (optional but reduces bot noise)
Port 2222

# Disable root login
PermitRootLogin no

# Use key authentication only
PasswordAuthentication no
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Limit to specific user
AllowUsers p2p

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
LoginGraceTime 30
```

```bash
# Restart SSH
sudo systemctl restart sshd

# Test in a NEW terminal before closing current session!
ssh -p 2222 p2p@YOUR_VPS_IP
```

> **Warning**: Always test SSH in a new terminal before closing your current session to avoid locking yourself out.

### 1.4 UFW Firewall Configuration

```bash
# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (use your custom port if changed)
sudo ufw allow 2222/tcp comment 'SSH'

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Enable firewall
sudo ufw --force enable

# Verify rules
sudo ufw status verbose
```

Expected output:
```
Status: active
To                         Action      From
--                         ------      ----
2222/tcp                   ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
```

### 1.5 Swap File for Low-RAM VPS

For VPS with 1GB–2GB RAM, a swap file prevents out-of-memory crashes:

```bash
# Check current swap
swapon --show

# Create 2GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Tune swappiness (use swap less aggressively)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
free -h
```

### 1.6 Timezone and Locale

```bash
# Set timezone
sudo timedatectl set-timezone UTC

# Verify
timedatectl

# Set locale
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

### 1.7 Unattended Security Upgrades

```bash
sudo apt install -y unattended-upgrades

# Configure
sudo dpkg-reconfigure -plow unattended-upgrades

# Edit configuration
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

Add/verify these settings:
```
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
```

```bash
# Enable and test
sudo systemctl enable unattended-upgrades
sudo unattended-upgrade --dry-run -d
```

---

## Python 3.12 on Ubuntu 20.04

Ubuntu 20.04 ships with Python 3.8. You need Python 3.12 via the deadsnakes PPA.

### 2.1 Add deadsnakes PPA

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
```

### 2.2 Install Python 3.12

```bash
sudo apt install -y python3.12 python3.12-venv python3.12-dev python3.12-distutils

# Verify
python3.12 --version
# Expected: Python 3.12.x
```

### 2.3 Install pip for Python 3.12

```bash
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
python3.12 -m pip --version
```

### 2.4 Optional: Set as Default

```bash
# Add update-alternatives entries
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2

# Select version interactively
sudo update-alternatives --config python3

# Verify
python3 --version
```

> **Note**: The `setup.sh --production` script handles Python 3.12 installation automatically.

---

## libsodium Installation

libsodium provides X25519 + XChaCha20-Poly1305 encryption used by PyNaCl.

### 3.1 Install via apt (Recommended)

```bash
sudo apt install -y libsodium-dev

# Verify
pkg-config --modversion libsodium
# Expected: 1.0.18 or higher
```

### 3.2 Build from Source (If apt Version is Too Old)

If you need a newer version:

```bash
# Install build tools
sudo apt install -y build-essential

# Download latest stable release
cd /tmp
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.20.tar.gz
wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.20.tar.gz.sig

# Verify signature (optional but recommended)
# Import libsodium signing key
# gpg --import libsodium-signing-key.asc
# gpg --verify libsodium-1.0.20.tar.gz.sig libsodium-1.0.20.tar.gz

# Extract and build
tar -xzf libsodium-1.0.20.tar.gz
cd libsodium-1.0.20
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install

# Update dynamic linker
sudo ldconfig

# Verify
pkg-config --modversion libsodium
```

---

## PostgreSQL 14 on Ubuntu 20.04

Ubuntu 20.04 ships with PostgreSQL 12. Install PostgreSQL 14 from the official APT repository.

### 4.1 Add Official PostgreSQL APT Repository

```bash
# Install signing key
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] \
    https://apt.postgresql.org/pub/repos/apt focal-pgdg main" | \
    sudo tee /etc/apt/sources.list.d/pgdg.list

sudo apt update
```

### 4.2 Install PostgreSQL 14

```bash
sudo apt install -y postgresql-14 postgresql-client-14

# Verify
sudo systemctl status postgresql@14-main
psql --version
# Expected: psql (PostgreSQL) 14.x
```

### 4.3 Create Database and User

```bash
# Switch to postgres user
sudo -u postgres psql

-- Create dedicated database user
CREATE USER p2puser WITH PASSWORD 'your_strong_password_here';

-- Create database
CREATE DATABASE p2pexchange OWNER p2puser;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE p2pexchange TO p2puser;

-- Exit
\q
```

### 4.4 Configure pg_hba.conf

```bash
sudo vim /etc/postgresql/14/main/pg_hba.conf
```

Ensure local connections use md5 authentication:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   p2pexchange     p2puser                                 md5
host    p2pexchange     p2puser         127.0.0.1/32            md5
```

```bash
sudo systemctl reload postgresql@14-main
```

### 4.5 Performance Tuning for Small VPS (1–2GB RAM)

```bash
sudo vim /etc/postgresql/14/main/postgresql.conf
```

For a 1GB RAM VPS:
```ini
# Memory settings
shared_buffers = 256MB              # 25% of RAM
effective_cache_size = 768MB        # 75% of RAM
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL settings
wal_buffers = 8MB
checkpoint_completion_target = 0.9
max_wal_size = 1GB

# Connection settings
max_connections = 50               # Reduce from 100 for small VPS

# Query planner
random_page_cost = 1.1             # For SSD VPS
```

```bash
sudo systemctl restart postgresql@14-main
```

### 4.6 Verify Connectivity

```bash
# Test connection
psql -h 127.0.0.1 -U p2puser -d p2pexchange -c "SELECT version();"
```

---

## Monero Daemon & Wallet RPC Setup

### 5.1 Download Monero CLI

```bash
# Download latest Monero CLI release from getmonero.org
cd /tmp

# Check https://www.getmonero.org/downloads/ for the latest version
MONERO_VERSION="0.18.3.3"
wget "https://downloads.getmonero.org/cli/monero-linux-x64-v${MONERO_VERSION}.tar.bz2"
wget "https://downloads.getmonero.org/cli/monero-linux-x64-v${MONERO_VERSION}.tar.bz2.asc"
```

### 5.2 Verify GPG Signature

```bash
# Import Monero GPG key
gpg --keyserver hkps://keys.openpgp.org --recv-keys \
    BDA6BD7042B721C467A9759D7455C5E3C0CDCEB9

# Verify signature
gpg --verify "monero-linux-x64-v${MONERO_VERSION}.tar.bz2.asc" \
    "monero-linux-x64-v${MONERO_VERSION}.tar.bz2"

# Expected: Good signature from "Riccardo Spagni <ric@spagni.net>"
```

### 5.3 Install Monero

```bash
# Extract
tar -xjf "monero-linux-x64-v${MONERO_VERSION}.tar.bz2"

# Install to /opt/monero
sudo mkdir -p /opt/monero
sudo cp monero-x86_64-linux-gnu-v${MONERO_VERSION}/* /opt/monero/
sudo chmod +x /opt/monero/*

# Add to PATH
echo 'export PATH="/opt/monero:$PATH"' | sudo tee /etc/profile.d/monero.sh
source /etc/profile.d/monero.sh

# Verify
monero-wallet-rpc --version
```

### 5.4 Create Monero Wallet

```bash
# Create wallet directory
sudo mkdir -p /var/lib/monero
sudo chown p2p:p2p /var/lib/monero

# Create new wallet (run as p2p user)
sudo -u p2p /opt/monero/monero-wallet-cli \
    --daemon-address=node.moneroworld.com:18089 \
    --generate-new-wallet=/var/lib/monero/exchange_wallet \
    --password="your_wallet_password"

# Note your wallet address and mnemonic seed!
```

#### Using Public Remote Nodes (No Local Daemon Required)

For a lightweight setup without running your own daemon:

```bash
# Reliable public Monero nodes:
# node.moneroworld.com:18089
# nodes.hashvault.pro:18081
# node.xmr.to:18081
# opennode.xmr-tw.org:18089
# p2pmd.xmrworld.net:18081
```

### 5.5 Create Systemd Service for Wallet RPC

```bash
sudo vim /etc/systemd/system/monero-wallet-rpc.service
```

```ini
[Unit]
Description=Monero Wallet RPC Server
After=network.target

[Service]
Type=simple
User=p2p
Group=p2p
WorkingDirectory=/var/lib/monero
ExecStart=/opt/monero/monero-wallet-rpc \
    --wallet-file=/var/lib/monero/exchange_wallet \
    --password=your_wallet_password \
    --rpc-bind-port=18083 \
    --rpc-bind-ip=127.0.0.1 \
    --daemon-address=node.moneroworld.com:18089 \
    --rpc-login=rpcuser:rpcpassword \
    --disable-rpc-login=0 \
    --trusted-daemon \
    --log-level=1 \
    --log-file=/var/log/monero/wallet-rpc.log
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo mkdir -p /var/log/monero
sudo chown p2p:p2p /var/log/monero

sudo systemctl daemon-reload
sudo systemctl enable monero-wallet-rpc
sudo systemctl start monero-wallet-rpc

# Verify
sudo systemctl status monero-wallet-rpc
curl -u rpcuser:rpcpassword http://127.0.0.1:18083/json_rpc \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0}}' \
    -H 'Content-Type: application/json'
```

---

## Application Installation

### 6.1 Clone Repository

```bash
cd /var/www
sudo git clone https://github.com/yourname/p2p-exchange.git
sudo chown -R p2p:p2p /var/www/p2p-exchange
cd /var/www/p2p-exchange
```

### 6.2 Create Virtual Environment

```bash
sudo -u p2p python3.12 -m venv /var/www/p2p-exchange/venv
sudo -u p2p /var/www/p2p-exchange/venv/bin/pip install --upgrade pip
sudo -u p2p /var/www/p2p-exchange/venv/bin/pip install -r /var/www/p2p-exchange/requirements.txt
```

### 6.3 Configure Environment

```bash
sudo -u p2p cp /var/www/p2p-exchange/.env.example /var/www/p2p-exchange/.env
sudo -u p2p vim /var/www/p2p-exchange/.env
```

Edit `.env`:
```ini
SECRET_KEY=<generate with: python3 -c "import secrets; print(secrets.token_hex(32))">
HMAC_SECRET=<generate with: python3 -c "import secrets; print(secrets.token_hex(32))">
FLASK_ENV=production
DATABASE_URL=postgresql://p2puser:your_password@localhost/p2pexchange
MONERO_RPC_URL=http://127.0.0.1:18083/json_rpc
MONERO_RPC_USER=rpcuser
MONERO_RPC_PASS=rpcpassword
SITE_URL=http://your-domain-or-ip
```

```bash
# Set strict permissions
sudo chmod 600 /var/www/p2p-exchange/.env
```

### 6.4 Initialize Database

```bash
sudo -u p2p bash -c "
    cd /var/www/p2p-exchange
    source venv/bin/activate
    FLASK_ENV=production python3 -c \"
from app import create_app, db
app = create_app('production')
with app.app_context():
    db.create_all()
    print('Database tables created successfully.')
\"
"
```

---

## Apache2 Reverse Proxy

### 7.1 Install Apache2 and Enable Modules

```bash
sudo apt install -y apache2

# Enable required modules
sudo a2enmod proxy          # Core proxy module
sudo a2enmod proxy_http     # HTTP proxy (for Gunicorn)
sudo a2enmod proxy_wstunnel # WebSocket proxy
sudo a2enmod headers        # Security headers (Header directive)
sudo a2enmod rewrite        # URL rewriting
sudo a2enmod expires        # Cache-Control headers for static files

sudo systemctl restart apache2
```

### 7.2 Create Virtual Host Configuration

```bash
sudo cp /var/www/p2p-exchange/deploy/apache.conf \
    /etc/apache2/sites-available/p2p-exchange.conf

# Edit to update ServerName
sudo vim /etc/apache2/sites-available/p2p-exchange.conf
```

Full annotated configuration:
```apache
<VirtualHost *:80>
    # Your domain or IP address
    ServerName p2pexchange.example.com

    # ProxyPreserveHost: Pass the Host header to Gunicorn
    # This is important for correct URL generation in Flask
    ProxyPreserveHost On

    # Don't proxy requests for /static/ — serve them directly
    ProxyPass /static/ !

    # Forward all other requests to Gunicorn on port 8000
    ProxyPass / http://127.0.0.1:8000/
    ProxyPassReverse / http://127.0.0.1:8000/

    # WebSocket support (for real-time features if added)
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteCond %{HTTP:Connection} upgrade [NC]
    RewriteRule ^/?(.*) "ws://127.0.0.1:8000/$1" [P,L]

    # Serve static files directly from filesystem (faster than proxying)
    Alias /static /var/www/p2p-exchange/app/static
    <Directory /var/www/p2p-exchange/app/static>
        Options -Indexes              # Disable directory listing
        AllowOverride None
        Require all granted
        ExpiresActive On
        ExpiresDefault "access plus 1 week"
    </Directory>

    # Security Headers
    # X-Frame-Options: Prevent clickjacking
    Header always set X-Frame-Options "DENY"

    # X-Content-Type-Options: Prevent MIME type sniffing
    Header always set X-Content-Type-Options "nosniff"

    # X-XSS-Protection: Legacy XSS protection (belt-and-suspenders)
    Header always set X-XSS-Protection "1; mode=block"

    # Referrer-Policy: Don't leak URL to external sites (important for Tor)
    Header always set Referrer-Policy "no-referrer"

    # Permissions-Policy: Disable browser features we don't use
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"

    # Content-Security-Policy: Restrict resource loading (XSS mitigation)
    # No external CDN resources — everything is self-hosted (required for Tor)
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';"

    # Remove server identification headers
    Header always unset Server
    Header always unset X-Powered-By

    # Logging
    ErrorLog ${APACHE_LOG_DIR}/p2p-exchange-error.log
    CustomLog ${APACHE_LOG_DIR}/p2p-exchange-access.log combined

    # Deny access to hidden files (.env, .git, etc.)
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>
</VirtualHost>
```

### 7.3 Enable Site and Test

```bash
sudo a2ensite p2p-exchange
sudo a2dissite 000-default

# Test configuration syntax
sudo apache2ctl configtest
# Expected: Syntax OK

# Reload Apache
sudo systemctl reload apache2
```

### 7.4 HTTPS with Let's Encrypt (Clearnet Deployment)

```bash
# Install certbot
sudo apt install -y certbot python3-certbot-apache

# Obtain certificate
sudo certbot --apache -d p2pexchange.example.com

# Auto-renewal test
sudo certbot renew --dry-run

# Verify auto-renewal timer
sudo systemctl status certbot.timer
```

### 7.5 Apache Log Locations

```bash
# Access log
sudo tail -f /var/log/apache2/p2p-exchange-access.log

# Error log
sudo tail -f /var/log/apache2/p2p-exchange-error.log

# All Apache logs
ls -la /var/log/apache2/
```

---

## Tor Hidden Service

### 8.1 Install Tor

```bash
sudo apt install -y tor

# Verify Tor version
tor --version
```

### 8.2 Configure Tor Hidden Service

```bash
sudo vim /etc/tor/torrc
```

Add at the end:
```
# P2P XMR Exchange Hidden Service
HiddenServiceDir /var/lib/tor/p2p-exchange/
HiddenServicePort 80 127.0.0.1:8000
HiddenServiceVersion 3
```

### 8.3 Set Correct Directory Permissions

```bash
# Create directory with correct permissions
sudo mkdir -p /var/lib/tor/p2p-exchange
sudo chown -R debian-tor:debian-tor /var/lib/tor/p2p-exchange
sudo chmod 700 /var/lib/tor/p2p-exchange

# Restart Tor to generate keys
sudo systemctl restart tor

# Verify Tor is running
sudo systemctl status tor
```

### 8.4 Retrieve Your .onion Address

```bash
# Wait a moment for Tor to generate keys
sleep 10

# Read your .onion address
sudo cat /var/lib/tor/p2p-exchange/hostname
# Example output: abc123def456ghi7.onion
```

### 8.5 Update Application with .onion Address

```bash
# Add to .env
echo "ONION_ADDRESS=$(sudo cat /var/lib/tor/p2p-exchange/hostname)" \
    >> /var/www/p2p-exchange/.env
```

### 8.6 Test via Tor Browser

1. Download Tor Browser from https://www.torproject.org/
2. Open Tor Browser
3. Navigate to `http://youronionaddress.onion`
4. Verify the site loads correctly

### 8.7 Verify Tor Hidden Service Security

```bash
# Check that only Tor process owns the key files
sudo ls -la /var/lib/tor/p2p-exchange/

# Expected permissions:
# drwx------ 2 debian-tor debian-tor  ... .
# -rw------- 1 debian-tor debian-tor  ... hostname
# -rw------- 1 debian-tor debian-tor  ... hs_ed25519_public_key
# -rw------- 1 debian-tor debian-tor  ... hs_ed25519_secret_key
```

---

## Systemd Service Files

### 9.1 Gunicorn Service

The service file is at `deploy/p2p-exchange.service`. Install it:

```bash
sudo cp /var/www/p2p-exchange/deploy/p2p-exchange.service \
    /etc/systemd/system/p2p-exchange.service

# Create required directories
sudo mkdir -p /var/log/p2p-exchange /var/run/p2p-exchange
sudo chown p2p:p2p /var/log/p2p-exchange /var/run/p2p-exchange

sudo systemctl daemon-reload
sudo systemctl enable p2p-exchange
sudo systemctl start p2p-exchange

# Check status
sudo systemctl status p2p-exchange

# View logs
sudo journalctl -u p2p-exchange -f
```

Full Gunicorn service file (`deploy/p2p-exchange.service`):

```ini
[Unit]
Description=P2P XMR Exchange (Gunicorn)
After=network.target postgresql.service

[Service]
Type=notify
User=p2p
Group=p2p
WorkingDirectory=/var/www/p2p-exchange
EnvironmentFile=/var/www/p2p-exchange/.env
ExecStart=/var/www/p2p-exchange/venv/bin/gunicorn \
    --bind 127.0.0.1:8000 \
    --workers 4 \
    --worker-class sync \
    --timeout 120 \
    --keep-alive 5 \
    --access-logfile /var/log/p2p-exchange/access.log \
    --error-logfile /var/log/p2p-exchange/error.log \
    --log-level info \
    --pid /var/run/p2p-exchange/gunicorn.pid \
    app.main:app
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

### 9.2 Monero Wallet RPC Service

See [Monero Wallet RPC Setup](#monero-daemon--wallet-rpc-setup) above.

### 9.3 Common systemctl Commands

```bash
# Start service
sudo systemctl start p2p-exchange

# Stop service
sudo systemctl stop p2p-exchange

# Restart service
sudo systemctl restart p2p-exchange

# Reload configuration (graceful restart)
sudo systemctl reload p2p-exchange

# Enable at boot
sudo systemctl enable p2p-exchange

# Disable at boot
sudo systemctl disable p2p-exchange

# Check status
sudo systemctl status p2p-exchange

# View last 100 log lines
sudo journalctl -u p2p-exchange -n 100

# Follow logs in real time
sudo journalctl -u p2p-exchange -f

# View logs since last boot
sudo journalctl -u p2p-exchange -b

# View logs from specific time
sudo journalctl -u p2p-exchange --since "2024-01-01 00:00:00"
```

---

## Configuration Reference

All configuration is via environment variables in `.env`.

| Variable | Description | Default | Example |
|---|---|---|---|
| `SECRET_KEY` | Flask session secret | `dev-secret-key...` | `$(openssl rand -hex 32)` |
| `HMAC_SECRET` | HMAC for session tokens | `dev-hmac-secret...` | `$(openssl rand -hex 32)` |
| `FLASK_ENV` | Flask environment | `development` | `production` |
| `DATABASE_URL` | Production DB URL | SQLite | `postgresql://user:pass@localhost/db` |
| `DATABASE_URL_DEV` | Dev DB URL | `sqlite:///p2p_exchange.db` | `sqlite:///dev.db` |
| `MONERO_RPC_URL` | Monero wallet RPC URL | `http://127.0.0.1:18083/json_rpc` | comma-separated for failover |
| `MONERO_RPC_USER` | RPC username | empty | `rpcuser` |
| `MONERO_RPC_PASS` | RPC password | empty | `rpcpassword` |
| `MONERO_WALLET_ADDRESS` | Main wallet address | empty | `4ABC...` |
| `ESCROW_TIMEOUT_HOURS` | Trade escrow timeout | `24` | `48` |
| `TRADE_FEE_PERCENT` | Platform fee % | `0.5` | `1.0` |
| `MAX_TRADE_XMR` | Maximum trade size | `100.0` | `50.0` |
| `MIN_TRADE_XMR` | Minimum trade size | `0.01` | `0.1` |
| `RATE_LIMIT_PER_MINUTE` | API rate limit | `60 per minute` | `30 per minute` |
| `SESSION_LIFETIME_DAYS` | Session duration | `30` | `7` |
| `SITE_URL` | Public site URL | `http://localhost:5000` | `https://p2pexchange.com` |
| `ONION_ADDRESS` | Tor .onion address | empty | `abc123.onion` |
| `LOG_LEVEL` | Logging level | `INFO` | `DEBUG` |
| `LOG_FILE` | Log file path | empty | `/var/log/p2p-exchange/app.log` |
| `SMTP_HOST` | SMTP server | empty | `smtp.gmail.com` |
| `SMTP_PORT` | SMTP port | `587` | `465` |
| `SMTP_USER` | SMTP username | empty | `admin@example.com` |
| `SMTP_PASS` | SMTP password | empty | `app-password` |
| `WTF_CSRF_ENABLED` | Enable CSRF protection | `True` | `False` (dev only) |
| `CORS_ORIGINS` | CORS allowed origins | `*` | `https://p2pexchange.com` |

### Production .env Example

```ini
SECRET_KEY=a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
HMAC_SECRET=f6e5d4c3b2a1f6e5d4c3b2a1f6e5d4c3b2a1f6e5d4c3b2a1f6e5d4c3b2a1f6e5
FLASK_ENV=production
DATABASE_URL=postgresql://p2puser:SecurePassword123@localhost/p2pexchange
MONERO_RPC_URL=http://127.0.0.1:18083/json_rpc
MONERO_RPC_USER=rpcuser
MONERO_RPC_PASS=rpcpassword
MONERO_WALLET_ADDRESS=4YourMoneroWalletAddressHere
ESCROW_TIMEOUT_HOURS=24
TRADE_FEE_PERCENT=0.5
MAX_TRADE_XMR=100.0
MIN_TRADE_XMR=0.01
RATE_LIMIT_PER_MINUTE=60
SESSION_LIFETIME_DAYS=30
SITE_URL=https://p2pexchange.example.com
ONION_ADDRESS=youronionaddress.onion
LOG_LEVEL=INFO
LOG_FILE=/var/log/p2p-exchange/app.log
WTF_CSRF_ENABLED=True
```

### Development .env Example

```ini
SECRET_KEY=dev-only-secret-not-for-production
HMAC_SECRET=dev-only-hmac-not-for-production
FLASK_ENV=development
DATABASE_URL_DEV=sqlite:///p2p_exchange.db
MONERO_RPC_URL=http://127.0.0.1:18083/json_rpc
ESCROW_TIMEOUT_HOURS=1
TRADE_FEE_PERCENT=0.5
MAX_TRADE_XMR=100.0
MIN_TRADE_XMR=0.001
LOG_LEVEL=DEBUG
WTF_CSRF_ENABLED=False
```

---

## API Reference

All API endpoints are prefixed with `/api`.

### Authentication (`/api/auth`)

#### `GET /api/auth/mnemonic/generate`
Generate a new BIP39 mnemonic and X25519 keypair.

**Response:**
```json
{
  "mnemonic": "word1 word2 ... word12",
  "public_key": "base64-encoded-public-key",
  "public_key_hex": "hex-encoded-public-key"
}
```

#### `POST /api/auth/mnemonic/recover`
Recover keypair from existing mnemonic.

**Request:**
```json
{"mnemonic": "word1 word2 ... word12"}
```

**Response (200):**
```json
{
  "public_key": "base64-encoded-public-key",
  "public_key_hex": "hex-encoded-public-key"
}
```

#### `POST /api/auth/session`
Create or restore a session.

**Request:**
```json
{"public_key": "base64-key", "display_name": "Trader"}
```

**Response (201):**
```json
{"token": "session-token", "user": {...}}
```

#### `GET /api/auth/verify`
Verify current session. Requires `X-Session-Token` header.

**Response (200):**
```json
{"valid": true, "user": {"id": 1, "display_name": "Trader", "trust_level": "Bronze"}}
```

#### `POST /api/auth/mnemonic/bind`
Bind a mnemonic to your account for recovery.

**Request:**
```json
{"mnemonic": "word1 word2 ... word12"}
```

#### `POST /api/auth/logout`
Invalidate current session.

**Response (200):**
```json
{"message": "Logged out successfully."}
```

---

### Offers (`/api/offers`)

#### `GET /api/offers`
List offers with optional filtering.

**Query Parameters:**
- `type` — `buy` or `sell`
- `fiat_currency` — e.g. `USD`, `EUR`
- `payment_method` — partial match
- `country` — partial match
- `page` — page number (default: 1)
- `per_page` — results per page (default: 20, max: 100)
- `sort` — `created_at` (default) or `price`

**Response:**
```json
{
  "offers": [...],
  "total": 42,
  "page": 1,
  "pages": 3,
  "per_page": 20
}
```

#### `GET /api/offers/<id>`
Get a specific offer.

**Response (200):**
```json
{
  "id": 1,
  "type": "sell",
  "user": {"id": 2, "display_name": "Trader", "trust_level": "Gold"},
  "fiat_currency": "USD",
  "payment_method": "Bank Transfer",
  "price_type": "market",
  "margin_percent": 2.0,
  "min_amount": 50.0,
  "max_amount": 500.0,
  "terms": "Payment within 30 minutes.",
  "country": "US",
  "active": true,
  "created_at": "2024-01-01T00:00:00"
}
```

#### `POST /api/offers`
Create a new offer. Requires authentication.

**Request:**
```json
{
  "type": "sell",
  "fiat_currency": "USD",
  "payment_method": "Bank Transfer",
  "price_type": "market",
  "margin_percent": 2.0,
  "min_amount": 50.0,
  "max_amount": 500.0,
  "terms": "Payment within 30 minutes.",
  "country": "US"
}
```

**Response (201):**
```json
{"id": 1, "message": "Offer created successfully."}
```

#### `PUT /api/offers/<id>`
Update an offer (owner only).

**Request:** Same fields as POST (partial update supported).

**Response (200):**
```json
{"message": "Offer updated successfully."}
```

#### `DELETE /api/offers/<id>`
Deactivate an offer (owner only).

**Response (200):**
```json
{"message": "Offer deactivated."}
```

---

### Trades (`/api/trades`)

#### `GET /api/trades`
List your trades (buyer or seller). Requires authentication.

**Query Parameters:**
- `status` — filter by status (e.g. `initiated`, `escrow_funded`, `completed`)
- `page` — page number
- `per_page` — results per page

**Response:**
```json
{
  "trades": [...],
  "total": 5,
  "page": 1,
  "pages": 1
}
```

#### `GET /api/trades/<id>`
Get trade details. Requires authentication + participant.

**Response (200):**
```json
{
  "id": 1,
  "offer_id": 1,
  "buyer": {"id": 3, "display_name": "Buyer"},
  "seller": {"id": 2, "display_name": "Seller"},
  "amount_xmr": 0.5,
  "amount_fiat": 75.0,
  "fiat_currency": "USD",
  "payment_method": "Bank Transfer",
  "status": "escrow_funded",
  "escrow_address": "4SubAddress...",
  "created_at": "2024-01-01T00:00:00",
  "expires_at": "2024-01-02T00:00:00"
}
```

#### `POST /api/trades`
Initiate a new trade. Requires authentication.

**Request:**
```json
{"offer_id": 1, "amount_xmr": 0.5, "amount_fiat": 75.0}
```

**Response (201):**
```json
{
  "id": 1,
  "escrow_address": "4SubAddress...",
  "message": "Trade initiated. Seller must fund escrow."
}
```

#### `POST /api/trades/<id>/confirm_escrow`
Seller confirms XMR locked in escrow.

**Request:**
```json
{"txid": "optional-transaction-id"}
```

**Response (200):**
```json
{"message": "Escrow confirmed. Buyer can now send fiat payment."}
```

#### `POST /api/trades/<id>/fiat_sent`
Buyer marks fiat payment as sent.

**Response (200):**
```json
{"message": "Fiat payment marked as sent. Awaiting seller confirmation."}
```

#### `POST /api/trades/<id>/fiat_received`
Seller confirms fiat received (releases escrow).

**Response (200):**
```json
{"message": "Fiat received confirmed. Releasing XMR to buyer."}
```

#### `POST /api/trades/<id>/complete`
Complete trade and release XMR to buyer.

**Response (200):**
```json
{"message": "Trade completed successfully.", "txid": "transaction-id"}
```

#### `POST /api/trades/<id>/cancel`
Cancel trade (only in `initiated` or `escrow_funded` state).

**Response (200):**
```json
{"message": "Trade cancelled."}
```

#### `POST /api/trades/<id>/dispute`
Open a dispute.

**Request:**
```json
{"reason": "Payment not received after 2 hours."}
```

**Response (200):**
```json
{"message": "Dispute opened. A moderator will review within 24 hours."}
```

---

### Chat (`/api/chat`)

#### `GET /api/chat/trade/<trade_id>`
Get encrypted messages for a trade.

**Query Parameters:**
- `since_id` — Only return messages after this ID (for polling)

**Response:**
```json
{
  "messages": [
    {
      "id": 1,
      "trade_id": 1,
      "sender_id": 2,
      "encrypted_content": "base64-ciphertext",
      "nonce": "base64-nonce",
      "ephemeral_public_key": "base64-key",
      "created_at": "2024-01-01T00:00:00"
    }
  ]
}
```

#### `POST /api/chat/trade/<trade_id>`
Send an encrypted message.

**Request:**
```json
{
  "encrypted_content": "base64-ciphertext",
  "nonce": "base64-nonce",
  "ephemeral_public_key": "base64-ephemeral-key"
}
```

**Response (201):**
```json
{"id": 1, "message": "Message sent."}
```

---

### Wallet (`/api/wallet`)

#### `GET /api/wallet/balance`
Get XMR wallet balance.

**Response:**
```json
{"balance": 1.5, "unlocked_balance": 1.2}
```

#### `POST /api/wallet/deposit`
Generate a deposit subaddress.

**Response:**
```json
{"address": "4SubAddress...", "address_index": 1}
```

#### `POST /api/wallet/withdraw`
Withdraw XMR.

**Request:**
```json
{"address": "4RecipientAddress...", "amount_xmr": 0.5}
```

**Response (200):**
```json
{"txid": "transaction-id", "message": "Withdrawal submitted."}
```

#### `GET /api/wallet/transactions`
Get transaction history.

**Response:**
```json
{
  "transactions": [
    {
      "txid": "abc123...",
      "type": "in",
      "amount_xmr": 0.5,
      "confirmations": 10,
      "timestamp": "2024-01-01T00:00:00"
    }
  ]
}
```

#### `GET /api/wallet/status`
Get Monero network status (height, connectivity).

**Response:**
```json
{
  "connected": true,
  "height": 3000000,
  "target_height": 3000000,
  "synchronized": true
}
```

---

## Testing

### Install Dependencies

```bash
pip install pytest pytest-cov
```

### Run All Tests

```bash
cd p2p-exchange
pytest tests/ -v
```

### Run with Coverage

```bash
pytest tests/ -v --cov=app --cov-report=html --cov-report=term-missing
```

### Run Specific Test File

```bash
pytest tests/test_encryption.py -v
pytest tests/test_trades.py -v
```

### Test Categories

| File | Tests |
|---|---|
| `test_encryption.py` | Mnemonic generation, keypair derivation, HMAC, E2E encrypt/decrypt |
| `test_auth.py` | Session create/verify, mnemonic generate/recover/bind, logout |
| `test_offers.py` | CRUD, filtering, pagination, ownership checks |
| `test_trades.py` | State machine transitions, cancel, dispute |
| `test_reputation.py` | Score calculation, trust level thresholds |

### Sample Test Output

```
tests/test_encryption.py::test_mnemonic_generation PASSED
tests/test_encryption.py::test_keypair_from_mnemonic PASSED
tests/test_encryption.py::test_e2e_encrypt_decrypt PASSED
tests/test_encryption.py::test_hmac_token PASSED
tests/test_auth.py::test_session_create PASSED
tests/test_auth.py::test_session_verify PASSED
tests/test_auth.py::test_mnemonic_generate PASSED
tests/test_auth.py::test_mnemonic_recover PASSED
tests/test_auth.py::test_logout PASSED
tests/test_offers.py::test_create_offer PASSED
tests/test_offers.py::test_list_offers_filter PASSED
tests/test_offers.py::test_offer_pagination PASSED
tests/test_offers.py::test_offer_ownership PASSED
tests/test_trades.py::test_trade_initiate PASSED
tests/test_trades.py::test_trade_escrow_flow PASSED
tests/test_trades.py::test_trade_cancel PASSED
tests/test_trades.py::test_trade_dispute PASSED
tests/test_reputation.py::test_score_calculation PASSED
tests/test_reputation.py::test_trust_levels PASSED
====== 20 passed in 3.45s ======
```

### Writing Tests

Use the `conftest.py` fixtures for test setup:

```python
# tests/conftest.py
import pytest
from app import create_app, db

@pytest.fixture
def app():
    app = create_app('testing')
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def auth_headers(client):
    # Generate mnemonic and create session
    resp = client.get('/api/auth/mnemonic/generate')
    data = resp.get_json()
    session_resp = client.post('/api/auth/session', json={
        'public_key': data['public_key'],
        'display_name': 'TestTrader'
    })
    token = session_resp.get_json()['token']
    return {'X-Session-Token': token}
```

---

## Operational Guide

### Log Rotation

```bash
sudo vim /etc/logrotate.d/p2p-exchange
```

```
/var/log/p2p-exchange/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    sharedscripts
    postrotate
        systemctl reload p2p-exchange
    endscript
}
```

```bash
# Test rotation
sudo logrotate --debug /etc/logrotate.d/p2p-exchange
```

### PostgreSQL Backup

```bash
# Full database backup
sudo -u p2p pg_dump -h localhost -U p2puser p2pexchange | \
    gzip > /var/backups/p2pexchange_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore
gunzip < /var/backups/p2pexchange_20240101_120000.sql.gz | \
    sudo -u p2p psql -h localhost -U p2puser p2pexchange

# Automated daily backup with cron
sudo crontab -e -u p2p
# Add: 0 2 * * * pg_dump -h localhost -U p2puser p2pexchange | gzip > /var/backups/p2pexchange_$(date +\%Y\%m\%d).sql.gz
```

### Updating the Application

```bash
sudo systemctl stop p2p-exchange

cd /var/www/p2p-exchange
sudo -u p2p git pull origin main

# Install any new dependencies
sudo -u p2p venv/bin/pip install -r requirements.txt

# Run database migrations (if any)
sudo -u p2p bash -c "source venv/bin/activate && \
    FLASK_ENV=production python3 -c \"from app import create_app, db; \
    app = create_app('production'); \
    app.app_context().push(); db.create_all()\""

sudo systemctl start p2p-exchange
sudo systemctl status p2p-exchange
```

### Health Monitoring

```bash
# Check the health endpoint
curl -s http://localhost:8000/health
# Expected: {"status": "ok", "version": "1.0.0"}

# Check all services
sudo systemctl status p2p-exchange postgresql@14-main apache2 tor

# Check Apache is proxying correctly
curl -s -o /dev/null -w "%{http_code}" http://localhost/
# Expected: 200

# Monitor memory usage
free -h
ps aux | grep gunicorn

# Monitor disk usage
df -h
du -sh /var/www/p2p-exchange /var/log/p2p-exchange /var/lib/postgresql
```

### PostgreSQL Database Maintenance

```bash
# Vacuum and analyze (run periodically)
sudo -u p2p psql -h localhost -U p2puser p2pexchange -c "VACUUM ANALYZE;"

# Check database size
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('p2pexchange'));"

# Check table sizes
sudo -u p2p psql -h localhost -U p2puser p2pexchange -c "
SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

### Monero Wallet Backup

```bash
# Backup wallet files (do this regularly!)
sudo -u p2p cp /var/lib/monero/exchange_wallet /var/backups/exchange_wallet_$(date +%Y%m%d)
sudo -u p2p cp /var/lib/monero/exchange_wallet.keys /var/backups/exchange_wallet_$(date +%Y%m%d).keys

# Store these files securely offline!
# The .keys file contains your private spend key.
```

### Automated Monitoring Script

Create a simple health check script:

```bash
sudo vim /usr/local/bin/p2p-health-check.sh
```

```bash
#!/bin/bash
# P2P Exchange Health Check Script

SERVICES=("p2p-exchange" "postgresql@14-main" "apache2" "tor" "monero-wallet-rpc")
FAILED=()

for service in "${SERVICES[@]}"; do
    if ! systemctl is-active --quiet "$service"; then
        FAILED+=("$service")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "CRITICAL: Failed services: ${FAILED[*]}"
    # Optionally send alert email here
    exit 1
else
    echo "OK: All services running"
    exit 0
fi
```

```bash
sudo chmod +x /usr/local/bin/p2p-health-check.sh

# Add to cron for regular checks
sudo crontab -e
# Add: */5 * * * * /usr/local/bin/p2p-health-check.sh >> /var/log/p2p-exchange/health.log 2>&1
```

---

## Security Hardening Checklist

### fail2ban Configuration

```bash
sudo apt install -y fail2ban

# Create local jail configuration
sudo vim /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = 2222
logpath = %(sshd_log)s

[apache-auth]
enabled = true
logpath = /var/log/apache2/*error.log
maxretry = 5

[apache-badbots]
enabled = true
logpath = /var/log/apache2/*access.log

[apache-noscript]
enabled = true
logpath = /var/log/apache2/*access.log

[apache-overflows]
enabled = true
logpath = /var/log/apache2/*access.log
maxretry = 2
```

```bash
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

### Kernel Hardening (sysctl.conf)

```bash
sudo vim /etc/sysctl.conf
```

Add:
```ini
# Disable IP forwarding
net.ipv4.ip_forward = 0

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Log Martian packets
net.ipv4.conf.all.log_martians = 1

# Enable SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048

# Disable source routing
net.ipv4.conf.all.accept_source_route = 0

# Disable ICMP broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Protection from time-wait assassination
net.ipv4.tcp_rfc1337 = 1

# Restrict dmesg to root
kernel.dmesg_restrict = 1

# Disable core dumps for setuid programs
fs.suid_dumpable = 0
```

```bash
sudo sysctl -p
```

### File Permission Audit

```bash
# Application files
sudo find /var/www/p2p-exchange -type f -name "*.py" -exec chmod 640 {} \;
sudo find /var/www/p2p-exchange -type d -exec chmod 750 {} \;
sudo chown -R p2p:p2p /var/www/p2p-exchange
sudo chmod 600 /var/www/p2p-exchange/.env

# Log files
sudo chmod 750 /var/log/p2p-exchange
sudo chown p2p:p2p /var/log/p2p-exchange

# Monero wallet
sudo chmod 700 /var/lib/monero
sudo chmod 600 /var/lib/monero/exchange_wallet*
sudo chown -R p2p:p2p /var/lib/monero
```

### Apache Server Token Hardening

```bash
sudo vim /etc/apache2/conf-available/security.conf
```

```apache
# Hide Apache version from error pages and headers
ServerTokens Prod
ServerSignature Off

# Disable TRACE method (XST attack vector)
TraceEnable Off
```

```bash
sudo a2enconf security
sudo systemctl reload apache2
```

### ModSecurity Web Application Firewall (Optional)

```bash
# Install ModSecurity
sudo apt install -y libapache2-mod-security2

# Enable ModSecurity
sudo a2enmod security2

# Copy default config
sudo cp /etc/modsecurity/modsecurity.conf-recommended \
    /etc/modsecurity/modsecurity.conf

# Enable detection mode
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' \
    /etc/modsecurity/modsecurity.conf

sudo systemctl restart apache2
```

### Security Checklist

- [ ] Non-root service user (`p2p`) created
- [ ] SSH root login disabled
- [ ] SSH password authentication disabled
- [ ] UFW firewall enabled with minimal rules
- [ ] fail2ban installed and configured
- [ ] Unattended security upgrades enabled
- [ ] Swap file configured
- [ ] `.env` file permissions set to 600
- [ ] PostgreSQL password authentication configured
- [ ] Apache server tokens hidden
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)
- [ ] Tor hidden service directory permissions set to 700
- [ ] Log rotation configured
- [ ] Regular backup schedule established
- [ ] Kernel hardening applied
- [ ] Python 3.12 (latest security patches)
- [ ] All dependencies pinned in requirements.txt
- [ ] Monero wallet backup stored securely offline
- [ ] fail2ban SSH jail enabled on custom port
- [ ] ModSecurity WAF installed (optional)

---

## Docker Deployment

### Quick Docker Start

```bash
cp .env.example .env
# Edit .env with your settings
./setup.sh --docker
```

### Manual Docker Compose

```bash
# Build and start
docker compose -f deploy/docker-compose.yml up -d --build

# View logs
docker compose -f deploy/docker-compose.yml logs -f web

# Run tests in container
docker compose -f deploy/docker-compose.yml exec web pytest tests/ -v

# Stop
docker compose -f deploy/docker-compose.yml down

# Stop and remove volumes (CAUTION: deletes data)
docker compose -f deploy/docker-compose.yml down -v
```

### Docker Environment Variables

Set these in `.env` for Docker:
```ini
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://p2puser:${POSTGRES_PASSWORD}@db:5432/p2pexchange
```

### Dockerfile (Multi-Stage Build)

```dockerfile
# deploy/Dockerfile

# --- Build stage ---
FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --- Runtime stage ---
FROM python:3.12-slim

# Install libsodium
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsodium23 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 -s /bin/bash p2p

WORKDIR /app

# Copy installed packages from build stage
COPY --from=builder /install /usr/local

# Copy application code
COPY --chown=p2p:p2p . .

USER p2p

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app.main:app"]
```

### docker-compose.yml

```yaml
# deploy/docker-compose.yml
version: '3.9'

services:
  web:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    restart: unless-stopped
    env_file: ../.env
    environment:
      - DATABASE_URL=postgresql://p2puser:${POSTGRES_PASSWORD}@db:5432/p2pexchange
    ports:
      - "127.0.0.1:8000:8000"
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - app_logs:/var/log/p2p-exchange

  db:
    image: postgres:14-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=p2puser
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=p2pexchange
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U p2puser -d p2pexchange"]
      interval: 10s
      timeout: 5s
      retries: 5

  tor:
    image: goldy/tor-hidden-service:latest
    restart: unless-stopped
    environment:
      - TOR_SERVICE_HOSTS=80:web:8000
      - TOR_SERVICE_VERSION=3
    volumes:
      - tor_keys:/var/lib/tor/hidden_service

volumes:
  postgres_data:
  app_logs:
  tor_keys:
```

### Docker Networking Notes

- The `web` container binds to `127.0.0.1:8000` on the host — Apache on the host proxies to it.
- Alternatively, run Apache inside Docker using an `nginx` or `httpd` container.
- The `tor` container automatically creates a hidden service pointing to `web:8000`.

---

## Troubleshooting

### Application Won't Start

```bash
# Check service logs
sudo journalctl -u p2p-exchange -n 50

# Check if port 8000 is in use
sudo ss -tlpn | grep 8000

# Test gunicorn manually
sudo -u p2p bash -c "cd /var/www/p2p-exchange && source venv/bin/activate && \
    gunicorn --bind 127.0.0.1:8000 app.main:app"
```

### Database Connection Errors

```bash
# Test PostgreSQL connection
sudo -u p2p psql -h localhost -U p2puser -d p2pexchange -c "SELECT 1;"

# Check PostgreSQL is running
sudo systemctl status postgresql@14-main

# Check pg_hba.conf
sudo grep -v '^#' /etc/postgresql/14/main/pg_hba.conf
```

### Monero RPC Errors

```bash
# Check wallet RPC is running
sudo systemctl status monero-wallet-rpc

# Test RPC endpoint
curl -u rpcuser:rpcpassword \
    http://127.0.0.1:18083/json_rpc \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_version"}' \
    -H 'Content-Type: application/json'

# Check logs
sudo journalctl -u monero-wallet-rpc -n 50
```

### Apache Proxy Issues

```bash
# Verify modules are loaded
apache2ctl -M | grep proxy

# Test Apache config
sudo apache2ctl configtest

# Check error log
sudo tail -f /var/log/apache2/p2p-exchange-error.log

# Test Gunicorn directly
curl http://127.0.0.1:8000/health
```

### Tor Hidden Service Not Working

```bash
# Check Tor is running
sudo systemctl status tor

# Verify hostname file exists
sudo ls -la /var/lib/tor/p2p-exchange/

# Check Tor logs
sudo journalctl -u tor -n 50

# Verify permissions (MUST be 700)
sudo stat /var/lib/tor/p2p-exchange/
```

### Import Errors / Missing Modules

```bash
# Verify virtual environment
source /var/www/p2p-exchange/venv/bin/activate
python -c "import flask, nacl, mnemonic; print('OK')"

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### SSL Certificate Issues

```bash
# Check certificate status
sudo certbot certificates

# Force renewal
sudo certbot renew --force-renewal

# Check Apache SSL config
sudo apache2ctl -S
```

### Out of Memory Errors

```bash
# Check memory usage
free -h
ps aux --sort=-%mem | head -20

# Check if swap is active
swapon --show

# Reduce Gunicorn workers if needed
# Edit /etc/systemd/system/p2p-exchange.service
# Change --workers 4 to --workers 2
sudo systemctl daemon-reload
sudo systemctl restart p2p-exchange
```

### PostgreSQL "too many connections"

```bash
# Check current connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check max_connections setting
sudo -u postgres psql -c "SHOW max_connections;"

# Increase if needed (in postgresql.conf)
# max_connections = 100
sudo systemctl restart postgresql@14-main
```

### Permission Denied Errors

```bash
# Fix ownership of application files
sudo chown -R p2p:p2p /var/www/p2p-exchange

# Fix log directory permissions
sudo chown -R p2p:p2p /var/log/p2p-exchange
sudo chmod 755 /var/log/p2p-exchange

# Fix wallet permissions
sudo chown -R p2p:p2p /var/lib/monero
sudo chmod 700 /var/lib/monero
```

---

## Build & Run Commands

### Development

```bash
# Setup
./setup.sh --dev

# Activate environment
source venv/bin/activate

# Start development server
FLASK_ENV=development flask run

# Or with gunicorn
gunicorn --bind 127.0.0.1:5000 --reload app.main:app

# Run tests
pytest tests/ -v

# Run tests with coverage
pytest tests/ -v --cov=app --cov-report=term-missing

# Initialize/reset database
python3 -c "from app import create_app, db; app = create_app('development'); app.app_context().push(); db.drop_all(); db.create_all()"
```

### Production

```bash
# Automated setup (run as root on Ubuntu 20.04)
sudo ./setup.sh --production

# Manual Gunicorn start
gunicorn \
    --bind 127.0.0.1:8000 \
    --workers 4 \
    --timeout 120 \
    --access-logfile /var/log/p2p-exchange/access.log \
    --error-logfile /var/log/p2p-exchange/error.log \
    app.main:app

# Restart service
sudo systemctl restart p2p-exchange
```

---

## License

MIT License. See LICENSE file.

---

## Security Policy

Found a security vulnerability? Please report it privately. Do not open a public issue.

This software is provided as-is for educational and research purposes. Users are responsible for compliance with local laws and regulations.
