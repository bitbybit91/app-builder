import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    DATABASE = os.environ.get('DATABASE_PATH', os.path.join(os.path.dirname(__file__), 'exchange.db'))
    SESSION_TYPE = 'filesystem'
    SESSION_FILE_DIR = os.environ.get('SESSION_FILE_DIR', os.path.join(os.path.dirname(__file__), 'flask_session'))
    SESSION_PERMANENT = True
    PERMANENT_SESSION_LIFETIME = timedelta(days=int(os.environ.get('SESSION_LIFETIME_DAYS', 30)))
    MONERO_RPC_URL = os.environ.get('MONERO_RPC_URL', 'http://127.0.0.1:18082/json_rpc')
    MONERO_RPC_USER = os.environ.get('MONERO_RPC_USER', '')
    MONERO_RPC_PASS = os.environ.get('MONERO_RPC_PASS', '')
    COINGECKO_CACHE_TTL = int(os.environ.get('COINGECKO_CACHE_TTL', 300))
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024
    WTF_CSRF_ENABLED = False

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False

class TestingConfig(Config):
    TESTING = True
    DEBUG = True
    DATABASE = ':memory:'
    SESSION_TYPE = 'null'
    WTF_CSRF_ENABLED = False
    COINGECKO_CACHE_TTL = 300

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig,
}
