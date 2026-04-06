"""
P2P Exchange — Flask Application Factory
=========================================
No-KYC, non-custodial P2P cryptocurrency exchange for XMR trading.
"""

import logging
import os

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_wtf.csrf import CSRFProtect

db = SQLAlchemy()
migrate = Migrate()
csrf = CSRFProtect()
limiter = Limiter(
    key_func=get_remote_address,
    storage_uri='memory://',
)


def create_app(config_name=None):
    """
    Application factory.

    Args:
        config_name: Configuration class name ('development', 'production', 'testing').
                     Defaults to FLASK_ENV environment variable.

    Returns:
        Configured Flask application instance.
    """
    app = Flask(__name__)

    # Load configuration
    from app.config import config_map
    env = config_name or os.getenv('FLASK_ENV', 'development')
    app.config.from_object(config_map[env])

    # Configure logging
    _setup_logging(app)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    csrf.init_app(app)
    limiter.init_app(app)

    # Security headers
    _register_security_headers(app)

    # Register blueprints
    _register_blueprints(app)

    # Create database tables (development only)
    with app.app_context():
        from app import models  # noqa: F401 — import models so SQLAlchemy knows them
        if app.config.get('AUTO_CREATE_TABLES', False):
            db.create_all()

    app.logger.info('P2P Exchange application initialized (env=%s)', env)
    return app


def _setup_logging(app):
    """Configure structured logging."""
    log_level = logging.DEBUG if app.config.get('DEBUG') else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
    )
    app.logger.setLevel(log_level)


def _register_security_headers(app):
    """Attach strict security headers to every response."""

    @app.after_request
    def set_security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Referrer-Policy'] = 'no-referrer'
        response.headers['Permissions-Policy'] = 'geolocation=(), camera=(), microphone=()'
        # Strict CSP — no inline scripts, no external resources (Tor-friendly)
        response.headers['Content-Security-Policy'] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data:; "
            "font-src 'self'; "
            "connect-src 'self' wss:; "
            "frame-ancestors 'none'; "
            "base-uri 'self'; "
            "form-action 'self';"
        )
        if not app.config.get('DEBUG'):
            response.headers['Strict-Transport-Security'] = (
                'max-age=31536000; includeSubDomains'
            )
        return response


def _register_blueprints(app):
    """Register all route blueprints."""
    from app.routes.auth import auth_bp
    from app.routes.offers import offers_bp
    from app.routes.trades import trades_bp
    from app.routes.chat import chat_bp
    from app.routes.wallet import wallet_bp
    from app.routes.main_routes import main_bp

    app.register_blueprint(main_bp)
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(offers_bp, url_prefix='/api/offers')
    app.register_blueprint(trades_bp, url_prefix='/api/trades')
    app.register_blueprint(chat_bp, url_prefix='/api/chat')
    app.register_blueprint(wallet_bp, url_prefix='/api/wallet')

    # Exempt API routes from CSRF (they use token auth)
    csrf.exempt(auth_bp)
    csrf.exempt(offers_bp)
    csrf.exempt(trades_bp)
    csrf.exempt(chat_bp)
    csrf.exempt(wallet_bp)
