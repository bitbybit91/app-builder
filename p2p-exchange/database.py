import sqlite3
from flask import current_app, g


def get_db():
    if 'db' not in g:
        db_path = current_app.config.get('DATABASE', 'exchange.db')
        if db_path == ':memory:':
            # For testing: use a per-app persistent connection
            app = current_app._get_current_object()
            if not hasattr(app, '_test_db'):
                conn = sqlite3.connect(':memory:', check_same_thread=False)
                conn.row_factory = sqlite3.Row
                app._test_db = conn
                _create_tables(conn)
            g.db = app._test_db
        else:
            conn = sqlite3.connect(db_path, detect_types=sqlite3.PARSE_DECLTYPES)
            conn.row_factory = sqlite3.Row
            g.db = conn
    return g.db


def close_db(e=None):
    db = g.pop('db', None)
    # Don't close in-memory test connections
    if db is not None and current_app.config.get('DATABASE') != ':memory:':
        db.close()


def _create_tables(db):
    db.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            monero_address TEXT,
            monero_account_index INTEGER DEFAULT 0,
            balance_xmr REAL DEFAULT 0.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS offers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            offer_type TEXT NOT NULL CHECK(offer_type IN ('buy', 'sell')),
            crypto_currency TEXT NOT NULL DEFAULT 'XMR',
            fiat_currency TEXT NOT NULL,
            price_margin REAL NOT NULL DEFAULT 0.0,
            min_amount REAL NOT NULL,
            max_amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            terms TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS trades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            offer_id INTEGER NOT NULL,
            buyer_id INTEGER NOT NULL,
            seller_id INTEGER NOT NULL,
            amount_xmr REAL NOT NULL,
            amount_fiat REAL NOT NULL,
            fiat_currency TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','escrow_funded','fiat_sent','completed','disputed','cancelled')),
            escrow_tx_id TEXT,
            release_tx_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (offer_id) REFERENCES offers(id),
            FOREIGN KEY (buyer_id) REFERENCES users(id),
            FOREIGN KEY (seller_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            tx_type TEXT NOT NULL CHECK(tx_type IN ('deposit','withdrawal','escrow_lock','escrow_release','escrow_refund')),
            amount_xmr REAL NOT NULL,
            tx_hash TEXT,
            monero_address TEXT,
            status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','confirmed','failed')),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );

        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trade_id INTEGER NOT NULL,
            sender_id INTEGER NOT NULL,
            message_text TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (trade_id) REFERENCES trades(id),
            FOREIGN KEY (sender_id) REFERENCES users(id)
        );
    """)
    db.commit()


def init_db():
    db = get_db()
    _create_tables(db)


def init_app(app):
    app.teardown_appcontext(close_db)
