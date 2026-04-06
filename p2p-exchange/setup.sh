#!/usr/bin/env bash
# P2P XMR Exchange Setup Script
# Supports: --dev | --production | --docker
# Ubuntu 20.04 targeted

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step() { echo -e "\n${BLUE}==>${NC} $*"; }

confirm() {
    read -r -p "$1 [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

trap 'err "Setup failed at line $LINENO. Check the output above for details."; exit 1' ERR

# ─────────────────────────────────────────────
# DEV MODE
# ─────────────────────────────────────────────
setup_dev() {
    step "Setting up development environment"

    log "Creating Python virtual environment..."
    python3.12 -m venv venv || python3 -m venv venv
    # shellcheck source=/dev/null
    source venv/bin/activate

    log "Installing Python dependencies..."
    pip install --upgrade pip -q
    pip install -r requirements.txt -q

    if [[ ! -f .env ]]; then
        log "Creating .env from .env.example..."
        cp .env.example .env
        SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        HMAC=$(python3 -c "import secrets; print(secrets.token_hex(32))")
        sed -i "s/your-secret-key-here-change-in-production/$SECRET/" .env
        sed -i "s/your-hmac-secret-change-in-production/$HMAC/" .env
        sed -i "s/^FLASK_ENV=.*/FLASK_ENV=development/" .env
        sed -i "s|^DATABASE_URL=.*|DATABASE_URL=sqlite:///p2p_exchange.db|" .env
        log "Generated .env with random secrets."
    else
        warn ".env already exists, skipping."
    fi

    log "Initializing SQLite database..."
    FLASK_ENV=development python3 -c "
from app import create_app, db
app = create_app('development')
with app.app_context():
    db.create_all()
    print('Database tables created.')
"

    log "Running tests..."
    python3 -m pytest tests/ -v --tb=short || warn "Some tests failed - check above"

    echo ""
    log "${GREEN}Development setup complete!${NC}"
    echo ""
    echo "  Activate venv:  source venv/bin/activate"
    echo "  Start server:   flask run  OR  python -m app.main"
    echo "  Run tests:      pytest tests/ -v"
    echo "  App URL:        http://127.0.0.1:5000"
}

# ─────────────────────────────────────────────
# PRODUCTION MODE
# ─────────────────────────────────────────────
setup_production() {
    step "Setting up production environment on Ubuntu 20.04"

    if [[ $EUID -ne 0 ]]; then
        err "Production setup must be run as root (sudo ./setup.sh --production)"
        exit 1
    fi

    confirm "This will install system packages and configure the server. Continue?" || exit 0

    step "Updating system packages..."
    apt-get update -qq
    apt-get upgrade -y -qq

    step "Installing Python 3.12 via deadsnakes PPA..."
    apt-get install -y software-properties-common -qq
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update -qq
    apt-get install -y python3.12 python3.12-venv python3.12-dev -qq

    step "Installing system dependencies..."
    apt-get install -y --no-install-recommends \
        libsodium-dev \
        libpq-dev \
        gcc \
        curl \
        git \
        ufw \
        fail2ban \
        apache2 \
        tor \
        -qq

    step "Installing PostgreSQL 14..."
    if ! dpkg -l postgresql-14 &>/dev/null; then
        curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list
        apt-get update -qq
        apt-get install -y postgresql-14 postgresql-client-14 -qq
    fi

    step "Creating p2p service user..."
    if ! id -u p2p &>/dev/null; then
        useradd -r -m -d /var/www/p2p-exchange -s /bin/bash p2p
        log "Created user 'p2p'"
    fi

    step "Setting up application directory..."
    APP_DIR="/var/www/p2p-exchange"
    mkdir -p "$APP_DIR"
    mkdir -p /var/log/p2p-exchange
    mkdir -p /var/run/p2p-exchange
    chown p2p:p2p "$APP_DIR" /var/log/p2p-exchange /var/run/p2p-exchange

    log "Copying application files..."
    rsync -a --exclude='.git' --exclude='venv' --exclude='__pycache__' --exclude='*.pyc' \
        "$(dirname "$0")/" "$APP_DIR/"
    chown -R p2p:p2p "$APP_DIR"

    step "Creating virtual environment..."
    sudo -u p2p python3.12 -m venv "$APP_DIR/venv"
    sudo -u p2p "$APP_DIR/venv/bin/pip" install --upgrade pip -q
    sudo -u p2p "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt" -q

    step "Configuring PostgreSQL..."
    DB_PASS=$(python3 -c "import secrets; print(secrets.token_urlsafe(24))")
    sudo -u postgres psql -c "CREATE USER p2puser WITH PASSWORD '$DB_PASS';" 2>/dev/null || warn "User may already exist"
    sudo -u postgres psql -c "CREATE DATABASE p2pexchange OWNER p2puser;" 2>/dev/null || warn "Database may already exist"

    step "Generating production .env..."
    SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    HMAC=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    cat > "$APP_DIR/.env" << EOF
SECRET_KEY=$SECRET
HMAC_SECRET=$HMAC
FLASK_ENV=production
DATABASE_URL=postgresql://p2puser:$DB_PASS@localhost/p2pexchange
MONERO_RPC_URL=http://127.0.0.1:18083/json_rpc
MONERO_RPC_USER=
MONERO_RPC_PASS=
ESCROW_TIMEOUT_HOURS=24
TRADE_FEE_PERCENT=0.5
MAX_TRADE_XMR=100.0
MIN_TRADE_XMR=0.01
RATE_LIMIT_PER_MINUTE=60
SESSION_LIFETIME_DAYS=30
SITE_URL=http://$(hostname -f 2>/dev/null || echo 'localhost')
LOG_LEVEL=INFO
LOG_FILE=/var/log/p2p-exchange/app.log
EOF
    chmod 600 "$APP_DIR/.env"
    chown p2p:p2p "$APP_DIR/.env"

    step "Initializing database tables..."
    sudo -u p2p bash -c "cd $APP_DIR && source venv/bin/activate && FLASK_ENV=production python3 -c \"
from app import create_app, db
app = create_app('production')
with app.app_context():
    db.create_all()
    print('Tables created.')
\""

    step "Configuring Apache2..."
    a2enmod proxy proxy_http proxy_wstunnel headers rewrite expires 2>/dev/null || true
    cp "$APP_DIR/deploy/apache.conf" /etc/apache2/sites-available/p2p-exchange.conf
    a2ensite p2p-exchange
    a2dissite 000-default 2>/dev/null || true
    apache2ctl configtest && systemctl reload apache2

    step "Configuring Tor hidden service..."
    mkdir -p /var/lib/tor/p2p-exchange
    chown debian-tor:debian-tor /var/lib/tor/p2p-exchange
    chmod 700 /var/lib/tor/p2p-exchange
    cat >> /etc/tor/torrc << 'TOREOF'
HiddenServiceDir /var/lib/tor/p2p-exchange/
HiddenServicePort 80 127.0.0.1:8000
HiddenServiceVersion 3
TOREOF
    systemctl enable tor && systemctl restart tor

    step "Installing systemd service..."
    cp "$APP_DIR/deploy/p2p-exchange.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable p2p-exchange
    systemctl start p2p-exchange

    step "Configuring UFW firewall..."
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable

    step "Configuring fail2ban..."
    systemctl enable fail2ban && systemctl start fail2ban

    sleep 3
    ONION=$(cat /var/lib/tor/p2p-exchange/hostname 2>/dev/null || echo 'not-yet-available')

    echo ""
    log "${GREEN}Production setup complete!${NC}"
    echo ""
    echo "  App URL (clearnet):  http://$(hostname -f 2>/dev/null || echo 'your-server-ip')"
    echo "  App URL (Tor):       http://$ONION"
    echo "  App directory:       $APP_DIR"
    echo "  Logs:                /var/log/p2p-exchange/"
    echo "  Service:             systemctl status p2p-exchange"
    echo "  PostgreSQL pass:     $DB_PASS (saved in .env)"
}

# ─────────────────────────────────────────────
# DOCKER MODE
# ─────────────────────────────────────────────
setup_docker() {
    step "Setting up Docker environment"

    if ! command -v docker &>/dev/null; then
        err "Docker is not installed. Install it from https://docs.docker.com/engine/install/"
        exit 1
    fi
    if ! command -v docker compose &>/dev/null && ! docker-compose version &>/dev/null 2>&1; then
        err "Docker Compose is not installed."
        exit 1
    fi

    if [[ ! -f .env ]]; then
        log "Copying .env.example to .env..."
        cp .env.example .env
        SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || openssl rand -hex 32)
        HMAC=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || openssl rand -hex 32)
        PGPASS=$(python3 -c "import secrets; print(secrets.token_urlsafe(20))" 2>/dev/null || openssl rand -base64 20)
        sed -i "s/your-secret-key-here-change-in-production/$SECRET/" .env
        sed -i "s/your-hmac-secret-change-in-production/$HMAC/" .env
        echo "POSTGRES_PASSWORD=$PGPASS" >> .env
        log "Generated .env with random secrets."
    else
        warn ".env already exists, skipping."
    fi

    step "Building and starting Docker containers..."
    docker compose -f deploy/docker-compose.yml up -d --build

    log "Waiting for services to start..."
    sleep 5

    step "Checking container status..."
    docker compose -f deploy/docker-compose.yml ps

    echo ""
    log "${GREEN}Docker setup complete!${NC}"
    echo ""
    echo "  App URL:   http://localhost:8000"
    echo "  Logs:      docker compose -f deploy/docker-compose.yml logs -f"
    echo "  Stop:      docker compose -f deploy/docker-compose.yml down"
    echo "  Shell:     docker compose -f deploy/docker-compose.yml exec web bash"
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
usage() {
    echo "Usage: $0 [--dev | --production | --docker]"
    echo ""
    echo "  --dev         Set up development environment (virtualenv + SQLite)"
    echo "  --production  Set up production environment (Ubuntu 20.04, requires root)"
    echo "  --docker      Set up Docker environment"
    echo ""
}

cd "$(dirname "$0")"

case "${1:-}" in
    --dev)        setup_dev ;;
    --production) setup_production ;;
    --docker)     setup_docker ;;
    *)            usage; exit 1 ;;
esac
