"""
Configuration Management
========================
Loads settings from environment variables / .env file.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class BaseConfig:
    """Base configuration shared across all environments."""

    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-change-me')
    DEBUG = False
    TESTING = False

    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///p2p_exchange.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    AUTO_CREATE_TABLES = False

    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'jwt-dev-secret')
    JWT_ACCESS_TOKEN_EXPIRES = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', 3600))
    JWT_REFRESH_TOKEN_EXPIRES = int(os.getenv('JWT_REFRESH_TOKEN_EXPIRES', 86400))

    # Session
    SESSION_HMAC_KEY = os.getenv('SESSION_HMAC_KEY', 'hmac-dev-key')

    # Rate limiting
    RATELIMIT_DEFAULT = os.getenv('RATE_LIMIT_DEFAULT', '100/hour')

    # Monero RPC
    XMR_RPC_ENDPOINTS = [
        ep.strip()
        for ep in os.getenv(
            'XMR_RPC_ENDPOINTS',
            'http://node.moneroworld.com:18089',
        ).split(',')
        if ep.strip()
    ]
    XMR_RPC_USER = os.getenv('XMR_RPC_USER', '')
    XMR_RPC_PASSWORD = os.getenv('XMR_RPC_PASSWORD', '')
    XMR_WALLET_RPC_URL = os.getenv('XMR_WALLET_RPC_URL', 'http://127.0.0.1:18083/json_rpc')
    XMR_WALLET_RPC_USER = os.getenv('XMR_WALLET_RPC_USER', '')
    XMR_WALLET_RPC_PASSWORD = os.getenv('XMR_WALLET_RPC_PASSWORD', '')

    # Escrow
    ESCROW_CONFIRMATIONS_REQUIRED = int(os.getenv('ESCROW_CONFIRMATIONS_REQUIRED', 10))
    ESCROW_TIMEOUT_HOURS = int(os.getenv('ESCROW_TIMEOUT_HOURS', 24))
    ARBITRATION_BOND_PERCENT = float(os.getenv('ARBITRATION_BOND_PERCENT', 5))

    # Notifications — SMTP
    SMTP_HOST = os.getenv('SMTP_HOST', '')
    SMTP_PORT = int(os.getenv('SMTP_PORT', 587))
    SMTP_USER = os.getenv('SMTP_USER', '')
    SMTP_PASSWORD = os.getenv('SMTP_PASSWORD', '')
    SMTP_FROM = os.getenv('SMTP_FROM', 'noreply@example.onion')

    # Tor
    TOR_ENABLED = os.getenv('TOR_ENABLED', 'false').lower() == 'true'
    ONION_ADDRESS = os.getenv('ONION_ADDRESS', '')

    # Server
    SERVER_NAME_CUSTOM = os.getenv('SERVER_NAME', 'localhost')
    SERVER_PORT = int(os.getenv('SERVER_PORT', 80))


class DevelopmentConfig(BaseConfig):
    """Development-specific settings."""

    DEBUG = True
    AUTO_CREATE_TABLES = True
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///p2p_exchange_dev.db')


class ProductionConfig(BaseConfig):
    """Production settings — all secrets MUST come from environment."""

    DEBUG = False
    AUTO_CREATE_TABLES = False


class TestingConfig(BaseConfig):
    """Testing settings — in-memory SQLite."""

    TESTING = True
    DEBUG = True
    AUTO_CREATE_TABLES = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    WTF_CSRF_ENABLED = False


config_map = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
}
