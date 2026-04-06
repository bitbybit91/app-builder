#!/usr/bin/env bash
# =============================================================================
# P2P Exchange — Automated Setup Script
# =============================================================================
# Usage:
#   chmod +x setup.sh
#   sudo ./setup.sh          # Full setup (deps + Apache + Tor + DB + keys)
#   ./setup.sh --dev          # Development setup (Python deps + DB only)
#   ./setup.sh --docker       # Docker setup (build + run containers)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# =============================================================================
# Development Setup
# =============================================================================

setup_dev() {
    log "Setting up development environment..."

    # Check Python
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is required. Install it first."
    fi

    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    log "Python version: $PYTHON_VERSION"

    # Create virtual environment
    if [ ! -d "venv" ]; then
        log "Creating virtual environment..."
        python3 -m venv venv
    fi

    log "Activating virtual environment..."
    # shellcheck disable=SC1091
    source venv/bin/activate

    # Install Python dependencies
    log "Installing Python dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create .env from template if not exists
    if [ ! -f ".env" ]; then
        log "Creating .env from template..."
        cp .env.example .env
        # Generate random secrets
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        HMAC_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

        sed -i "s/change-me-to-a-random-64-char-hex-string/$SECRET_KEY/" .env
        sed -i "s/change-me-to-a-random-jwt-secret/$JWT_SECRET/" .env
        # Update the HMAC key (second occurrence)
        sed -i "0,/change-me-to-a-random-64-char-hex-string/{s/change-me-to-a-random-64-char-hex-string/$HMAC_KEY/}" .env

        log "Generated random secrets in .env"
    else
        warn ".env already exists, skipping."
    fi

    # Initialize database
    log "Initializing database..."
    FLASK_ENV=development python3 -c "
from app import create_app, db
app = create_app('development')
with app.app_context():
    db.create_all()
    print('Database tables created.')
"

    log "Development setup complete!"
    echo ""
    echo "  To start the dev server:"
    echo "    source venv/bin/activate"
    echo "    python -m app.main"
    echo ""
    echo "  Then open: http://localhost:5000"
}

# =============================================================================
# Production Setup (Ubuntu/Debian)
# =============================================================================

