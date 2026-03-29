<?php

require_once __DIR__ . '/../src/Core/Database.php';
require_once __DIR__ . '/../src/Core/App.php';

use App\Core\Database;
use App\Core\App;

// Bootstrap minimal config for database path
$config = require __DIR__ . '/../config/app.php';
$dbPath = $config['db']['path'];
$dir = dirname($dbPath);
if (!is_dir($dir)) {
    mkdir($dir, 0755, true);
}

$pdo = new PDO('sqlite:' . $dbPath);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec('PRAGMA journal_mode=WAL');
$pdo->exec('PRAGMA foreign_keys=ON');

echo "Running migrations...\n";

$pdo->exec("
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        bio TEXT DEFAULT '',
        trades_completed INTEGER DEFAULT 0,
        reputation REAL DEFAULT 0.0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
");
echo "  ✓ users table\n";

$pdo->exec("
    CREATE TABLE IF NOT EXISTS trades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('buy', 'sell')),
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        amount_min REAL NOT NULL,
        amount_max REAL NOT NULL,
        price_per_xmr REAL,
        currency TEXT NOT NULL DEFAULT 'USD',
        payment_method TEXT NOT NULL,
        location TEXT DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed', 'completed', 'cancelled', 'disputed')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )
");
echo "  ✓ trades table\n";

$pdo->exec("
    CREATE TABLE IF NOT EXISTS trade_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trade_id INTEGER NOT NULL,
        responder_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        message TEXT DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'rejected', 'completed', 'cancelled')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trade_id) REFERENCES trades(id),
        FOREIGN KEY (responder_id) REFERENCES users(id)
    )
");
echo "  ✓ trade_responses table\n";

$pdo->exec("
    CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trade_response_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        body TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trade_response_id) REFERENCES trade_responses(id),
        FOREIGN KEY (sender_id) REFERENCES users(id)
    )
");
echo "  ✓ messages table\n";

$pdo->exec("
    CREATE TABLE IF NOT EXISTS contact_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
");
echo "  ✓ contact_messages table\n";

$pdo->exec("CREATE INDEX IF NOT EXISTS idx_trades_user ON trades(user_id)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_trades_type ON trades(type)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_trades_status ON trades(status)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_responses_trade ON trade_responses(trade_id)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_messages_response ON messages(trade_response_id)");
echo "  ✓ indexes\n";

echo "\nMigrations complete!\n";
