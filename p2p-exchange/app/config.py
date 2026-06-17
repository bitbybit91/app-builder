import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    HMAC_SECRET = os.environ.get('HMAC_SECRET', 'dev-hmac-secret-change-in-production')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = 3600
    MAX_CONTENT_LENGTH = int(os.environ.get('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))
    SESSION_LIFETIME_DAYS = int(os.environ.get('SESSION_LIFETIME_DAYS', 30))
    PERMANENT_SESSION_LIFETIME = timedelta(days=int(os.environ.get('SESSION_LIFETIME_DAYS', 30)))

    # Rate limiting
    RATELIMIT_DEFAULT = os.environ.get('RATE_LIMIT_PER_MINUTE', '60 per minute')
    RATELIMIT_STORAGE_URL = 'memory://'

    # Monero RPC
    MONERO_RPC_URL = os.environ.get('MONERO_RPC_URL', 'http://127.0.0.1:18083/json_rpc')
    MONERO_RPC_USER = os.environ.get('MONERO_RPC_USER', '')
    MONERO_RPC_PASS = os.environ.get('MONERO_RPC_PASS', '')
    MONERO_WALLET_ADDRESS = os.environ.get('MONERO_WALLET_ADDRESS', '')

    # Trade settings
    ESCROW_TIMEOUT_HOURS = int(os.environ.get('ESCROW_TIMEOUT_HOURS', 24))
    TRADE_FEE_PERCENT = float(os.environ.get('TRADE_FEE_PERCENT', 0.5))
    MAX_TRADE_XMR = float(os.environ.get('MAX_TRADE_XMR', 100.0))
    MIN_TRADE_XMR = float(os.environ.get('MIN_TRADE_XMR', 0.01))

    # Site settings
    SITE_URL = os.environ.get('SITE_URL', 'http://localhost:5000')
    ONION_ADDRESS = os.environ.get('ONION_ADDRESS', '')

    # Notifications
    SMTP_HOST = os.environ.get('SMTP_HOST', '')
    SMTP_PORT = int(os.environ.get('SMTP_PORT', 587))
    SMTP_USER = os.environ.get('SMTP_USER', '')
    SMTP_PASS = os.environ.get('SMTP_PASS', '')
    NOSTR_PRIVATE_KEY = os.environ.get('NOSTR_PRIVATE_KEY', '')

    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*')


class DevelopmentConfig(Config):
    DEBUG = True
    FLASK_ENV = 'development'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL_DEV', 'sqlite:///p2p_exchange.db')
    WTF_CSRF_ENABLED = False


class ProductionConfig(Config):
    DEBUG = False
    FLASK_ENV = 'production'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///p2p_exchange.db')
    WTF_CSRF_ENABLED = True


class TestingConfig(Config):
    TESTING = True
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    WTF_CSRF_ENABLED = False
    RATELIMIT_ENABLED = False


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