setup_production() {
    log "Setting up production environment..."

    # Check root
    if [ "$(id -u)" -ne 0 ]; then
        error "Production setup requires root. Run with sudo."
    fi

    # Install system dependencies
    log "Installing system packages..."
    apt-get update
    apt-get install -y \
        python3 python3-pip python3-venv \
        apache2 libapache2-mod-proxy-html \
        tor \
        postgresql postgresql-client \
        libffi-dev libsodium-dev \
        certbot python3-certbot-apache

    # Enable Apache modules
    log "Configuring Apache..."
    a2enmod proxy proxy_http proxy_wstunnel headers rewrite
    cp deploy/apache.conf /etc/apache2/sites-available/p2p-exchange.conf
    a2ensite p2p-exchange
    a2dissite 000-default 2>/dev/null || true

    # Set up application directory
    APP_DIR="/var/www/p2p-exchange"
    log "Setting up application directory at $APP_DIR..."
    mkdir -p "$APP_DIR"
    cp -r . "$APP_DIR/"
    cd "$APP_DIR"

    # Create virtual environment
    python3 -m venv venv
    # shellcheck disable=SC1091
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt

    # Create .env
    if [ ! -f ".env" ]; then
        cp .env.example .env
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        HMAC_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        sed -i "s/change-me-to-a-random-64-char-hex-string/$SECRET_KEY/" .env
        sed -i "s/change-me-to-a-random-jwt-secret/$JWT_SECRET/" .env
        sed -i "0,/change-me-to-a-random-64-char-hex-string/{s/change-me-to-a-random-64-char-hex-string/$HMAC_KEY/}" .env
        sed -i "s|DATABASE_URL=sqlite:///p2p_exchange.db|DATABASE_URL=postgresql://p2p:p2p_secret@localhost:5432/p2p_exchange|" .env
        log "Generated .env with random secrets"
    fi

    # Set up PostgreSQL
    log "Setting up PostgreSQL..."
    sudo -u postgres psql -c "CREATE USER p2p WITH PASSWORD 'p2p_secret';" 2>/dev/null || warn "DB user already exists"
    sudo -u postgres psql -c "CREATE DATABASE p2p_exchange OWNER p2p;" 2>/dev/null || warn "Database already exists"

    # Initialize database tables
    log "Initializing database..."
    FLASK_ENV=production python3 -c "
from app import create_app, db
app = create_app('production')
with app.app_context():
    db.create_all()
    print('Database tables created.')
"

    # Create systemd service for Gunicorn
    log "Creating systemd service..."
    cat > /etc/systemd/system/p2p-exchange.service << 'EOF'
[Unit]
Description=P2P Exchange (Gunicorn)
After=network.target postgresql.service

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/p2p-exchange
Environment="PATH=/var/www/p2p-exchange/venv/bin"
ExecStart=/var/www/p2p-exchange/venv/bin/gunicorn app.main:app \
    --bind 127.0.0.1:8000 \
    --workers 4 \
    --threads 2 \
    --timeout 120 \
    --access-logfile /var/log/p2p-exchange/access.log \
    --error-logfile /var/log/p2p-exchange/error.log
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    mkdir -p /var/log/p2p-exchange
    chown -R www-data:www-data "$APP_DIR" /var/log/p2p-exchange

    systemctl daemon-reload
    systemctl enable p2p-exchange
    systemctl start p2p-exchange

    # Configure Tor hidden service
    log "Configuring Tor hidden service..."
    if ! grep -q "p2p-exchange" /etc/tor/torrc; then
        cat deploy/torrc >> /etc/tor/torrc
        systemctl restart tor
        sleep 3
        if [ -f /var/lib/tor/p2p-exchange/hostname ]; then
            ONION=$(cat /var/lib/tor/p2p-exchange/hostname)
            log "Tor hidden service: $ONION"
            sed -i "s|ONION_ADDRESS=|ONION_ADDRESS=$ONION|" .env
        fi
    fi

    # Reload Apache
    systemctl reload apache2

    log "Production setup complete!"
    echo ""
    echo "  Clearnet:  http://$(hostname -I | awk '{print $1}')"
    if [ -f /var/lib/tor/p2p-exchange/hostname ]; then
        echo "  Tor:       http://$(cat /var/lib/tor/p2p-exchange/hostname)"
    fi
    echo ""
    echo "  Manage:"
    echo "    sudo systemctl status p2p-exchange"
    echo "    sudo journalctl -u p2p-exchange -f"
    echo "    sudo tail -f /var/log/p2p-exchange/error.log"
}

# =============================================================================
# Docker Setup
# =============================================================================

setup_docker() {
    log "Setting up with Docker..."

    if ! command -v docker &> /dev/null; then
        error "Docker is required. Install it first: https://docs.docker.com/get-docker/"
    fi

    # Create .env if needed
    if [ ! -f ".env" ]; then
        cp .env.example .env
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || openssl rand -hex 32)
        JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || openssl rand -hex 32)
        sed -i "s/change-me-to-a-random-64-char-hex-string/$SECRET_KEY/" .env
        sed -i "s/change-me-to-a-random-jwt-secret/$JWT_SECRET/" .env
        log "Generated .env"
    fi

    log "Building and starting containers..."
    docker compose -f deploy/docker-compose.yml up -d --build

    log "Docker setup complete!"
    echo ""
    echo "  Application: http://localhost:8000"
    echo "  Logs:        docker compose -f deploy/docker-compose.yml logs -f"
    echo "  Stop:        docker compose -f deploy/docker-compose.yml down"
}

# =============================================================================
# Main
# =============================================================================

case "${1:-}" in
    --dev)
        setup_dev
        ;;
    --docker)
        setup_docker
        ;;
    --production|"")
        if [ "$(id -u)" -eq 0 ]; then
            setup_production
        else
            setup_dev
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [--dev|--docker|--production]"
        echo ""
        echo "  --dev         Development setup (Python venv + SQLite)"
        echo "  --docker      Docker setup (build + run containers)"
        echo "  --production  Full production setup (requires root)"
        echo "  --help        Show this help"
        ;;
    *)
        error "Unknown option: $1. Use --help for usage."
        ;;
esac
