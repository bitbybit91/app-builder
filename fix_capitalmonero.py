#!/usr/bin/env python3
"""
fix_capitalmonero.py  v2
========================
Complete, self-contained deployment fix for the CapitalMonero Exchange.
Inspired by localcoinswap.com — P2P BTC/XMR trading platform.

Fixes ALL causes of the 500 Server Error and builds the full Laravel 8 app.

Domain  : capitalmonero.com
Onion   : fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion
AppRoot : /var/www/capitalmonero/app
Stack   : Laravel 8 / Bootstrap 4 / Apache / MariaDB / Redis / Tor / PHP 7.4

Run as root:
  sudo python3 fix_capitalmonero.py
"""

import os, sys, re, shutil, subprocess, textwrap, secrets, string
from pathlib import Path

# ============================================================================
# Constants
# ============================================================================
APP_ROOT  = "/var/www/capitalmonero/app"
DOMAIN    = "capitalmonero.com"
ONION     = "fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion"
DB_NAME   = "capitalmonero"
DB_USER   = "capitalmonero"
# DB / admin passwords: generated randomly each deployment so every install
# has a unique credential. Override via environment variable if needed.
_alpha    = string.ascii_letters + string.digits + "!@#%^&*"
DB_PASS   = os.environ.get("CM_DB_PASS") or (
    "Cm" + "".join(secrets.choice(_alpha) for _ in range(20))
)
ADMIN_PASS = os.environ.get("CM_ADMIN_PASS") or (
    "Adm" + "".join(secrets.choice(_alpha) for _ in range(18))
)
CERT_DIR  = "/etc/ssl/capitalmonero"
COMPOSER  = "/usr/local/bin/composer"

# Detect best available PHP binary
def _pick_php():
    for v in ["php7.4", "php8.1", "php8.0", "php8.2", "php"]:
        if shutil.which(v):
            return v
    return "php"

PHP_BIN = _pick_php()

# ============================================================================
# Helpers
# ============================================================================
BOLD  = "\033[1m"
GREEN = "\033[32m"
YELLOW= "\033[33m"
RED   = "\033[31m"
RESET = "\033[0m"

def log(msg):
    print(f"\n{BOLD}[*]{RESET} {msg}")

def ok(msg):
    print(f"  {GREEN}[OK]{RESET} {msg}")

def warn(msg):
    print(f"  {YELLOW}[WARN]{RESET} {msg}", file=sys.stderr)

def err(msg):
    print(f"  {RED}[ERR]{RESET} {msg}", file=sys.stderr)


def run(cmd, cwd=None, env=None, stdin_data=None, quiet=False):
    """Run command (list=no-shell, str=shell).  Returns CompletedProcess.
    SECURITY: string commands must be hardcoded literals only.
    """
    kwargs = dict(capture_output=True, text=True)
    if cwd:
        kwargs["cwd"] = cwd
    if env:
        kwargs["env"] = {**os.environ, **env}
    if stdin_data is not None:
        kwargs["input"] = stdin_data
    if isinstance(cmd, list):
        result = subprocess.run(cmd, **kwargs)
    else:
        result = subprocess.run(cmd, shell=True, **kwargs)
    if not quiet and result.stdout.strip():
        for line in result.stdout.strip().splitlines()[-20:]:
            print(f"    {line}")
    if result.returncode != 0 and not quiet:
        snippet = (result.stderr or "").strip()
        for line in snippet.splitlines()[-10:]:
            warn(line)
    return result


def run_checked(cmd, cwd=None, env=None, stdin_data=None, msg=""):
    """Like run() but exits on failure."""
    r = run(cmd, cwd=cwd, env=env, stdin_data=stdin_data)
    if r.returncode != 0:
        err(f"FATAL: {msg or 'command failed'}")
        err((r.stderr or "").strip()[-600:])
        sys.exit(1)
    return r


def wf(path, content, mode=0o644):
    """Write content to path, creating parent directories."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    os.chmod(path, mode)


def mkdirs(*paths):
    for p in paths:
        Path(p).mkdir(parents=True, exist_ok=True)


def apt_install(*pkgs):
    env = {"DEBIAN_FRONTEND": "noninteractive"}
    run(["apt-get", "install", "-y", "--no-install-recommends"] + list(pkgs),
        env=env)


# ============================================================================
# Step 0 – System package installation
# ============================================================================
def install_system_packages():
    log("Step 0: Installing/verifying system packages")

    run(["apt-get", "update", "-qq"],
        env={"DEBIAN_FRONTEND": "noninteractive"})

    # PHP 7.4 + extensions
    apt_install(
        "php7.4", "php7.4-cli", "php7.4-fpm",
        "php7.4-mysql", "php7.4-mbstring", "php7.4-xml",
        "php7.4-curl", "php7.4-zip", "php7.4-bcmath",
        "php7.4-json", "php7.4-tokenizer", "php7.4-redis",
        "php7.4-gd", "php7.4-intl",
        "libapache2-mod-php7.4",
    )

    # Web server
    apt_install("apache2")

    # Database
    apt_install("mariadb-server", "mariadb-client")

    # Cache / sessions
    apt_install("redis-server")

    # Node.js (nodesource builds bundle npm; the separate 'npm' apt package
    # conflicts with those builds – so we only install nodejs here and verify
    # npm separately below)
    apt_install("nodejs")
    # Install npm only when it is not already provided by nodejs
    npm_check = run(["npm", "--version"], quiet=True)
    if npm_check.returncode != 0:
        apt_install("npm")

    # Tools
    apt_install("curl", "git", "unzip", "openssl", "ufw", "certbot",
                "python3-certbot-apache")

    # Enable & start services
    for svc in ["apache2", "mariadb", "redis-server"]:
        run(["systemctl", "enable", svc], quiet=True)
        run(["systemctl", "start",  svc], quiet=True)

    ok("System packages installed and services started")


def ensure_composer():
    log("Ensuring Composer is installed")
    if shutil.which("composer"):
        ok("Composer already available")
        return
    # Download installer
    r = run(["curl", "-sS", "-o", "/tmp/composer-setup.php",
             "https://getcomposer.org/installer"])
    if r.returncode != 0:
        # Try alternate download method
        r2 = run(["wget", "-q", "-O", "/tmp/composer-setup.php",
                  "https://getcomposer.org/installer"])
        if r2.returncode != 0:
            warn("Cannot download Composer – must be installed manually")
            return
    run([PHP_BIN, "/tmp/composer-setup.php",
         f"--install-dir=/usr/local/bin", "--filename=composer"])
    run(["chmod", "+x", COMPOSER])
    ok("Composer installed")


# ============================================================================
# Fix 1 – Database (SQL via stdin, no shell backtick expansion)
# ============================================================================
def fix_database():
    log("Fix 1: Database setup")
    sql = textwrap.dedent(f"""\
        CREATE DATABASE IF NOT EXISTS `{DB_NAME}`
            CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        CREATE USER IF NOT EXISTS '{DB_USER}'@'localhost'
            IDENTIFIED BY '{DB_PASS}';
        GRANT ALL PRIVILEGES ON `{DB_NAME}`.* TO '{DB_USER}'@'localhost';
        FLUSH PRIVILEGES;
    """)
    r = run(["mariadb", "-u", "root"], stdin_data=sql)
    if r.returncode != 0:
        # Try mysql instead (some systems alias differently)
        r2 = run(["mysql", "-u", "root"], stdin_data=sql)
        if r2.returncode != 0:
            warn("DB setup had errors – may already exist or MariaDB needs root socket auth")
        else:
            ok("Database created via mysql client")
    else:
        ok("Database and user created/verified")


# ============================================================================
# Fix 2 – Composer (valid composer.json, no double-caret)
# ============================================================================
def fix_composer():
    log("Fix 2: Writing valid composer.json and installing dependencies")

    composer_json = r"""{
    "name": "capitalmonero/exchange",
    "type": "project",
    "description": "CapitalMonero P2P Bitcoin & Monero Exchange",
    "license": "MIT",
    "require": {
        "php": "^7.4|^8.0",
        "ext-json": "*",
        "ext-mbstring": "*",
        "ext-pdo": "*",
        "fruitcake/laravel-cors": "^2.0",
        "guzzlehttp/guzzle": "^7.0.1",
        "laravel/framework": "^8.83",
        "laravel/sanctum": "^2.15",
        "laravel/tinker": "^2.7",
        "predis/predis": "^1.1"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9.1",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^5.10",
        "phpunit/phpunit": "^9.5.10"
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true,
        "allow-plugins": {
            "composer/package-versions-deprecated": true
        },
        "audit": {
            "abandoned": "report",
            "ignore": ["PKSA-8qx3-n5y5-vvnd", "PKSA-w7xr-vk7n-rstm"],
            "block-insecure": false
        }
    },
    "extra": {
        "laravel": {
            "dont-discover": []
        }
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\Factories\\": "database/factories/",
            "Database\\Seeders\\": "database/seeders/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    },
    "minimum-stability": "stable",
    "prefer-stable": true,
    "scripts": {
        "post-autoload-dump": [
            "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
            "@php artisan package:discover --ansi"
        ],
        "post-update-cmd": [
            "@php artisan vendor:publish --tag=laravel-assets --ansi --force"
        ],
        "post-root-package-install": [
            "@php -r \"file_exists('.env') || copy('.env.example', '.env');\""
        ],
        "post-create-project-cmd": [
            "@php artisan key:generate --ansi"
        ]
    }
}
"""
    Path(APP_ROOT).mkdir(parents=True, exist_ok=True)
    wf(f"{APP_ROOT}/composer.json", composer_json)

    for stale in ["vendor", "composer.lock"]:
        sp = Path(f"{APP_ROOT}/{stale}")
        if sp.is_dir():
            shutil.rmtree(sp); ok(f"Removed {stale}/")
        elif sp.exists():
            sp.unlink();       ok(f"Removed {stale}")

    c_env = {"COMPOSER_ALLOW_SUPERUSER": "1",
             "COMPOSER_NO_INTERACTION": "1"}
    c_bin = shutil.which("composer") or COMPOSER
    run_checked(
        [c_bin, "install", "--no-interaction", "--prefer-dist",
         "--optimize-autoloader", "--no-scripts", "--no-audit"],
        cwd=APP_ROOT, env=c_env,
        msg="composer install failed"
    )
    ok("Composer dependencies installed")


# ============================================================================
# Fix 3 – NPM / Laravel Mix
# ============================================================================
def fix_npm():
    log("Fix 3: NPM – writing package.json with laravel-mix")

    package_json = r"""{
    "private": true,
    "scripts": {
        "dev":         "npm run development",
        "development": "mix",
        "watch":       "mix watch",
        "prod":        "npm run production",
        "production":  "mix --production"
    },
    "devDependencies": {
        "axios":              "^0.21",
        "bootstrap":          "^4.6.2",
        "jquery":             "^3.6.4",
        "laravel-mix":        "^6.0.49",
        "lodash":             "^4.17.21",
        "popper.js":          "^1.16.1",
        "resolve-url-loader": "^3.1.2",
        "sass":               "^1.32.11",
        "sass-loader":        "^11.0.1"
    }
}
"""
    wf(f"{APP_ROOT}/package.json", package_json)
    for stale in ["node_modules", "package-lock.json"]:
        sp = Path(f"{APP_ROOT}/{stale}")
        if sp.is_dir():
            shutil.rmtree(sp)
        elif sp.exists():
            sp.unlink()
    run(["npm", "install", "--prefix", APP_ROOT])
    ok("NPM packages installed")


# ============================================================================
# Fix 4 – Monerod (Type=simple so it doesn't stay in activating)
# ============================================================================
def fix_monerod():
    log("Fix 4: Monerod – Type=simple systemd unit")
    unit = """\
[Unit]
Description=CapitalMonero Monerod
After=network.target

[Service]
Type=simple
User=capitalmonero
ExecStart=/usr/local/bin/monerod --config-file /etc/capitalmonero/monerod.conf --non-interactive
Restart=always
RestartSec=10
TimeoutStartSec=0
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""
    wf("/etc/systemd/system/capitalmonero-monerod.service", unit)
    run(["systemctl", "daemon-reload"])
    run(["systemctl", "restart", "capitalmonero-monerod"])
    ok("Monerod service rewritten")


# ============================================================================
# Fix 5 – HTTPS (self-signed + Apache vhosts, try Certbot)
# ============================================================================
def fix_https():
    log("Fix 5: HTTPS – SSL cert + Apache vhosts")
    mkdirs(CERT_DIR)

    run([
        "openssl", "req", "-x509", "-nodes", "-days", "3650",
        "-newkey", "rsa:2048",
        "-keyout", f"{CERT_DIR}/key.pem",
        "-out",    f"{CERT_DIR}/cert.pem",
        "-subj",   f"/CN={DOMAIN}/O=CapitalMonero/C=US",
    ])

    vhost_80 = f"""\
<VirtualHost *:80>
    ServerName {DOMAIN}
    ServerAlias www.{DOMAIN}
    Redirect permanent / https://{DOMAIN}/
</VirtualHost>
"""
    vhost_443 = f"""\
<VirtualHost *:443>
    ServerName {DOMAIN}
    ServerAlias www.{DOMAIN}
    DocumentRoot {APP_ROOT}/public

    SSLEngine on
    SSLCertificateFile    {CERT_DIR}/cert.pem
    SSLCertificateKeyFile {CERT_DIR}/key.pem

    <Directory {APP_ROOT}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog  ${{APACHE_LOG_DIR}}/capitalmonero_error.log
    CustomLog ${{APACHE_LOG_DIR}}/capitalmonero_access.log combined
</VirtualHost>
"""
    wf("/etc/apache2/sites-available/capitalmonero-http.conf",  vhost_80)
    wf("/etc/apache2/sites-available/capitalmonero-ssl.conf",   vhost_443)

    for cmd in [
        ["a2enmod", "ssl"], ["a2enmod", "rewrite"], ["a2enmod", "headers"],
        ["a2dissite", "000-default"],
        ["a2ensite", "capitalmonero-http"],
        ["a2ensite", "capitalmonero-ssl"],
    ]:
        run(cmd, quiet=True)

    if shutil.which("certbot"):
        run([
            "certbot", "--apache", "--non-interactive", "--agree-tos",
            "-m", f"admin@{DOMAIN}", "-d", DOMAIN, "--redirect",
        ])

    if shutil.which("ufw"):
        run(["ufw", "allow", "443/tcp"], quiet=True)
        run(["ufw", "allow", "80/tcp"],  quiet=True)

    run(["systemctl", "restart", "apache2"])
    ok("HTTPS configured")


# ============================================================================
# Laravel App – Migration
# ============================================================================
def write_migration():
    log("Writing consolidated migration")
    wf(f"{APP_ROOT}/database/migrations/2024_01_01_000000_create_all_tables.php", r"""<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAllTables extends Migration
{
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('username', 30)->unique();
            $table->string('email')->unique();
            $table->string('password');
            $table->enum('role', ['user', 'admin', 'moderator'])->default('user');
            $table->boolean('is_active')->default(true);
            $table->boolean('two_factor_enabled')->default(false);
            $table->string('two_factor_secret')->nullable();
            $table->decimal('btc_balance', 18, 8)->default(0);
            $table->decimal('xmr_balance', 18, 12)->default(0);
            $table->decimal('escrow_btc', 18, 8)->default(0);
            $table->decimal('escrow_xmr', 18, 12)->default(0);
            $table->string('btc_deposit_address')->nullable();
            $table->string('xmr_deposit_address')->nullable();
            $table->integer('completed_trades')->default(0);
            $table->decimal('rating', 3, 2)->default(0.00);
            $table->text('bio')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->string('preferred_currency', 3)->default('USD');
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['buy', 'sell']);
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->string('fiat_currency', 3)->default('USD');
            $table->decimal('price_margin', 5, 2)->default(0.00);
            $table->decimal('min_amount', 18, 2);
            $table->decimal('max_amount', 18, 2);
            $table->string('payment_method', 100);
            $table->text('terms')->nullable();
            $table->string('country', 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('trade_count')->default(0);
            $table->timestamps();
        });

        Schema::create('trades', function (Blueprint $table) {
            $table->id();
            $table->string('trade_id', 16)->unique();
            $table->foreignId('offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('buyer_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('seller_id')->constrained('users')->onDelete('cascade');
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->decimal('crypto_amount', 18, 8)->default(0);
            $table->decimal('fiat_amount', 18, 2);
            $table->string('fiat_currency', 3)->default('USD');
            $table->string('payment_method', 100);
            $table->enum('status', [
                'open', 'paid', 'released', 'disputed', 'cancelled', 'completed'
            ])->default('open');
            $table->text('cancel_reason')->nullable();
            $table->text('dispute_reason')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('released_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('trade_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->text('message');
            $table->boolean('is_system')->default(false);
            $table->timestamps();
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->string('address')->nullable();
            $table->decimal('balance', 18, 8)->default(0);
            $table->decimal('locked_balance', 18, 8)->default(0);
            $table->timestamps();
        });

        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('txid')->nullable();
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->enum('type', ['deposit', 'withdrawal', 'trade_in', 'trade_out', 'fee']);
            $table->decimal('amount', 18, 8);
            $table->decimal('fee', 18, 8)->default(0);
            $table->string('address')->nullable();
            $table->string('status', 20)->default('pending');
            $table->integer('confirmations')->default(0);
            $table->timestamps();
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('opened_by')->constrained('users')->onDelete('cascade');
            $table->unsignedBigInteger('resolved_by')->nullable();
            $table->foreign('resolved_by')->references('id')->on('users')->nullOnDelete();
            $table->text('reason');
            $table->text('resolution')->nullable();
            $table->string('status', 20)->default('open');
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->text('message');
            $table->boolean('is_read')->default(false);
            $table->timestamps();
        });

        Schema::create('password_resets', function (Blueprint $table) {
            $table->string('email')->index();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();
        });

        Schema::create('failed_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('uuid')->unique();
            $table->text('connection');
            $table->text('queue');
            $table->longText('payload');
            $table->longText('exception');
            $table->timestamp('failed_at')->useCurrent();
        });
    }

    public function down()
    {
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('password_resets');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('disputes');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('trade_messages');
        Schema::dropIfExists('trades');
        Schema::dropIfExists('offers');
        Schema::dropIfExists('users');
    }
}
""")
    ok("Migration written")


# ============================================================================
# Laravel App – Models
# ============================================================================
def write_models():
    log("Writing Eloquent models")

    wf(f"{APP_ROOT}/app/Models/User.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'username','email','password','role','is_active',
        'btc_balance','xmr_balance','escrow_btc','escrow_xmr',
        'btc_deposit_address','xmr_deposit_address',
        'completed_trades','rating','bio','last_seen_at','preferred_currency',
    ];

    protected $hidden = ['password','remember_token','two_factor_secret'];

    protected $casts = [
        'email_verified_at'  => 'datetime',
        'last_seen_at'       => 'datetime',
        'is_active'          => 'boolean',
        'two_factor_enabled' => 'boolean',
        'btc_balance'        => 'decimal:8',
        'xmr_balance'        => 'decimal:12',
        'escrow_btc'         => 'decimal:8',
        'escrow_xmr'         => 'decimal:12',
    ];

    public function offers()           { return $this->hasMany(Offer::class); }
    public function tradesAsBuyer()    { return $this->hasMany(Trade::class, 'buyer_id'); }
    public function tradesAsSeller()   { return $this->hasMany(Trade::class, 'seller_id'); }
    public function wallets()          { return $this->hasMany(Wallet::class); }
    public function transactions()     { return $this->hasMany(Transaction::class); }
    public function userNotifications(){ return $this->hasMany(Notification::class); }
    public function isAdmin()          { return $this->role === 'admin'; }

    public function getAvatarAttribute()
    {
        return 'https://ui-avatars.com/api/?name='
            . urlencode($this->username)
            . '&background=f0883e&color=0d1117&size=40';
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/Offer.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Offer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id','type','crypto','fiat_currency',
        'price_margin','min_amount','max_amount',
        'payment_method','terms','country','is_active','trade_count',
    ];

    protected $casts = [
        'is_active'    => 'boolean',
        'price_margin' => 'decimal:2',
        'min_amount'   => 'decimal:2',
        'max_amount'   => 'decimal:2',
    ];

    public function user()   { return $this->belongsTo(User::class); }
    public function trades() { return $this->hasMany(Trade::class); }
}
""")

    wf(f"{APP_ROOT}/app/Models/Trade.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Trade extends Model
{
    use HasFactory;

    protected $fillable = [
        'trade_id','offer_id','buyer_id','seller_id',
        'crypto','crypto_amount','fiat_amount','fiat_currency',
        'payment_method','status','cancel_reason','dispute_reason',
        'paid_at','released_at','completed_at','expires_at',
    ];

    protected $casts = [
        'crypto_amount' => 'decimal:8',
        'fiat_amount'   => 'decimal:2',
        'paid_at'       => 'datetime',
        'released_at'   => 'datetime',
        'completed_at'  => 'datetime',
        'expires_at'    => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function ($trade) {
            if (empty($trade->trade_id)) {
                $trade->trade_id = strtoupper(Str::random(12));
            }
        });
    }

    public function offer()    { return $this->belongsTo(Offer::class); }
    public function buyer()    { return $this->belongsTo(User::class, 'buyer_id'); }
    public function seller()   { return $this->belongsTo(User::class, 'seller_id'); }
    public function dispute()  { return $this->hasOne(Dispute::class); }
    public function messages() { return $this->hasMany(TradeMessage::class)->orderBy('created_at'); }

    public function isExpired()
    {
        return $this->expires_at && $this->expires_at->isPast()
            && in_array($this->status, ['open', 'paid']);
    }

    public function canBePaidBy(int $userId): bool
    {
        return $this->status === 'open' && $this->buyer_id === $userId;
    }

    public function canBeReleasedBy(int $userId): bool
    {
        return $this->status === 'paid' && $this->seller_id === $userId;
    }

    public function canBeCancelledBy(int $userId): bool
    {
        return in_array($this->status, ['open'])
            && ($this->buyer_id === $userId || $this->seller_id === $userId);
    }

    public function canBeDisputedBy(int $userId): bool
    {
        return in_array($this->status, ['paid'])
            && ($this->buyer_id === $userId || $this->seller_id === $userId);
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/TradeMessage.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TradeMessage extends Model
{
    protected $fillable = ['trade_id', 'user_id', 'message', 'is_system'];

    protected $casts = ['is_system' => 'boolean'];

    public function user()  { return $this->belongsTo(User::class); }
    public function trade() { return $this->belongsTo(Trade::class); }
}
""")

    wf(f"{APP_ROOT}/app/Models/Wallet.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    protected $fillable = ['user_id','crypto','address','balance','locked_balance'];
    protected $casts    = ['balance' => 'decimal:8', 'locked_balance' => 'decimal:8'];
    public function user() { return $this->belongsTo(User::class); }
}
""")

    wf(f"{APP_ROOT}/app/Models/Transaction.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id','txid','crypto','type','amount','fee','address','status','confirmations',
    ];
    protected $casts = ['amount' => 'decimal:8', 'fee' => 'decimal:8'];
    public function user() { return $this->belongsTo(User::class); }
}
""")

    wf(f"{APP_ROOT}/app/Models/Dispute.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    protected $fillable = ['trade_id','opened_by','resolved_by','reason','resolution','status'];

    public function trade()    { return $this->belongsTo(Trade::class); }
    public function opener()   { return $this->belongsTo(User::class, 'opened_by'); }
    public function resolver() { return $this->belongsTo(User::class, 'resolved_by'); }
}
""")

    wf(f"{APP_ROOT}/app/Models/Notification.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $fillable = ['user_id','title','message','is_read'];
    protected $casts    = ['is_read' => 'boolean'];
    public function user() { return $this->belongsTo(User::class); }
}
""")
    ok("Models written")


# ============================================================================
# Laravel App – Controllers (FIXED: middleware in constructors)
# ============================================================================
def write_controllers():
    log("Writing controllers")

    wf(f"{APP_ROOT}/app/Http/Controllers/Controller.php", r"""<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/HomeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use App\Models\User;

class HomeController extends Controller
{
    public function index()
    {
        $stats = [
            'total_users'      => User::count(),
            'active_offers'    => Offer::where('is_active', true)->count(),
            'completed_trades' => Trade::where('status', 'completed')->count(),
        ];

        $buyOffers = Offer::with('user')
            ->where('type', 'buy')->where('is_active', true)
            ->latest()->take(6)->get();

        $sellOffers = Offer::with('user')
            ->where('type', 'sell')->where('is_active', true)
            ->latest()->take(6)->get();

        return view('home', compact('stats', 'buyOffers', 'sellOffers'));
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/AuthController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function __construct()
    {
        $this->middleware('guest')->except('logout');
    }

    public function showLogin()  { return view('auth.login'); }
    public function showRegister(){ return view('auth.register'); }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $request->session()->regenerate();
            Auth::user()->update(['last_seen_at' => now()]);
            return redirect()->intended(route('dashboard'));
        }

        return back()
            ->withErrors(['username' => 'Invalid username or password.'])
            ->onlyInput('username');
    }

    public function register(Request $request)
    {
        $request->validate([
            'username' => 'required|string|min:3|max:30|unique:users|alpha_dash',
            'email'    => 'required|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'username' => $request->username,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        Auth::login($user);
        return redirect()->route('dashboard')
            ->with('success', 'Welcome to CapitalMonero, ' . $user->username . '!');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('home');
    }
}
""")

    # FIX: middleware in constructor, not in methods
    wf(f"{APP_ROOT}/app/Http/Controllers/OfferController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OfferController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth')->only(['create', 'store', 'toggleActive', 'destroy']);
    }

    public function index(Request $request)
    {
        $query = Offer::with('user')->where('is_active', true);

        if ($request->filled('type'))           $query->where('type', $request->type);
        if ($request->filled('crypto'))         $query->where('crypto', $request->crypto);
        if ($request->filled('payment_method')) {
            $query->where('payment_method', 'like', '%' . $request->payment_method . '%');
        }
        if ($request->filled('currency'))       $query->where('fiat_currency', $request->currency);

        $offers = $query->latest()->paginate(20)->withQueryString();
        return view('offers.index', compact('offers'));
    }

    public function show(Offer $offer)
    {
        $offer->load('user');
        return view('offers.show', compact('offer'));
    }

    public function create()
    {
        return view('offers.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type'           => 'required|in:buy,sell',
            'crypto'         => 'required|in:BTC,XMR',
            'fiat_currency'  => 'required|string|size:3',
            'price_margin'   => 'required|numeric|between:-50,50',
            'min_amount'     => 'required|numeric|min:1',
            'max_amount'     => 'required|numeric|gt:min_amount',
            'payment_method' => 'required|string|max:100',
            'terms'          => 'nullable|string|max:3000',
            'country'        => 'nullable|string|size:2',
        ]);
        $data['user_id'] = Auth::id();
        $offer = Offer::create($data);
        return redirect()->route('offers.show', $offer)
            ->with('success', 'Offer posted successfully!');
    }

    public function toggleActive(Offer $offer)
    {
        if ($offer->user_id !== Auth::id()) abort(403);
        $offer->update(['is_active' => !$offer->is_active]);
        $msg = $offer->is_active ? 'Offer activated.' : 'Offer deactivated.';
        return back()->with('success', $msg);
    }

    public function destroy(Offer $offer)
    {
        if ($offer->user_id !== Auth::id()) abort(403);
        $offer->delete();
        return redirect()->route('offers.index')
            ->with('success', 'Offer deleted.');
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/TradeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Dispute;
use App\Models\Offer;
use App\Models\Trade;
use App\Models\TradeMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TradeController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    /** List the authenticated user's trades */
    public function index()
    {
        $userId = Auth::id();
        $trades = Trade::with(['offer', 'buyer', 'seller'])
            ->where(function ($q) use ($userId) {
                $q->where('buyer_id', $userId)->orWhere('seller_id', $userId);
            })
            ->latest()
            ->paginate(20);

        return view('trades.index', compact('trades'));
    }

    /** Start a trade from an offer */
    public function start(Request $request, Offer $offer)
    {
        if (!$offer->is_active)
            return back()->with('error', 'This offer is no longer active.');
        if ($offer->user_id === Auth::id())
            return back()->with('error', 'You cannot trade your own offer.');

        $request->validate([
            'fiat_amount' => 'required|numeric|min:' . $offer->min_amount . '|max:' . $offer->max_amount,
        ]);

        $isBuy = $offer->type === 'sell'; // I am buying → offer is a sell offer
        $trade = Trade::create([
            'offer_id'       => $offer->id,
            'buyer_id'       => $isBuy ? Auth::id() : $offer->user_id,
            'seller_id'      => $isBuy ? $offer->user_id : Auth::id(),
            'crypto'         => $offer->crypto,
            'crypto_amount'  => 0,
            'fiat_amount'    => $request->fiat_amount,
            'fiat_currency'  => $offer->fiat_currency,
            'payment_method' => $offer->payment_method,
            'status'         => 'open',
            'expires_at'     => now()->addHours(1),
        ]);

        TradeMessage::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'message'   => 'Trade started. Please follow the payment instructions.',
            'is_system' => true,
        ]);

        $offer->increment('trade_count');

        return redirect()->route('trades.show', $trade)
            ->with('success', 'Trade opened! Reference ID: ' . $trade->trade_id);
    }

    /** Show a single trade */
    public function show(Trade $trade)
    {
        $userId = Auth::id();
        if ($trade->buyer_id !== $userId && $trade->seller_id !== $userId) abort(403);

        $trade->load(['offer', 'buyer', 'seller', 'messages.user', 'dispute']);
        return view('trades.show', compact('trade'));
    }

    /** Buyer marks they have sent payment */
    public function markPaid(Request $request, Trade $trade)
    {
        $userId = Auth::id();
        if (!$trade->canBePaidBy($userId))
            return back()->with('error', 'You cannot mark this trade as paid.');

        $trade->update(['status' => 'paid', 'paid_at' => now()]);

        TradeMessage::create([
            'trade_id'  => $trade->id,
            'user_id'   => $userId,
            'message'   => 'Buyer marked payment as sent.',
            'is_system' => true,
        ]);

        return back()->with('success', 'Payment marked. Waiting for seller to release funds.');
    }

    /** Seller releases crypto to buyer */
    public function release(Trade $trade)
    {
        $userId = Auth::id();
        if (!$trade->canBeReleasedBy($userId))
            return back()->with('error', 'You cannot release funds for this trade.');

        $trade->update([
            'status'       => 'completed',
            'released_at'  => now(),
            'completed_at' => now(),
        ]);

        // Update buyer's completed trades count and offer trade count
        $trade->buyer->increment('completed_trades');
        $trade->seller->increment('completed_trades');

        TradeMessage::create([
            'trade_id'  => $trade->id,
            'user_id'   => $userId,
            'message'   => 'Seller released funds. Trade completed!',
            'is_system' => true,
        ]);

        return back()->with('success', 'Funds released. Trade completed!');
    }

    /** Cancel a trade (buyer or seller, only when open) */
    public function cancel(Request $request, Trade $trade)
    {
        $userId = Auth::id();
        if (!$trade->canBeCancelledBy($userId))
            return back()->with('error', 'This trade cannot be cancelled.');

        $request->validate(['reason' => 'nullable|string|max:500']);

        $trade->update([
            'status'        => 'cancelled',
            'cancel_reason' => $request->reason,
        ]);

        TradeMessage::create([
            'trade_id'  => $trade->id,
            'user_id'   => $userId,
            'message'   => 'Trade cancelled' . ($request->reason ? ': ' . $request->reason : '.'),
            'is_system' => true,
        ]);

        return redirect()->route('trades.index')
            ->with('success', 'Trade cancelled.');
    }

    /** Open a dispute */
    public function dispute(Request $request, Trade $trade)
    {
        $userId = Auth::id();
        if (!$trade->canBeDisputedBy($userId))
            return back()->with('error', 'This trade cannot be disputed.');

        $request->validate(['reason' => 'required|string|max:1000']);

        $trade->update(['status' => 'disputed', 'dispute_reason' => $request->reason]);

        Dispute::create([
            'trade_id'  => $trade->id,
            'opened_by' => $userId,
            'reason'    => $request->reason,
            'status'    => 'open',
        ]);

        TradeMessage::create([
            'trade_id'  => $trade->id,
            'user_id'   => $userId,
            'message'   => 'Dispute opened: ' . $request->reason,
            'is_system' => true,
        ]);

        return back()->with('success', 'Dispute opened. An admin will review it shortly.');
    }

    /** Post a chat message in a trade */
    public function message(Request $request, Trade $trade)
    {
        $userId = Auth::id();
        if ($trade->buyer_id !== $userId && $trade->seller_id !== $userId) abort(403);

        $request->validate(['message' => 'required|string|max:1000']);

        TradeMessage::create([
            'trade_id' => $trade->id,
            'user_id'  => $userId,
            'message'  => $request->message,
        ]);

        return back();
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/WalletController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Support\Facades\Auth;

class WalletController extends Controller
{
    public function __construct() { $this->middleware('auth'); }

    public function index()
    {
        $user         = Auth::user();
        $transactions = Transaction::where('user_id', $user->id)
            ->latest()->paginate(20);
        return view('wallet.index', compact('user', 'transactions'));
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/DashboardController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Support\Facades\Auth;

class DashboardController extends Controller
{
    public function __construct() { $this->middleware('auth'); }

    public function index()
    {
        $user   = Auth::user();
        $userId = $user->id;

        $activeTrades = Trade::where(function ($q) use ($userId) {
                $q->where('buyer_id', $userId)->orWhere('seller_id', $userId);
            })
            ->whereIn('status', ['open', 'paid', 'disputed'])
            ->with(['offer', 'buyer', 'seller'])
            ->latest()->take(5)->get();

        $myOffers = Offer::where('user_id', $userId)
            ->latest()->take(5)->get();

        $stats = [
            'active_trades'  => Trade::where(function ($q) use ($userId) {
                $q->where('buyer_id', $userId)->orWhere('seller_id', $userId);
            })->whereIn('status', ['open','paid','disputed'])->count(),
            'active_offers'  => Offer::where('user_id', $userId)->where('is_active', true)->count(),
            'btc_balance'    => $user->btc_balance,
            'xmr_balance'    => $user->xmr_balance,
        ];

        return view('dashboard', compact('user', 'stats', 'activeTrades', 'myOffers'));
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/ProfileController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use App\Models\User;

class ProfileController extends Controller
{
    public function show(User $user)
    {
        $offers = Offer::where('user_id', $user->id)
            ->where('is_active', true)->latest()->take(10)->get();

        $completedTrades = Trade::where(function ($q) use ($user) {
                $q->where('buyer_id', $user->id)->orWhere('seller_id', $user->id);
            })->where('status', 'completed')->count();

        return view('profile.show', compact('user', 'offers', 'completedTrades'));
    }
}
""")
    ok("Controllers written")


# ============================================================================
# Laravel App – Middleware (FIXED: TrustProxies extends Illuminate's version)
# ============================================================================
def write_middleware():
    log("Writing middleware")

    wf(f"{APP_ROOT}/app/Http/Middleware/Authenticate.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    protected function redirectTo($request)
    {
        if (!$request->expectsJson()) return route('login');
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/RedirectIfAuthenticated.php", r"""<?php

namespace App\Http\Middleware;

use App\Providers\RouteServiceProvider;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RedirectIfAuthenticated
{
    public function handle(Request $request, Closure $next, ...$guards)
    {
        $guards = empty($guards) ? [null] : $guards;
        foreach ($guards as $guard) {
            if (Auth::guard($guard)->check()) {
                return redirect(RouteServiceProvider::HOME);
            }
        }
        return $next($request);
    }
}
""")

    # FIX: extend Illuminate's TrustProxies, NOT fideloper's (fideloper not in composer)
    wf(f"{APP_ROOT}/app/Http/Middleware/TrustProxies.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    protected $proxies;
    protected $headers =
        Request::HEADER_X_FORWARDED_FOR    |
        Request::HEADER_X_FORWARDED_HOST   |
        Request::HEADER_X_FORWARDED_PORT   |
        Request::HEADER_X_FORWARDED_PROTO  |
        Request::HEADER_X_FORWARDED_AWS_ELB;
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/TrustHosts.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\TrustHosts as Middleware;

class TrustHosts extends Middleware
{
    public function hosts()
    {
        return [
            $this->allSubdomainsOfApplicationUrl(),
        ];
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/VerifyCsrfToken.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    protected $except = [];
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/TrimStrings.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\TrimStrings as Middleware;

class TrimStrings extends Middleware
{
    protected $except = ['current_password', 'password', 'password_confirmation'];
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/PreventRequestsDuringMaintenance.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance as Middleware;

class PreventRequestsDuringMaintenance extends Middleware
{
    protected $except = [];
}
""")

    wf(f"{APP_ROOT}/app/Http/Middleware/EncryptCookies.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Cookie\Middleware\EncryptCookies as Middleware;

class EncryptCookies extends Middleware
{
    protected $except = [];
}
""")
    ok("Middleware written")


def write_kernel():
    log("Writing HTTP Kernel")
    wf(f"{APP_ROOT}/app/Http/Kernel.php", r"""<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected $middleware = [
        \App\Http\Middleware\TrustHosts::class,
        \App\Http\Middleware\TrustProxies::class,
        \Fruitcake\Cors\HandleCors::class,
        \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
        \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
        \App\Http\Middleware\TrimStrings::class,
        \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
    ];

    protected $middlewareGroups = [
        'web' => [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\Session\Middleware\AuthenticateSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
        'api' => [
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    protected $routeMiddleware = [
        'auth'             => \App\Http\Middleware\Authenticate::class,
        'auth.basic'       => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'cache.headers'    => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can'              => \Illuminate\Auth\Middleware\Authorize::class,
        'guest'            => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed'           => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle'         => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified'         => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
    ];
}
""")
    ok("Kernel written")


# ============================================================================
# Laravel App – Providers (FIXED: Paginator::useBootstrap)
# ============================================================================
def write_providers():
    log("Writing service providers")

    # FIX: Add Paginator::useBootstrap() so pagination links render correctly
    wf(f"{APP_ROOT}/app/Providers/AppServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Pagination\Paginator;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register() {}

    public function boot()
    {
        // Bootstrap 4 pagination (prevents raw HTML / missing view errors)
        Paginator::useBootstrap();

        // Force HTTPS in production
        if (config('app.env') === 'production') {
            URL::forceScheme('https');
        }
    }
}
""")

    wf(f"{APP_ROOT}/app/Providers/AuthServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [];
    public function boot() { $this->registerPolicies(); }
}
""")

    wf(f"{APP_ROOT}/app/Providers/RouteServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Support\Providers\RouteServiceProvider as ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;

class RouteServiceProvider extends ServiceProvider
{
    public const HOME = '/dashboard';

    public function boot()
    {
        $this->configureRateLimiting();
        $this->routes(function () {
            Route::prefix('api')
                ->middleware('api')
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->group(base_path('routes/web.php'));
        });
    }

    protected function configureRateLimiting()
    {
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(60)->by(optional($request->user())->id ?: $request->ip());
        });
    }
}
""")

    wf(f"{APP_ROOT}/app/Providers/EventServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Auth\Events\Registered;
use Illuminate\Auth\Listeners\SendEmailVerificationNotification;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        Registered::class => [SendEmailVerificationNotification::class],
    ];
    public function boot() {}
}
""")

    wf(f"{APP_ROOT}/app/Providers/BroadcastServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\ServiceProvider;

class BroadcastServiceProvider extends ServiceProvider
{
    public function boot()
    {
        Broadcast::routes();
        require base_path('routes/channels.php');
    }
}
""")
    ok("Providers written")


def write_exceptions():
    log("Writing Exception Handler")
    wf(f"{APP_ROOT}/app/Exceptions/Handler.php", r"""<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontReport  = [];
    protected $dontFlash   = ['current_password','password','password_confirmation'];

    public function register()
    {
        $this->reportable(function (Throwable $e) {});
    }
}
""")
    ok("Exception Handler written")


def write_console():
    log("Writing Console Kernel")
    wf(f"{APP_ROOT}/app/Console/Kernel.php", r"""<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected function schedule(Schedule $schedule) {}

    protected function commands()
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }
}
""")
    ok("Console Kernel written")


# ============================================================================
# Laravel App – Routes (updated with trade actions + profile)
# ============================================================================
def write_routes():
    log("Writing routes")

    wf(f"{APP_ROOT}/routes/web.php", r"""<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\OfferController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TradeController;
use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

// Home
Route::get('/', [HomeController::class, 'index'])->name('home');

// Auth
Route::get('/login',     [AuthController::class, 'showLogin'])->name('login');
Route::post('/login',    [AuthController::class, 'login']);
Route::get('/register',  [AuthController::class, 'showRegister'])->name('register');
Route::post('/register', [AuthController::class, 'register']);
Route::post('/logout',   [AuthController::class, 'logout'])->name('logout');

// Offers
Route::get('/offers',         [OfferController::class, 'index'])->name('offers.index');
Route::get('/offers/create',  [OfferController::class, 'create'])->name('offers.create');
Route::post('/offers',        [OfferController::class, 'store'])->name('offers.store');
Route::get('/offers/{offer}', [OfferController::class, 'show'])->name('offers.show');
Route::post('/offers/{offer}/toggle',  [OfferController::class, 'toggleActive'])->name('offers.toggle');
Route::delete('/offers/{offer}',       [OfferController::class, 'destroy'])->name('offers.destroy');

// Trade start (from offer page)
Route::post('/offers/{offer}/trade', [TradeController::class, 'start'])->name('trades.start');

// Trades
Route::get('/trades',         [TradeController::class, 'index'])->name('trades.index');
Route::get('/trades/{trade}', [TradeController::class, 'show'])->name('trades.show');

// Trade actions
Route::post('/trades/{trade}/paid',    [TradeController::class, 'markPaid'])->name('trades.paid');
Route::post('/trades/{trade}/release', [TradeController::class, 'release'])->name('trades.release');
Route::post('/trades/{trade}/cancel',  [TradeController::class, 'cancel'])->name('trades.cancel');
Route::post('/trades/{trade}/dispute', [TradeController::class, 'dispute'])->name('trades.dispute');
Route::post('/trades/{trade}/message', [TradeController::class, 'message'])->name('trades.message');

// Wallet
Route::get('/wallet', [WalletController::class, 'index'])->name('wallet.index');

// Dashboard
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

// Profile
Route::get('/user/{user}', [ProfileController::class, 'show'])->name('profile.show');
""")

    wf(f"{APP_ROOT}/routes/api.php", r"""<?php

use App\Models\Offer;
use App\Models\Trade;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->get('/user', fn(Request $request) => $request->user());

Route::get('/health', fn() => response()->json(['status' => 'ok', 'ts' => now()]));

Route::get('/stats', fn() => response()->json([
    'users'            => User::count(),
    'active_offers'    => Offer::where('is_active', true)->count(),
    'completed_trades' => Trade::where('status', 'completed')->count(),
]));
""")

    wf(f"{APP_ROOT}/routes/channels.php", r"""<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
""")

    wf(f"{APP_ROOT}/routes/console.php", r"""<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
""")
    ok("Routes written")


# ============================================================================
# Laravel App – Config files (COMPLETE: all required configs)
# ============================================================================
def write_config():
    log("Writing config files")

    wf(f"{APP_ROOT}/config/app.php", r"""<?php

return [
    'name'             => env('APP_NAME', 'CapitalMonero'),
    'env'              => env('APP_ENV', 'production'),
    'debug'            => (bool) env('APP_DEBUG', false),
    'url'              => env('APP_URL', 'https://capitalmonero.com'),
    'asset_url'        => env('ASSET_URL', null),
    'timezone'         => 'UTC',
    'locale'           => 'en',
    'fallback_locale'  => 'en',
    'faker_locale'     => 'en_US',
    'key'              => env('APP_KEY'),
    'cipher'           => 'AES-256-CBC',

    'providers' => [
        Illuminate\Auth\AuthServiceProvider::class,
        Illuminate\Broadcasting\BroadcastServiceProvider::class,
        Illuminate\Bus\BusServiceProvider::class,
        Illuminate\Cache\CacheServiceProvider::class,
        Illuminate\Foundation\Providers\ConsoleSupportServiceProvider::class,
        Illuminate\Cookie\CookieServiceProvider::class,
        Illuminate\Database\DatabaseServiceProvider::class,
        Illuminate\Encryption\EncryptionServiceProvider::class,
        Illuminate\Filesystem\FilesystemServiceProvider::class,
        Illuminate\Foundation\Providers\FoundationServiceProvider::class,
        Illuminate\Hashing\HashServiceProvider::class,
        Illuminate\Mail\MailServiceProvider::class,
        Illuminate\Notifications\NotificationServiceProvider::class,
        Illuminate\Pagination\PaginationServiceProvider::class,
        Illuminate\Pipeline\PipelineServiceProvider::class,
        Illuminate\Queue\QueueServiceProvider::class,
        Illuminate\Redis\RedisServiceProvider::class,
        Illuminate\Auth\Passwords\PasswordResetServiceProvider::class,
        Illuminate\Session\SessionServiceProvider::class,
        Illuminate\Translation\TranslationServiceProvider::class,
        Illuminate\Validation\ValidationServiceProvider::class,
        Illuminate\View\ViewServiceProvider::class,
        App\Providers\AppServiceProvider::class,
        App\Providers\AuthServiceProvider::class,
        App\Providers\EventServiceProvider::class,
        App\Providers\RouteServiceProvider::class,
    ],

    'aliases' => [
        'App'          => Illuminate\Support\Facades\App::class,
        'Arr'          => Illuminate\Support\Arr::class,
        'Artisan'      => Illuminate\Support\Facades\Artisan::class,
        'Auth'         => Illuminate\Support\Facades\Auth::class,
        'Blade'        => Illuminate\Support\Facades\Blade::class,
        'Broadcast'    => Illuminate\Support\Facades\Broadcast::class,
        'Bus'          => Illuminate\Support\Facades\Bus::class,
        'Cache'        => Illuminate\Support\Facades\Cache::class,
        'Config'       => Illuminate\Support\Facades\Config::class,
        'Cookie'       => Illuminate\Support\Facades\Cookie::class,
        'Crypt'        => Illuminate\Support\Facades\Crypt::class,
        'DB'           => Illuminate\Support\Facades\DB::class,
        'Eloquent'     => Illuminate\Database\Eloquent\Model::class,
        'Event'        => Illuminate\Support\Facades\Event::class,
        'File'         => Illuminate\Support\Facades\File::class,
        'Gate'         => Illuminate\Support\Facades\Gate::class,
        'Hash'         => Illuminate\Support\Facades\Hash::class,
        'Http'         => Illuminate\Support\Facades\Http::class,
        'Lang'         => Illuminate\Support\Facades\Lang::class,
        'Log'          => Illuminate\Support\Facades\Log::class,
        'Mail'         => Illuminate\Support\Facades\Mail::class,
        'Notification' => Illuminate\Support\Facades\Notification::class,
        'Password'     => Illuminate\Support\Facades\Password::class,
        'Queue'        => Illuminate\Support\Facades\Queue::class,
        'RateLimiter'  => Illuminate\Support\Facades\RateLimiter::class,
        'Redirect'     => Illuminate\Support\Facades\Redirect::class,
        'Request'      => Illuminate\Support\Facades\Request::class,
        'Response'     => Illuminate\Support\Facades\Response::class,
        'Route'        => Illuminate\Support\Facades\Route::class,
        'Schema'       => Illuminate\Support\Facades\Schema::class,
        'Session'      => Illuminate\Support\Facades\Session::class,
        'Storage'      => Illuminate\Support\Facades\Storage::class,
        'Str'          => Illuminate\Support\Str::class,
        'URL'          => Illuminate\Support\Facades\URL::class,
        'Validator'    => Illuminate\Support\Facades\Validator::class,
        'View'         => Illuminate\Support\Facades\View::class,
    ],
];
""")

    wf(f"{APP_ROOT}/config/database.php", r"""<?php

return [
    'default'    => env('DB_CONNECTION', 'mysql'),
    'connections'=> [
        'mysql' => [
            'driver'         => 'mysql',
            'url'            => env('DATABASE_URL'),
            'host'           => env('DB_HOST', '127.0.0.1'),
            'port'           => env('DB_PORT', '3306'),
            'database'       => env('DB_DATABASE', 'capitalmonero'),
            'username'       => env('DB_USERNAME', 'capitalmonero'),
            'password'       => env('DB_PASSWORD', ''),
            'unix_socket'    => env('DB_SOCKET', ''),
            'charset'        => 'utf8mb4',
            'collation'      => 'utf8mb4_unicode_ci',
            'prefix'         => '',
            'prefix_indexes' => true,
            'strict'         => true,
            'engine'         => null,
        ],
    ],
    'migrations' => 'migrations',
    'redis' => [
        'client' => env('REDIS_CLIENT', 'predis'),
        'options'=> ['cluster' => 'redis', 'prefix' => env('REDIS_PREFIX', 'cm_')],
        'default'=> [
            'url'      => env('REDIS_URL'),
            'host'     => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port'     => env('REDIS_PORT', '6379'),
            'database' => env('REDIS_DB', '0'),
        ],
        'cache' => [
            'url'      => env('REDIS_URL'),
            'host'     => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port'     => env('REDIS_PORT', '6379'),
            'database' => env('REDIS_CACHE_DB', '1'),
        ],
    ],
];
""")

    wf(f"{APP_ROOT}/config/session.php", r"""<?php

return [
    'driver'          => env('SESSION_DRIVER', 'file'),
    'lifetime'        => env('SESSION_LIFETIME', 120),
    'expire_on_close' => false,
    'encrypt'         => false,
    'files'           => storage_path('framework/sessions'),
    'connection'      => env('SESSION_CONNECTION', null),
    'table'           => 'sessions',
    'store'           => env('SESSION_STORE', null),
    'lottery'         => [2, 100],
    'cookie'          => env('SESSION_COOKIE', 'capitalmonero_session'),
    'path'            => '/',
    'domain'          => env('SESSION_DOMAIN', null),
    'secure'          => env('SESSION_SECURE_COOKIE', false),
    'http_only'       => true,
    'same_site'       => 'lax',
];
""")

    wf(f"{APP_ROOT}/config/cache.php", r"""<?php

return [
    'default' => env('CACHE_DRIVER', 'file'),
    'stores'  => [
        'file'  => ['driver' => 'file',  'path' => storage_path('framework/cache/data')],
        'redis' => ['driver' => 'redis', 'connection' => 'cache'],
        'array' => ['driver' => 'array', 'serialize' => false],
        'null'  => ['driver' => 'null'],
    ],
    'prefix'  => env('CACHE_PREFIX', 'cm_cache'),
];
""")

    wf(f"{APP_ROOT}/config/auth.php", r"""<?php

return [
    'defaults'  => ['guard' => 'web', 'passwords' => 'users'],
    'guards'    => [
        'web' => ['driver' => 'session', 'provider' => 'users'],
        'api' => ['driver' => 'token',   'provider' => 'users', 'hash' => false],
    ],
    'providers' => ['users' => ['driver' => 'eloquent', 'model' => App\Models\User::class]],
    'passwords' => [
        'users' => ['provider' => 'users', 'table' => 'password_resets', 'expire' => 60, 'throttle' => 60],
    ],
    'password_timeout' => 10800,
];
""")

    wf(f"{APP_ROOT}/config/view.php", r"""<?php

return [
    'paths'    => [resource_path('views')],
    'compiled' => env('VIEW_COMPILED_PATH', realpath(storage_path('framework/views'))),
];
""")

    wf(f"{APP_ROOT}/config/logging.php", r"""<?php

return [
    'default'      => env('LOG_CHANNEL', 'stack'),
    'deprecations' => env('LOG_DEPRECATIONS_CHANNEL', 'null'),
    'channels'     => [
        'stack'  => ['driver' => 'stack', 'channels' => ['single'], 'ignore_exceptions' => false],
        'single' => ['driver' => 'single', 'path' => storage_path('logs/laravel.log'), 'level' => env('LOG_LEVEL', 'debug')],
        'stderr' => ['driver' => 'monolog', 'level' => 'debug', 'handler' => Monolog\Handler\StreamHandler::class, 'with' => ['stream' => 'php://stderr']],
        'null'   => ['driver' => 'monolog', 'handler' => Monolog\Handler\NullHandler::class],
    ],
];
""")

    wf(f"{APP_ROOT}/config/cors.php", r"""<?php

return [
    'paths'                    => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods'          => ['*'],
    'allowed_origins'          => ['*'],
    'allowed_origins_patterns' => [],
    'allowed_headers'          => ['*'],
    'exposed_headers'          => [],
    'max_age'                  => 0,
    'supports_credentials'     => false,
];
""")

    wf(f"{APP_ROOT}/config/sanctum.php", r"""<?php

return [
    'stateful'   => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,127.0.0.1')),
    'guard'      => ['web'],
    'expiration' => null,
    'middleware' => [
        'verify_csrf_token' => App\Http\Middleware\VerifyCsrfToken::class,
        'encrypt_cookies'   => App\Http\Middleware\EncryptCookies::class,
    ],
];
""")

    # NEW: filesystems config (needed by Storage facade)
    wf(f"{APP_ROOT}/config/filesystems.php", r"""<?php

return [
    'default'  => env('FILESYSTEM_DISK', 'local'),
    'disks'    => [
        'local'   => ['driver' => 'local', 'root' => storage_path('app'), 'throw' => false],
        'public'  => ['driver' => 'local', 'root' => storage_path('app/public'), 'url' => env('APP_URL') . '/storage', 'visibility' => 'public', 'throw' => false],
        's3'      => ['driver' => 's3', 'key' => env('AWS_ACCESS_KEY_ID'), 'secret' => env('AWS_SECRET_ACCESS_KEY'), 'region' => env('AWS_DEFAULT_REGION'), 'bucket' => env('AWS_BUCKET'), 'url' => env('AWS_URL'), 'endpoint' => env('AWS_ENDPOINT'), 'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false), 'throw' => false],
    ],
    'links'    => [public_path('storage') => storage_path('app/public')],
];
""")

    # NEW: queue config (needed by Queue facade)
    wf(f"{APP_ROOT}/config/queue.php", r"""<?php

return [
    'default'     => env('QUEUE_CONNECTION', 'sync'),
    'connections' => [
        'sync'     => ['driver' => 'sync'],
        'database' => ['driver' => 'database', 'table' => 'jobs', 'queue' => 'default', 'retry_after' => 90, 'after_commit' => false],
        'redis'    => ['driver' => 'redis', 'connection' => 'default', 'queue' => env('REDIS_QUEUE', 'default'), 'retry_after' => 90, 'block_for' => null, 'after_commit' => false],
    ],
    'failed'      => ['driver' => env('QUEUE_FAILED_DRIVER', 'database-uuids'), 'database' => env('DB_CONNECTION', 'mysql'), 'table' => 'failed_jobs'],
];
""")

    # NEW: mail config (needed by Mail facade)
    wf(f"{APP_ROOT}/config/mail.php", r"""<?php

return [
    'default'   => env('MAIL_MAILER', 'smtp'),
    'mailers'   => [
        'smtp' => ['transport' => 'smtp', 'host' => env('MAIL_HOST', 'localhost'), 'port' => env('MAIL_PORT', 25), 'encryption' => env('MAIL_ENCRYPTION', null), 'username' => env('MAIL_USERNAME'), 'password' => env('MAIL_PASSWORD'), 'timeout' => null, 'auth_mode' => null],
        'log'  => ['transport' => 'log', 'channel' => env('MAIL_LOG_CHANNEL')],
    ],
    'from'      => ['address' => env('MAIL_FROM_ADDRESS', 'noreply@capitalmonero.com'), 'name' => env('MAIL_FROM_NAME', 'CapitalMonero')],
    'markdown'  => ['theme' => 'default', 'paths' => [resource_path('views/vendor/mail')]],
];
""")

    # NEW: broadcasting config
    wf(f"{APP_ROOT}/config/broadcasting.php", r"""<?php

return [
    'default'     => env('BROADCAST_DRIVER', 'null'),
    'connections' => [
        'pusher' => ['driver' => 'pusher', 'key' => env('PUSHER_APP_KEY'), 'secret' => env('PUSHER_APP_SECRET'), 'app_id' => env('PUSHER_APP_ID'), 'options' => ['cluster' => env('PUSHER_APP_CLUSTER'), 'useTLS' => true]],
        'redis'  => ['driver' => 'redis', 'connection' => 'default'],
        'log'    => ['driver' => 'log'],
        'null'   => ['driver' => 'null'],
    ],
];
""")

    # NEW: hashing config
    wf(f"{APP_ROOT}/config/hashing.php", r"""<?php

return [
    'driver'  => 'bcrypt',
    'bcrypt'  => ['rounds' => env('BCRYPT_ROUNDS', 10)],
    'argon'   => ['memory' => 65536, 'threads' => 1, 'time' => 4],
    'argon2id'=> ['memory' => 65536, 'threads' => 1, 'time' => 4],
];
""")
    ok("Config files written")


# ============================================================================
# Laravel App – Bootstrap, Public, Storage dirs
# ============================================================================
def write_bootstrap():
    log("Writing bootstrap/app.php")
    wf(f"{APP_ROOT}/bootstrap/app.php", r"""<?php

$app = new Illuminate\Foundation\Application(
    $_ENV['APP_BASE_PATH'] ?? dirname(__DIR__)
);

$app->singleton(
    Illuminate\Contracts\Http\Kernel::class,
    App\Http\Kernel::class
);
$app->singleton(
    Illuminate\Contracts\Console\Kernel::class,
    App\Console\Kernel::class
);
$app->singleton(
    Illuminate\Contracts\Debug\ExceptionHandler::class,
    App\Exceptions\Handler::class
);

return $app;
""")
    wf(f"{APP_ROOT}/bootstrap/cache/.gitignore", "*\n!.gitignore\n")
    ok("Bootstrap written")


def write_public():
    log("Writing public/ files")

    wf(f"{APP_ROOT}/public/index.php", r"""<?php

define('LARAVEL_START', microtime(true));

require __DIR__ . '/../vendor/autoload.php';

$app = require_once __DIR__ . '/../bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
);

$response->send();

$kernel->terminate($request, $response);
""")

    wf(f"{APP_ROOT}/public/.htaccess", """\
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>
    RewriteEngine On
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
""")

    wf(f"{APP_ROOT}/public/robots.txt", "User-agent: *\nDisallow: /admin\nDisallow: /api\n")
    ok("Public files written")


def make_storage_dirs():
    log("Creating storage structure")
    dirs = [
        f"{APP_ROOT}/storage/app/public",
        f"{APP_ROOT}/storage/framework/cache/data",
        f"{APP_ROOT}/storage/framework/sessions",
        f"{APP_ROOT}/storage/framework/views",
        f"{APP_ROOT}/storage/logs",
        f"{APP_ROOT}/bootstrap/cache",
        f"{APP_ROOT}/database/factories",
    ]
    for d in dirs:
        mkdirs(d)
        gi = Path(d) / ".gitignore"
        if not gi.exists():
            wf(str(gi), "*\n!.gitignore\n")
    ok("Storage dirs created")


# ============================================================================
# Laravel App – Lang files (REQUIRED to prevent validation 500s)
# ============================================================================
def write_lang():
    log("Writing resources/lang/en/ files")

    wf(f"{APP_ROOT}/resources/lang/en/auth.php", r"""<?php

return [
    'failed'   => 'These credentials do not match our records.',
    'password' => 'The provided password is incorrect.',
    'throttle' => 'Too many login attempts. Please try again in :seconds seconds.',
];
""")

    wf(f"{APP_ROOT}/resources/lang/en/pagination.php", r"""<?php

return [
    'previous' => '&laquo; Previous',
    'next'     => 'Next &raquo;',
];
""")

    wf(f"{APP_ROOT}/resources/lang/en/passwords.php", r"""<?php

return [
    'reset'     => 'Your password has been reset.',
    'sent'      => 'We have emailed your password reset link.',
    'throttled' => 'Please wait before retrying.',
    'token'     => 'This password reset token is invalid.',
    'user'      => 'We can\'t find a user with that email address.',
];
""")

    wf(f"{APP_ROOT}/resources/lang/en/validation.php", r"""<?php

return [
    'accepted'             => 'The :attribute must be accepted.',
    'active_url'           => 'The :attribute is not a valid URL.',
    'after'                => 'The :attribute must be a date after :date.',
    'after_or_equal'       => 'The :attribute must be a date after or equal to :date.',
    'alpha'                => 'The :attribute must only contain letters.',
    'alpha_dash'           => 'The :attribute must only contain letters, numbers, dashes and underscores.',
    'alpha_num'            => 'The :attribute must only contain letters and numbers.',
    'array'                => 'The :attribute must be an array.',
    'before'               => 'The :attribute must be a date before :date.',
    'before_or_equal'      => 'The :attribute must be a date before or equal to :date.',
    'between'              => [
        'numeric' => 'The :attribute must be between :min and :max.',
        'file'    => 'The :attribute must be between :min and :max kilobytes.',
        'string'  => 'The :attribute must be between :min and :max characters.',
        'array'   => 'The :attribute must have between :min and :max items.',
    ],
    'boolean'              => 'The :attribute field must be true or false.',
    'confirmed'            => 'The :attribute confirmation does not match.',
    'date'                 => 'The :attribute is not a valid date.',
    'date_equals'          => 'The :attribute must be a date equal to :date.',
    'date_format'          => 'The :attribute does not match the format :format.',
    'different'            => 'The :attribute and :other must be different.',
    'digits'               => 'The :attribute must be :digits digits.',
    'digits_between'       => 'The :attribute must be between :min and :max digits.',
    'dimensions'           => 'The :attribute has invalid image dimensions.',
    'distinct'             => 'The :attribute field has a duplicate value.',
    'email'                => 'The :attribute must be a valid email address.',
    'ends_with'            => 'The :attribute must end with one of the following: :values.',
    'exists'               => 'The selected :attribute is invalid.',
    'file'                 => 'The :attribute must be a file.',
    'filled'               => 'The :attribute field must have a value.',
    'gt'                   => [
        'numeric' => 'The :attribute must be greater than :value.',
        'file'    => 'The :attribute must be greater than :value kilobytes.',
        'string'  => 'The :attribute must be greater than :value characters.',
        'array'   => 'The :attribute must have more than :value items.',
    ],
    'gte'                  => [
        'numeric' => 'The :attribute must be greater than or equal :value.',
        'file'    => 'The :attribute must be greater than or equal :value kilobytes.',
        'string'  => 'The :attribute must be greater than or equal :value characters.',
        'array'   => 'The :attribute must have :value items or more.',
    ],
    'image'                => 'The :attribute must be an image.',
    'in'                   => 'The selected :attribute is invalid.',
    'in_array'             => 'The :attribute field does not exist in :other.',
    'integer'              => 'The :attribute must be an integer.',
    'ip'                   => 'The :attribute must be a valid IP address.',
    'ipv4'                 => 'The :attribute must be a valid IPv4 address.',
    'ipv6'                 => 'The :attribute must be a valid IPv6 address.',
    'json'                 => 'The :attribute must be a valid JSON string.',
    'lt'                   => [
        'numeric' => 'The :attribute must be less than :value.',
        'file'    => 'The :attribute must be less than :value kilobytes.',
        'string'  => 'The :attribute must be less than :value characters.',
        'array'   => 'The :attribute must have less than :value items.',
    ],
    'lte'                  => [
        'numeric' => 'The :attribute must be less than or equal :value.',
        'file'    => 'The :attribute must be less than or equal :value kilobytes.',
        'string'  => 'The :attribute must be less than or equal :value characters.',
        'array'   => 'The :attribute must not have more than :value items.',
    ],
    'max'                  => [
        'numeric' => 'The :attribute must not be greater than :max.',
        'file'    => 'The :attribute must not be greater than :max kilobytes.',
        'string'  => 'The :attribute must not be greater than :max characters.',
        'array'   => 'The :attribute must not have more than :max items.',
    ],
    'mimes'                => 'The :attribute must be a file of type: :values.',
    'mimetypes'            => 'The :attribute must be a file of type: :values.',
    'min'                  => [
        'numeric' => 'The :attribute must be at least :min.',
        'file'    => 'The :attribute must be at least :min kilobytes.',
        'string'  => 'The :attribute must be at least :min characters.',
        'array'   => 'The :attribute must have at least :min items.',
    ],
    'multiple_of'          => 'The :attribute must be a multiple of :value.',
    'not_in'               => 'The selected :attribute is invalid.',
    'not_regex'            => 'The :attribute format is invalid.',
    'numeric'              => 'The :attribute must be a number.',
    'password'             => 'The password is incorrect.',
    'present'              => 'The :attribute field must be present.',
    'regex'                => 'The :attribute format is invalid.',
    'required'             => 'The :attribute field is required.',
    'required_if'          => 'The :attribute field is required when :other is :value.',
    'required_unless'      => 'The :attribute field is required unless :other is in :values.',
    'required_with'        => 'The :attribute field is required when :values is present.',
    'required_with_all'    => 'The :attribute field is required when :values are present.',
    'required_without'     => 'The :attribute field is required when :values is not present.',
    'required_without_all' => 'The :attribute field is required when none of :values are present.',
    'same'                 => 'The :attribute and :other must match.',
    'size'                 => [
        'numeric' => 'The :attribute must be :size.',
        'file'    => 'The :attribute must be :size kilobytes.',
        'string'  => 'The :attribute must be :size characters.',
        'array'   => 'The :attribute must contain :size items.',
    ],
    'starts_with'          => 'The :attribute must start with one of the following: :values.',
    'string'               => 'The :attribute must be a string.',
    'timezone'             => 'The :attribute must be a valid zone.',
    'unique'               => 'The :attribute has already been taken.',
    'uploaded'             => 'The :attribute failed to upload.',
    'url'                  => 'The :attribute must be a valid URL.',
    'uuid'                 => 'The :attribute must be a valid UUID.',
    'custom' => ['attribute-name' => ['rule-name' => 'custom-message']],
    'attributes' => [],
];
""")
    ok("Lang files written")


# ============================================================================
# Laravel App – Blade Views (LocalCoinSwap-inspired UI)
# ============================================================================
def write_views():
    log("Writing Blade views")

    # ------------------------------------------------------------------
    # Layout
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/layouts/app.blade.php", r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="csrf-token" content="{{ csrf_token() }}">
<title>@yield('title', 'CapitalMonero') — P2P Crypto Exchange</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
<style>
:root{--bg:#0d1117;--bg2:#161b22;--bg3:#21262d;--border:#30363d;
      --text:#c9d1d9;--muted:#8b949e;--accent:#f0883e;--accent2:#388bfd;
      --green:#2ea043;--red:#da3633;--yellow:#e3b341;}
*{box-sizing:border-box;}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',Arial,sans-serif;min-height:100vh;display:flex;flex-direction:column;}
a{color:var(--accent2);}a:hover{color:#79c0ff;text-decoration:none;}
.navbar{background:var(--bg2)!important;border-bottom:1px solid var(--border);padding:.75rem 0;}
.navbar-brand{font-weight:800;color:var(--accent)!important;font-size:1.35rem;letter-spacing:-.5px;}
.navbar-brand span{color:var(--text);}
.nav-link{color:var(--muted)!important;padding:.4rem .8rem!important;border-radius:6px;transition:all .15s;}
.nav-link:hover,.nav-link.active{color:var(--text)!important;background:var(--bg3);}
.btn-buy{background:var(--green);border:none;color:#fff;font-weight:600;}
.btn-buy:hover{background:#2c974b;color:#fff;}
.btn-sell{background:var(--red);border:none;color:#fff;font-weight:600;}
.btn-sell:hover{background:#c93b30;color:#fff;}
.btn-accent{background:var(--accent);border:none;color:#0d1117;font-weight:600;}
.btn-accent:hover{background:#d4772d;color:#0d1117;}
.btn-outline-accent{border:1px solid var(--accent);color:var(--accent);background:transparent;}
.btn-outline-accent:hover{background:var(--accent);color:#0d1117;}
.card{background:var(--bg2);border:1px solid var(--border);border-radius:8px;}
.card-header{background:var(--bg3);border-bottom:1px solid var(--border);padding:.75rem 1.25rem;}
.table{color:var(--text);}
.table thead th{border-color:var(--border);color:var(--muted);font-size:.8rem;text-transform:uppercase;letter-spacing:.5px;font-weight:600;}
.table td,.table th{border-color:var(--bg3);padding:.65rem 1rem;vertical-align:middle;}
.table-hover tbody tr:hover{background:rgba(255,255,255,.03);}
.badge-open{background:#1f6feb;color:#fff;}
.badge-paid{background:#2ea043;color:#fff;}
.badge-released{background:var(--yellow);color:#0d1117;}
.badge-completed{background:#2ea043;color:#fff;}
.badge-cancelled{background:var(--muted);color:#0d1117;}
.badge-disputed{background:var(--red);color:#fff;}
.form-control{background:var(--bg3);border:1px solid var(--border);color:var(--text);border-radius:6px;}
.form-control:focus{background:var(--bg3);border-color:var(--accent2);color:var(--text);box-shadow:0 0 0 2px rgba(56,139,253,.25);}
.form-control::placeholder{color:var(--muted);}
select.form-control option{background:var(--bg3);}
.alert-success{background:#0d4429;border:1px solid var(--green);color:#56d364;}
.alert-danger{background:#4c1015;border:1px solid var(--red);color:#ff7b72;}
.alert-warning{background:#3d2d00;border:1px solid var(--yellow);color:var(--yellow);}
.hero{background:linear-gradient(135deg,#161b22 0%,#0d1117 60%);padding:64px 0;border-bottom:1px solid var(--border);}
.stat-box{background:var(--bg2);border:1px solid var(--border);border-radius:8px;padding:1.5rem;text-align:center;}
.stat-num{font-size:2rem;font-weight:700;color:var(--accent);}
.offer-row{transition:background .15s;}
.offer-row:hover{background:var(--bg3)!important;}
.trade-badge{display:inline-block;padding:.25em .6em;border-radius:4px;font-size:.8rem;font-weight:600;}
.progress-bar-custom{height:4px;background:var(--border);border-radius:2px;}
.progress-fill{height:4px;background:var(--accent);border-radius:2px;transition:width .3s;}
footer{background:var(--bg2);border-top:1px solid var(--border);color:var(--muted);padding:1.5rem 0;margin-top:auto;}
.chat-box{max-height:400px;overflow-y:auto;background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:1rem;}
.chat-msg{margin-bottom:.75rem;}
.chat-msg .meta{font-size:.75rem;color:var(--muted);margin-bottom:.2rem;}
.chat-msg .body{background:var(--bg3);border-radius:6px;padding:.5rem .75rem;display:inline-block;max-width:80%;}
.chat-msg.mine .body{background:#1f6feb;color:#fff;}
.chat-msg.system .body{background:var(--bg3);color:var(--muted);font-style:italic;font-size:.85rem;}
.sidebar-card{background:var(--bg2);border:1px solid var(--border);border-radius:8px;padding:1.25rem;margin-bottom:1rem;}
.action-btn{display:block;width:100%;padding:.6rem;text-align:center;border-radius:6px;margin-bottom:.5rem;font-weight:600;cursor:pointer;border:none;}
</style>
@yield('styles')
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-dark">
  <div class="container">
    <a class="navbar-brand" href="{{ route('home') }}">Capital<span>Monero</span></a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#nav">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="nav">
      <ul class="navbar-nav mr-auto">
        <li class="nav-item">
          <a class="nav-link" href="{{ route('offers.index',['type'=>'buy','crypto'=>'BTC']) }}">
            <i class="fab fa-bitcoin"></i> Buy BTC
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="{{ route('offers.index',['type'=>'sell','crypto'=>'BTC']) }}">
            <i class="fab fa-bitcoin"></i> Sell BTC
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="{{ route('offers.index',['type'=>'buy','crypto'=>'XMR']) }}">
            <i class="fas fa-coins"></i> Buy XMR
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="{{ route('offers.index',['type'=>'sell','crypto'=>'XMR']) }}">
            <i class="fas fa-coins"></i> Sell XMR
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="{{ route('offers.index') }}">All Offers</a>
        </li>
      </ul>
      <ul class="navbar-nav ml-auto align-items-center">
        @guest
          <li class="nav-item mr-2">
            <a class="nav-link" href="{{ route('login') }}">Sign In</a>
          </li>
          <li class="nav-item">
            <a class="btn btn-accent btn-sm px-3" href="{{ route('register') }}">Get Started</a>
          </li>
        @else
          <li class="nav-item">
            <a class="nav-link" href="{{ route('trades.index') }}">
              <i class="fas fa-exchange-alt"></i> Trades
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="{{ route('wallet.index') }}">
              <i class="fas fa-wallet"></i> Wallet
            </a>
          </li>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" id="userDrop" data-toggle="dropdown">
              <img src="{{ Auth::user()->avatar }}" class="rounded-circle mr-1" width="24" height="24" alt="">
              {{ Auth::user()->username }}
            </a>
            <div class="dropdown-menu dropdown-menu-right" style="background:var(--bg2);border-color:var(--border);">
              <a class="dropdown-item" style="color:var(--text)" href="{{ route('dashboard') }}">
                <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
              </a>
              <a class="dropdown-item" style="color:var(--text)" href="{{ route('offers.create') }}">
                <i class="fas fa-plus mr-2"></i>Post Offer
              </a>
              <a class="dropdown-item" style="color:var(--text)" href="{{ route('profile.show', Auth::user()) }}">
                <i class="fas fa-user mr-2"></i>My Profile
              </a>
              <div class="dropdown-divider" style="border-color:var(--border)"></div>
              <form method="POST" action="{{ route('logout') }}">
                @csrf
                <button type="submit" class="dropdown-item" style="color:#ff7b72;background:none;border:none;width:100%;text-align:left;cursor:pointer;">
                  <i class="fas fa-sign-out-alt mr-2"></i>Sign Out
                </button>
              </form>
            </div>
          </li>
        @endguest
      </ul>
    </div>
  </div>
</nav>

<main class="flex-grow-1">
  <div class="container mt-3">
    @foreach(['success','error','warning'] as $type)
      @if(session($type))
        <div class="alert alert-{{ $type === 'error' ? 'danger' : $type }} alert-dismissible fade show" role="alert">
          {{ session($type) }}
          <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
        </div>
      @endif
    @endforeach
    @if($errors->any())
      <div class="alert alert-danger">
        <ul class="mb-0 pl-3">
          @foreach($errors->all() as $e) <li>{{ $e }}</li> @endforeach
        </ul>
      </div>
    @endif
  </div>
  @yield('content')
</main>

<footer>
  <div class="container">
    <div class="row">
      <div class="col-md-4">
        <strong style="color:var(--accent)">CapitalMonero</strong>
        <p class="mt-1 mb-0" style="font-size:.85rem">P2P Bitcoin &amp; Monero Exchange. No KYC. Privacy-first.</p>
      </div>
      <div class="col-md-4 text-center">
        <a href="{{ route('offers.index',['type'=>'buy','crypto'=>'BTC']) }}" class="text-muted mr-3">Buy BTC</a>
        <a href="{{ route('offers.index',['type'=>'sell','crypto'=>'BTC']) }}" class="text-muted mr-3">Sell BTC</a>
        <a href="{{ route('offers.index',['type'=>'buy','crypto'=>'XMR']) }}" class="text-muted mr-3">Buy XMR</a>
        <a href="{{ route('offers.index',['type'=>'sell','crypto'=>'XMR']) }}" class="text-muted">Sell XMR</a>
      </div>
      <div class="col-md-4 text-right">
        <small>
          Clearnet: <a href="https://capitalmonero.com" class="text-muted">capitalmonero.com</a><br>
          Onion: <span style="font-size:.7rem;color:var(--muted)">fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion</span>
        </small>
      </div>
    </div>
    <hr style="border-color:var(--border);margin:.75rem 0">
    <p class="text-center mb-0" style="font-size:.8rem">&copy; {{ date('Y') }} CapitalMonero Exchange</p>
  </div>
</footer>

<script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js"></script>
@yield('scripts')
</body>
</html>
""")

    # ------------------------------------------------------------------
    # Home
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/home.blade.php", r"""@extends('layouts.app')
@section('title','Home')
@section('content')
<div class="hero">
  <div class="container text-center">
    <h1 class="display-4 font-weight-bold text-white mb-2">
      Buy &amp; Sell <span style="color:var(--accent)">Bitcoin</span> and
      <span style="color:var(--accent)">Monero</span> P2P
    </h1>
    <p class="lead" style="color:var(--muted);max-width:600px;margin:0 auto 2rem">
      Trade directly with other people. No KYC. Escrow-protected. Privacy-first.
    </p>
    <div class="d-flex justify-content-center flex-wrap gap-2">
      <a href="{{ route('offers.index',['type'=>'buy','crypto'=>'BTC']) }}" class="btn btn-buy btn-lg mr-2 mb-2">
        <i class="fab fa-bitcoin mr-1"></i> Buy Bitcoin
      </a>
      <a href="{{ route('offers.index',['type'=>'sell','crypto'=>'BTC']) }}" class="btn btn-sell btn-lg mr-2 mb-2">
        <i class="fab fa-bitcoin mr-1"></i> Sell Bitcoin
      </a>
      <a href="{{ route('offers.index',['type'=>'buy','crypto'=>'XMR']) }}" class="btn btn-buy btn-lg mr-2 mb-2">
        <i class="fas fa-coins mr-1"></i> Buy Monero
      </a>
      <a href="{{ route('offers.index',['type'=>'sell','crypto'=>'XMR']) }}" class="btn btn-sell btn-lg mb-2">
        <i class="fas fa-coins mr-1"></i> Sell Monero
      </a>
    </div>
  </div>
</div>

<div class="container mt-4">
  <div class="row mb-4">
    <div class="col-md-4 mb-3">
      <div class="stat-box">
        <div class="stat-num">{{ number_format($stats['total_users']) }}</div>
        <div style="color:var(--muted)">Registered Traders</div>
      </div>
    </div>
    <div class="col-md-4 mb-3">
      <div class="stat-box">
        <div class="stat-num">{{ number_format($stats['active_offers']) }}</div>
        <div style="color:var(--muted)">Active Offers</div>
      </div>
    </div>
    <div class="col-md-4 mb-3">
      <div class="stat-box">
        <div class="stat-num">{{ number_format($stats['completed_trades']) }}</div>
        <div style="color:var(--muted)">Completed Trades</div>
      </div>
    </div>
  </div>

  <div class="row">
    <div class="col-lg-6 mb-4">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h6 class="mb-0"><span class="text-success">▲</span> Buy Offers (traders want to buy)</h6>
          <a href="{{ route('offers.index',['type'=>'buy']) }}" class="btn btn-sm btn-outline-accent">See all</a>
        </div>
        <div class="card-body p-0">
          <table class="table table-hover mb-0">
            <thead><tr>
              <th>Trader</th><th>Crypto</th><th>Payment</th><th>Margin</th><th></th>
            </tr></thead>
            <tbody>
            @forelse($buyOffers as $o)
              <tr class="offer-row">
                <td>
                  <a href="{{ route('profile.show',$o->user) }}" class="font-weight-bold">{{ $o->user->username }}</a>
                  <br><small style="color:var(--muted)">{{ $o->user->completed_trades }} trades</small>
                </td>
                <td><span class="badge badge-secondary">{{ $o->crypto }}</span></td>
                <td><small>{{ Str::limit($o->payment_method,22) }}</small></td>
                <td>
                  @if($o->price_margin>=0)
                    <span class="text-success font-weight-bold">+{{ $o->price_margin }}%</span>
                  @else
                    <span class="text-danger font-weight-bold">{{ $o->price_margin }}%</span>
                  @endif
                </td>
                <td>
                  <a href="{{ route('offers.show',$o) }}" class="btn btn-buy btn-sm">Sell</a>
                </td>
              </tr>
            @empty
              <tr><td colspan="5" class="text-center py-3" style="color:var(--muted)">No buy offers yet</td></tr>
            @endforelse
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="col-lg-6 mb-4">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h6 class="mb-0"><span class="text-danger">▼</span> Sell Offers (traders want to sell)</h6>
          <a href="{{ route('offers.index',['type'=>'sell']) }}" class="btn btn-sm btn-outline-accent">See all</a>
        </div>
        <div class="card-body p-0">
          <table class="table table-hover mb-0">
            <thead><tr>
              <th>Trader</th><th>Crypto</th><th>Payment</th><th>Margin</th><th></th>
            </tr></thead>
            <tbody>
            @forelse($sellOffers as $o)
              <tr class="offer-row">
                <td>
                  <a href="{{ route('profile.show',$o->user) }}" class="font-weight-bold">{{ $o->user->username }}</a>
                  <br><small style="color:var(--muted)">{{ $o->user->completed_trades }} trades</small>
                </td>
                <td><span class="badge badge-secondary">{{ $o->crypto }}</span></td>
                <td><small>{{ Str::limit($o->payment_method,22) }}</small></td>
                <td>
                  @if($o->price_margin>=0)
                    <span class="text-success font-weight-bold">+{{ $o->price_margin }}%</span>
                  @else
                    <span class="text-danger font-weight-bold">{{ $o->price_margin }}%</span>
                  @endif
                </td>
                <td>
                  <a href="{{ route('offers.show',$o) }}" class="btn btn-sell btn-sm">Buy</a>
                </td>
              </tr>
            @empty
              <tr><td colspan="5" class="text-center py-3" style="color:var(--muted)">No sell offers yet</td></tr>
            @endforelse
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  @guest
  <div class="card mt-2 mb-4" style="border-color:var(--accent)">
    <div class="card-body text-center py-4">
      <h4>Start trading privately today</h4>
      <p style="color:var(--muted)">Create a free account in 30 seconds. No email verification required to browse.</p>
      <a href="{{ route('register') }}" class="btn btn-accent btn-lg mr-3">Create Account</a>
      <a href="{{ route('login') }}"    class="btn btn-outline-accent btn-lg">Sign In</a>
    </div>
  </div>
  @endguest
</div>
@endsection
""")


    # ------------------------------------------------------------------
    # Auth views
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/auth/login.blade.php", r"""@extends('layouts.app')
@section('title','Sign In')
@section('content')
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-5 col-lg-4">
      <div class="card">
        <div class="card-header text-center">
          <h5 class="mb-0"><i class="fas fa-lock" style="color:var(--accent)"></i> Sign In</h5>
        </div>
        <div class="card-body">
          <form method="POST" action="{{ route('login') }}">
            @csrf
            <div class="form-group">
              <label>Username</label>
              <input type="text" name="username" class="form-control @error('username') is-invalid @enderror"
                     value="{{ old('username') }}" required autofocus>
              @error('username')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-group">
              <label>Password</label>
              <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required>
              @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-group form-check">
              <input type="checkbox" class="form-check-input" id="remember" name="remember">
              <label class="form-check-label" for="remember" style="color:var(--muted)">Remember me</label>
            </div>
            <button type="submit" class="btn btn-accent btn-block">Sign In</button>
          </form>
        </div>
        <div class="card-footer text-center" style="color:var(--muted)">
          No account? <a href="{{ route('register') }}">Create one</a>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/auth/register.blade.php", r"""@extends('layouts.app')
@section('title','Create Account')
@section('content')
<div class="container mt-5">
  <div class="row justify-content-center">
    <div class="col-md-5 col-lg-4">
      <div class="card">
        <div class="card-header text-center">
          <h5 class="mb-0"><i class="fas fa-user-plus" style="color:var(--accent)"></i> Create Account</h5>
        </div>
        <div class="card-body">
          <form method="POST" action="{{ route('register') }}">
            @csrf
            <div class="form-group">
              <label>Username <small style="color:var(--muted)">(3-30 chars, letters/numbers/dashes)</small></label>
              <input type="text" name="username" class="form-control @error('username') is-invalid @enderror"
                     value="{{ old('username') }}" required autofocus>
              @error('username')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-group">
              <label>Email</label>
              <input type="email" name="email" class="form-control @error('email') is-invalid @enderror"
                     value="{{ old('email') }}" required>
              @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-group">
              <label>Password <small style="color:var(--muted)">(min 8 chars)</small></label>
              <input type="password" name="password" class="form-control @error('password') is-invalid @enderror" required>
              @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-group">
              <label>Confirm Password</label>
              <input type="password" name="password_confirmation" class="form-control" required>
            </div>
            <button type="submit" class="btn btn-accent btn-block">Create Account</button>
          </form>
        </div>
        <div class="card-footer text-center" style="color:var(--muted)">
          Already have an account? <a href="{{ route('login') }}">Sign in</a>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")

    # ------------------------------------------------------------------
    # Offers
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/offers/index.blade.php", r"""@extends('layouts.app')
@section('title','Offers')
@section('content')
<div class="container mt-4">
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0">Browse Offers</h4>
    @auth
      <a href="{{ route('offers.create') }}" class="btn btn-accent btn-sm">
        <i class="fas fa-plus mr-1"></i> Post Offer
      </a>
    @endauth
  </div>

  <form method="GET" class="card card-body mb-4 py-3">
    <div class="form-row">
      <div class="col-6 col-md-2 mb-2">
        <select name="type" class="form-control form-control-sm">
          <option value="">All Types</option>
          <option value="buy"  @selected(request('type')=='buy')>Buy</option>
          <option value="sell" @selected(request('type')=='sell')>Sell</option>
        </select>
      </div>
      <div class="col-6 col-md-2 mb-2">
        <select name="crypto" class="form-control form-control-sm">
          <option value="">All Crypto</option>
          <option value="BTC" @selected(request('crypto')=='BTC')>Bitcoin (BTC)</option>
          <option value="XMR" @selected(request('crypto')=='XMR')>Monero (XMR)</option>
        </select>
      </div>
      <div class="col-6 col-md-2 mb-2">
        <select name="currency" class="form-control form-control-sm">
          <option value="">Any Currency</option>
          @foreach(['USD','EUR','GBP','CAD','AUD','JPY'] as $c)
            <option value="{{ $c }}" @selected(request('currency')==$c)>{{ $c }}</option>
          @endforeach
        </select>
      </div>
      <div class="col-6 col-md-4 mb-2">
        <input type="text" name="payment_method" class="form-control form-control-sm"
               placeholder="Payment method..." value="{{ request('payment_method') }}">
      </div>
      <div class="col-12 col-md-2 mb-2">
        <button type="submit" class="btn btn-accent btn-sm btn-block">Filter</button>
      </div>
    </div>
  </form>

  @forelse($offers as $o)
  <div class="card mb-2 offer-row">
    <div class="card-body py-2 px-3">
      <div class="row align-items-center">
        <div class="col-2 col-md-1">
          <span class="badge {{ $o->type=='buy' ? 'badge-success' : 'badge-danger' }} d-block text-center p-2">
            {{ strtoupper($o->type) }}
          </span>
        </div>
        <div class="col-5 col-md-2">
          <a href="{{ route('profile.show',$o->user) }}" class="font-weight-bold d-block">{{ $o->user->username }}</a>
          <small style="color:var(--muted)">{{ $o->user->completed_trades }} trades</small>
        </div>
        <div class="col-5 col-md-2">
          <span class="badge badge-secondary">{{ $o->crypto }}</span><br>
          <small style="color:var(--muted)">{{ $o->fiat_currency }}</small>
        </div>
        <div class="col-6 col-md-3 mt-2 mt-md-0">
          <i class="fas fa-credit-card mr-1" style="color:var(--muted)"></i>
          <small>{{ $o->payment_method }}</small>
        </div>
        <div class="col-3 col-md-2 text-right mt-2 mt-md-0">
          @if($o->price_margin>=0)
            <strong class="text-success">+{{ $o->price_margin }}%</strong>
          @else
            <strong class="text-danger">{{ $o->price_margin }}%</strong>
          @endif
          <br>
          <small style="color:var(--muted)">{{ $o->min_amount }}-{{ $o->max_amount }}</small>
        </div>
        <div class="col-3 col-md-2 text-right mt-2 mt-md-0">
          <a href="{{ route('offers.show',$o) }}"
             class="btn btn-sm {{ $o->type=='buy' ? 'btn-buy' : 'btn-sell' }}">
            {{ $o->type=='buy' ? 'Sell' : 'Buy' }}
          </a>
        </div>
      </div>
    </div>
  </div>
  @empty
  <div class="text-center py-5">
    <i class="fas fa-search fa-3x mb-3" style="color:var(--muted)"></i>
    <p style="color:var(--muted)">No offers found. <a href="{{ route('offers.create') }}">Post the first one!</a></p>
  </div>
  @endforelse

  <div class="d-flex justify-content-center mt-4">{{ $offers->links() }}</div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/offers/show.blade.php", r"""@extends('layouts.app')
@section('title','Offer')
@section('content')
<div class="container mt-4">
  <div class="row">
    <div class="col-lg-8">
      <div class="card mb-4">
        <div class="card-header">
          <div class="d-flex align-items-center">
            <img src="{{ $offer->user->avatar }}" class="rounded-circle mr-2" width="36" height="36" alt="">
            <div>
              <a href="{{ route('profile.show',$offer->user) }}" class="font-weight-bold d-block">
                {{ $offer->user->username }}
              </a>
              <small style="color:var(--muted)">{{ $offer->user->completed_trades }} trades</small>
            </div>
            <div class="ml-auto">
              <span class="badge badge-lg {{ $offer->type=='buy'?'badge-success':'badge-danger' }} p-2">
                {{ strtoupper($offer->type) }} {{ $offer->crypto }}
              </span>
            </div>
          </div>
        </div>
        <div class="card-body">
          <div class="row">
            <div class="col-sm-6">
              <table class="table table-borderless table-sm mb-0">
                <tr>
                  <td style="color:var(--muted)">Payment Method</td>
                  <td class="font-weight-bold">{{ $offer->payment_method }}</td>
                </tr>
                <tr>
                  <td style="color:var(--muted)">Currency</td>
                  <td>{{ $offer->fiat_currency }}</td>
                </tr>
                <tr>
                  <td style="color:var(--muted)">Price Margin</td>
                  <td>
                    @if($offer->price_margin>=0)
                      <span class="text-success">+{{ $offer->price_margin }}% market</span>
                    @else
                      <span class="text-danger">{{ $offer->price_margin }}% market</span>
                    @endif
                  </td>
                </tr>
                <tr>
                  <td style="color:var(--muted)">Trade Limits</td>
                  <td>{{ $offer->min_amount }} – {{ $offer->max_amount }} {{ $offer->fiat_currency }}</td>
                </tr>
                @if($offer->country)
                <tr>
                  <td style="color:var(--muted)">Country</td>
                  <td>{{ $offer->country }}</td>
                </tr>
                @endif
              </table>
            </div>
            <div class="col-sm-6">
              @if($offer->terms)
                <h6 style="color:var(--muted)">Trade Terms</h6>
                <p style="font-size:.9rem;white-space:pre-line">{{ $offer->terms }}</p>
              @endif
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="col-lg-4">
      @auth
        @if(Auth::id() !== $offer->user_id && $offer->is_active)
          <div class="card">
            <div class="card-header"><h6 class="mb-0">Start a Trade</h6></div>
            <div class="card-body">
              <form method="POST" action="{{ route('trades.start',$offer) }}">
                @csrf
                <div class="form-group">
                  <label>Amount in {{ $offer->fiat_currency }}</label>
                  <input type="number" step="0.01" name="fiat_amount"
                         class="form-control" required
                         min="{{ $offer->min_amount }}" max="{{ $offer->max_amount }}"
                         placeholder="{{ $offer->min_amount }} – {{ $offer->max_amount }}">
                  <small style="color:var(--muted)">
                    Limits: {{ $offer->min_amount }} – {{ $offer->max_amount }} {{ $offer->fiat_currency }}
                  </small>
                </div>
                <button type="submit"
                  class="btn btn-block {{ $offer->type=='buy' ? 'btn-buy' : 'btn-sell' }}">
                  {{ $offer->type=='buy' ? 'Sell to this trader' : 'Buy from this trader' }}
                </button>
              </form>
            </div>
          </div>
          @elseif(Auth::id()===$offer->user_id)
          <div class="card">
            <div class="card-header"><h6 class="mb-0">Your Offer</h6></div>
            <div class="card-body">
              <form method="POST" action="{{ route('offers.toggle',$offer) }}">
                @csrf
                <button type="submit" class="btn btn-block btn-outline-accent mb-2">
                  {{ $offer->is_active ? 'Deactivate' : 'Activate' }} Offer
                </button>
              </form>
              <form method="POST" action="{{ route('offers.destroy',$offer) }}"
                    onsubmit="return confirm('Delete this offer?')">
                @csrf @method('DELETE')
                <button type="submit" class="btn btn-block btn-sell btn-sm">Delete Offer</button>
              </form>
            </div>
          </div>
        @elseif(!$offer->is_active)
          <div class="alert alert-warning">This offer is not currently active.</div>
        @endif
      @else
        <div class="card card-body text-center">
          <p style="color:var(--muted)">Sign in to start trading</p>
          <a href="{{ route('login') }}" class="btn btn-accent">Sign In</a>
        </div>
      @endauth
    </div>
  </div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/offers/create.blade.php", r"""@extends('layouts.app')
@section('title','Post Offer')
@section('content')
<div class="container mt-4">
  <div class="row justify-content-center">
    <div class="col-lg-8">
      <div class="card">
        <div class="card-header">
          <h5 class="mb-0"><i class="fas fa-plus" style="color:var(--accent)"></i> Post New Offer</h5>
        </div>
        <div class="card-body">
          <form method="POST" action="{{ route('offers.store') }}">
            @csrf
            <div class="form-row">
              <div class="form-group col-md-6">
                <label>Offer Type</label>
                <select name="type" class="form-control @error('type')is-invalid@enderror" required>
                  <option value="buy"  @selected(old('type')=='buy')>I want to BUY crypto</option>
                  <option value="sell" @selected(old('type')=='sell')>I want to SELL crypto</option>
                </select>
                @error('type')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
              <div class="form-group col-md-6">
                <label>Cryptocurrency</label>
                <select name="crypto" class="form-control @error('crypto')is-invalid@enderror" required>
                  <option value="BTC" @selected(old('crypto')=='BTC')>Bitcoin (BTC)</option>
                  <option value="XMR" @selected(old('crypto')=='XMR')>Monero (XMR)</option>
                </select>
                @error('crypto')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-md-4">
                <label>Fiat Currency</label>
                <select name="fiat_currency" class="form-control @error('fiat_currency')is-invalid@enderror" required>
                  @foreach(['USD','EUR','GBP','CAD','AUD','CHF','JPY','CNY'] as $c)
                    <option value="{{ $c }}" @selected(old('fiat_currency', 'USD') === $c)>{{ $c }}</option>
                  @endforeach
                </select>
                @error('fiat_currency')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
              <div class="form-group col-md-4">
                <label>Min Amount (fiat)</label>
                <input type="number" step="0.01" name="min_amount"
                       class="form-control @error('min_amount')is-invalid@enderror"
                       value="{{ old('min_amount') }}" required placeholder="e.g. 10">
                @error('min_amount')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
              <div class="form-group col-md-4">
                <label>Max Amount (fiat)</label>
                <input type="number" step="0.01" name="max_amount"
                       class="form-control @error('max_amount')is-invalid@enderror"
                       value="{{ old('max_amount') }}" required placeholder="e.g. 1000">
                @error('max_amount')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
            </div>
            <div class="form-row">
              <div class="form-group col-md-6">
                <label>Price Margin (%)</label>
                <input type="number" step="0.01" name="price_margin"
                       class="form-control @error('price_margin')is-invalid@enderror"
                       value="{{ old('price_margin',0) }}" min="-50" max="50">
                <small style="color:var(--muted)">Positive = premium above market; negative = discount</small>
                @error('price_margin')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
              <div class="form-group col-md-6">
                <label>Payment Method</label>
                <input type="text" name="payment_method"
                       class="form-control @error('payment_method')is-invalid@enderror"
                       value="{{ old('payment_method') }}" required
                       placeholder="e.g. Bank Transfer, Cash, Revolut">
                @error('payment_method')<div class="invalid-feedback">{{$message}}</div>@enderror
              </div>
            </div>
            <div class="form-group">
              <label>Country (2-letter ISO, optional)</label>
              <input type="text" name="country" class="form-control @error('country')is-invalid@enderror"
                     value="{{ old('country') }}" maxlength="2" placeholder="e.g. US">
              @error('country')<div class="invalid-feedback">{{$message}}</div>@enderror
            </div>
            <div class="form-group">
              <label>Trade Terms <small style="color:var(--muted)">(optional – what the other party needs to do)</small></label>
              <textarea name="terms" class="form-control @error('terms')is-invalid@enderror"
                        rows="5" placeholder="Describe payment steps, requirements, etc.">{{ old('terms') }}</textarea>
              @error('terms')<div class="invalid-feedback">{{$message}}</div>@enderror
            </div>
            <button type="submit" class="btn btn-accent btn-block">Post Offer</button>
          </form>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")


    # ------------------------------------------------------------------
    # Trades: Index
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/trades/index.blade.php", r"""@extends('layouts.app')
@section('title','My Trades')
@section('content')
<div class="container mt-4">
  <h4 class="mb-4">My Trades</h4>
  <div class="card">
    <div class="card-body p-0">
      <table class="table table-hover mb-0">
        <thead><tr>
          <th>Trade ID</th><th>Crypto</th><th>Counterparty</th>
          <th>Amount</th><th>Payment</th><th>Status</th><th>Date</th><th></th>
        </tr></thead>
        <tbody>
        @forelse($trades as $trade)
          @php
            $isBuyer = $trade->buyer_id === Auth::id();
            $peer    = $isBuyer ? $trade->seller : $trade->buyer;
          @endphp
          <tr>
            <td><code>{{ $trade->trade_id }}</code></td>
            <td><span class="badge badge-secondary">{{ $trade->crypto }}</span></td>
            <td>
              @if($peer)
                <a href="{{ route('profile.show',$peer) }}">{{ $peer->username }}</a>
              @else — @endif
              <br><small style="color:var(--muted)">{{ $isBuyer ? 'You buy' : 'You sell' }}</small>
            </td>
            <td>{{ number_format($trade->fiat_amount,2) }} {{ $trade->fiat_currency }}</td>
            <td><small>{{ Str::limit($trade->payment_method,20) }}</small></td>
            <td>
              <span class="trade-badge badge-{{ $trade->status }}">{{ $trade->status }}</span>
            </td>
            <td><small>{{ $trade->created_at->format('d M Y') }}</small></td>
            <td>
              <a href="{{ route('trades.show',$trade) }}" class="btn btn-sm btn-outline-accent">View</a>
            </td>
          </tr>
        @empty
          <tr>
            <td colspan="8" class="text-center py-5" style="color:var(--muted)">
              No trades yet. <a href="{{ route('offers.index') }}">Browse offers</a> to start.
            </td>
          </tr>
        @endforelse
        </tbody>
      </table>
    </div>
  </div>
  <div class="d-flex justify-content-center mt-4">{{ $trades->links() }}</div>
</div>
@endsection
""")

    # ------------------------------------------------------------------
    # Trades: Show (with actions + chat)
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/trades/show.blade.php", r"""@extends('layouts.app')
@section('title','Trade #{{ $trade->trade_id }}')
@section('content')
<div class="container mt-4">
  <div class="row">
    {{-- Main trade info --}}
    <div class="col-lg-8">
      <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
          <div>
            <h5 class="mb-0">Trade <code>{{ $trade->trade_id }}</code></h5>
            <small style="color:var(--muted)">
              {{ $trade->crypto }} · {{ $trade->payment_method }}
            </small>
          </div>
          <span class="trade-badge badge-{{ $trade->status }} px-3 py-2">
            {{ strtoupper($trade->status) }}
          </span>
        </div>
        <div class="card-body">
          <div class="row">
            <div class="col-sm-6">
              <table class="table table-borderless table-sm mb-0">
                <tr><td style="color:var(--muted)">Fiat Amount</td>
                    <td class="font-weight-bold">{{ number_format($trade->fiat_amount,2) }} {{ $trade->fiat_currency }}</td></tr>
                <tr><td style="color:var(--muted)">Crypto</td>
                    <td>{{ $trade->crypto }}</td></tr>
                <tr><td style="color:var(--muted)">Buyer</td>
                    <td>
                      <a href="{{ route('profile.show',$trade->buyer) }}">{{ optional($trade->buyer)->username }}</a>
                      @if($trade->buyer_id === Auth::id()) <span class="badge badge-secondary">you</span> @endif
                    </td></tr>
                <tr><td style="color:var(--muted)">Seller</td>
                    <td>
                      <a href="{{ route('profile.show',$trade->seller) }}">{{ optional($trade->seller)->username }}</a>
                      @if($trade->seller_id === Auth::id()) <span class="badge badge-secondary">you</span> @endif
                    </td></tr>
                @if($trade->expires_at)
                <tr><td style="color:var(--muted)">Expires</td>
                    <td>{{ $trade->expires_at->format('d M Y H:i') }} UTC</td></tr>
                @endif
                <tr><td style="color:var(--muted)">Opened</td>
                    <td>{{ $trade->created_at->format('d M Y H:i') }} UTC</td></tr>
              </table>
            </div>
            <div class="col-sm-6">
              @if($trade->offer && $trade->offer->terms)
                <h6 style="color:var(--muted)">Payment Instructions</h6>
                <div style="background:var(--bg3);border-radius:6px;padding:.75rem;font-size:.9rem;white-space:pre-line">{{ $trade->offer->terms }}</div>
              @endif
            </div>
          </div>
        </div>
      </div>

      {{-- Chat box --}}
      <div class="card mb-3">
        <div class="card-header"><h6 class="mb-0"><i class="fas fa-comments mr-1"></i> Trade Chat</h6></div>
        <div class="card-body p-0">
          <div class="chat-box" id="chat">
            @forelse($trade->messages as $msg)
              @if($msg->is_system)
                <div class="chat-msg system">
                  <div class="body">{{ $msg->message }}</div>
                </div>
              @else
                <div class="chat-msg {{ $msg->user_id === Auth::id() ? 'mine' : '' }}">
                  <div class="meta">{{ optional($msg->user)->username }} · {{ $msg->created_at->format('H:i d M') }}</div>
                  <div class="body">{{ $msg->message }}</div>
                </div>
              @endif
            @empty
              <p style="color:var(--muted);text-align:center;padding:1rem">No messages yet. Say hello!</p>
            @endforelse
          </div>
          @if(in_array($trade->status, ['open','paid','disputed']))
          <form method="POST" action="{{ route('trades.message',$trade) }}" class="p-3 d-flex">
            @csrf
            <input type="text" name="message" class="form-control mr-2"
                   placeholder="Type a message..." required maxlength="1000" autocomplete="off">
            <button type="submit" class="btn btn-accent btn-sm px-3">Send</button>
          </form>
          @endif
        </div>
      </div>
    </div>

    {{-- Sidebar actions --}}
    <div class="col-lg-4">
      <div class="sidebar-card">
        <h6 class="mb-3" style="color:var(--muted)">Trade Actions</h6>

        @php $uid = Auth::id(); @endphp

        {{-- Buyer: Mark as Paid --}}
        @if($trade->canBePaidBy($uid))
          <form method="POST" action="{{ route('trades.paid',$trade) }}">
            @csrf
            <button type="submit" class="action-btn btn-buy"
                    onclick="return confirm('Confirm: you have sent the payment?')">
              <i class="fas fa-check-circle mr-1"></i> I Paid — Mark as Paid
            </button>
          </form>
        @endif

        {{-- Seller: Release Funds --}}
        @if($trade->canBeReleasedBy($uid))
          <form method="POST" action="{{ route('trades.release',$trade) }}">
            @csrf
            <button type="submit" class="action-btn btn-buy"
                    onclick="return confirm('Confirm: you received payment and want to release funds?')">
              <i class="fas fa-paper-plane mr-1"></i> Release Funds to Buyer
            </button>
          </form>
        @endif

        {{-- Cancel --}}
        @if($trade->canBeCancelledBy($uid))
          <button class="action-btn" style="background:var(--bg3);color:var(--muted)"
                  data-toggle="collapse" data-target="#cancelForm">
            <i class="fas fa-times mr-1"></i> Cancel Trade
          </button>
          <div class="collapse mt-2" id="cancelForm">
            <form method="POST" action="{{ route('trades.cancel',$trade) }}">
              @csrf
              <textarea name="reason" class="form-control mb-2" rows="2"
                        placeholder="Reason (optional)" maxlength="500"></textarea>
              <button type="submit" class="btn btn-sell btn-sm btn-block">
                Confirm Cancel
              </button>
            </form>
          </div>
        @endif

        {{-- Dispute --}}
        @if($trade->canBeDisputedBy($uid))
          <button class="action-btn btn-sell mt-1"
                  data-toggle="collapse" data-target="#disputeForm">
            <i class="fas fa-exclamation-triangle mr-1"></i> Open Dispute
          </button>
          <div class="collapse mt-2" id="disputeForm">
            <form method="POST" action="{{ route('trades.dispute',$trade) }}">
              @csrf
              <textarea name="reason" class="form-control mb-2" rows="3"
                        placeholder="Describe the issue..." required maxlength="1000"></textarea>
              <button type="submit" class="btn btn-sell btn-sm btn-block">
                Submit Dispute
              </button>
            </form>
          </div>
        @endif

        @if(in_array($trade->status,['completed','cancelled','disputed']) && !$trade->canBePaidBy($uid) && !$trade->canBeReleasedBy($uid))
          <p class="text-center mt-2" style="color:var(--muted)">
            This trade is <strong>{{ $trade->status }}</strong>.
          </p>
        @endif
      </div>

      <div class="sidebar-card">
        <h6 style="color:var(--muted)" class="mb-2">Trade Timeline</h6>
        <ul class="list-unstyled mb-0" style="font-size:.85rem">
          <li><i class="fas fa-circle text-success mr-2" style="font-size:.5rem"></i>
              Opened: {{ $trade->created_at->format('d M Y H:i') }}</li>
          @if($trade->paid_at)
          <li><i class="fas fa-circle text-info mr-2" style="font-size:.5rem"></i>
              Paid: {{ $trade->paid_at->format('d M Y H:i') }}</li>
          @endif
          @if($trade->completed_at)
          <li><i class="fas fa-circle text-success mr-2" style="font-size:.5rem"></i>
              Completed: {{ $trade->completed_at->format('d M Y H:i') }}</li>
          @endif
        </ul>
      </div>

      <a href="{{ route('trades.index') }}" class="btn btn-outline-accent btn-block btn-sm">
        ← Back to My Trades
      </a>
    </div>
  </div>
</div>
@endsection
@section('scripts')
<script>
  // Auto-scroll chat
  var chat = document.getElementById('chat');
  if(chat) chat.scrollTop = chat.scrollHeight;
</script>
@endsection
""")


    # ------------------------------------------------------------------
    # Wallet, Dashboard, Profile, Errors
    # ------------------------------------------------------------------
    wf(f"{APP_ROOT}/resources/views/wallet/index.blade.php", r"""@extends('layouts.app')
@section('title','Wallet')
@section('content')
<div class="container mt-4">
  <h4 class="mb-4"><i class="fas fa-wallet" style="color:var(--accent)"></i> My Wallet</h4>
  <div class="row mb-4">
    <div class="col-md-6 mb-3">
      <div class="card">
        <div class="card-header">
          <h6 class="mb-0"><i class="fab fa-bitcoin text-warning mr-2"></i>Bitcoin (BTC)</h6>
        </div>
        <div class="card-body">
          <div class="row text-center">
            <div class="col-6">
              <div style="color:var(--muted);font-size:.8rem">Available</div>
              <div class="stat-num" style="font-size:1.5rem">{{ number_format($user->btc_balance,8) }}</div>
            </div>
            <div class="col-6">
              <div style="color:var(--muted);font-size:.8rem">In Escrow</div>
              <div class="stat-num text-warning" style="font-size:1.5rem">{{ number_format($user->escrow_btc,8) }}</div>
            </div>
          </div>
          @if($user->btc_deposit_address)
            <hr style="border-color:var(--border)">
            <small style="color:var(--muted)">Deposit Address:</small><br>
            <code style="font-size:.75rem;word-break:break-all">{{ $user->btc_deposit_address }}</code>
          @else
            <hr style="border-color:var(--border)">
            <small style="color:var(--muted)">No BTC deposit address assigned yet.</small>
          @endif
        </div>
      </div>
    </div>
    <div class="col-md-6 mb-3">
      <div class="card">
        <div class="card-header">
          <h6 class="mb-0"><i class="fas fa-coins mr-2" style="color:var(--muted)"></i>Monero (XMR)</h6>
        </div>
        <div class="card-body">
          <div class="row text-center">
            <div class="col-6">
              <div style="color:var(--muted);font-size:.8rem">Available</div>
              <div class="stat-num" style="font-size:1.5rem">{{ number_format($user->xmr_balance,12) }}</div>
            </div>
            <div class="col-6">
              <div style="color:var(--muted);font-size:.8rem">In Escrow</div>
              <div class="stat-num text-warning" style="font-size:1.5rem">{{ number_format($user->escrow_xmr,12) }}</div>
            </div>
          </div>
          @if($user->xmr_deposit_address)
            <hr style="border-color:var(--border)">
            <small style="color:var(--muted)">Deposit Address:</small><br>
            <code style="font-size:.75rem;word-break:break-all">{{ $user->xmr_deposit_address }}</code>
          @else
            <hr style="border-color:var(--border)">
            <small style="color:var(--muted)">No XMR deposit address assigned yet.</small>
          @endif
        </div>
      </div>
    </div>
  </div>

  <div class="card">
    <div class="card-header"><h6 class="mb-0">Transaction History</h6></div>
    <div class="card-body p-0">
      <table class="table table-hover mb-0">
        <thead><tr>
          <th>Date</th><th>Crypto</th><th>Type</th><th>Amount</th><th>Status</th><th>TXID</th>
        </tr></thead>
        <tbody>
        @forelse($transactions as $tx)
          <tr>
            <td><small>{{ $tx->created_at->format('d M Y H:i') }}</small></td>
            <td><span class="badge badge-secondary">{{ $tx->crypto }}</span></td>
            <td>{{ str_replace('_',' ',$tx->type) }}</td>
            <td class="{{ in_array($tx->type,['deposit','trade_in']) ? 'text-success' : 'text-danger' }}">
              {{ $tx->amount }}
            </td>
            <td><span class="badge badge-secondary">{{ $tx->status }}</span></td>
            <td><code style="font-size:.75rem">{{ $tx->txid ? Str::limit($tx->txid,16) : '—' }}</code></td>
          </tr>
        @empty
          <tr><td colspan="6" class="text-center py-4" style="color:var(--muted)">No transactions yet.</td></tr>
        @endforelse
        </tbody>
      </table>
    </div>
  </div>
  <div class="d-flex justify-content-center mt-4">{{ $transactions->links() }}</div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/dashboard.blade.php", r"""@extends('layouts.app')
@section('title','Dashboard')
@section('content')
<div class="container mt-4">
  <div class="d-flex align-items-center mb-4">
    <img src="{{ $user->avatar }}" class="rounded-circle mr-3" width="48" height="48" alt="">
    <div>
      <h4 class="mb-0">Welcome, <strong style="color:var(--accent)">{{ $user->username }}</strong></h4>
      <small style="color:var(--muted)">
        @if($user->last_seen_at) Last seen {{ $user->last_seen_at->diffForHumans() }} @endif
      </small>
    </div>
    <div class="ml-auto">
      <a href="{{ route('offers.create') }}" class="btn btn-accent">
        <i class="fas fa-plus mr-1"></i> Post Offer
      </a>
    </div>
  </div>

  <div class="row mb-4">
    <div class="col-6 col-md-3 mb-3">
      <div class="stat-box">
        <div class="stat-num">{{ $stats['active_trades'] }}</div>
        <div style="color:var(--muted);font-size:.85rem">Active Trades</div>
      </div>
    </div>
    <div class="col-6 col-md-3 mb-3">
      <div class="stat-box">
        <div class="stat-num">{{ $stats['active_offers'] }}</div>
        <div style="color:var(--muted);font-size:.85rem">Active Offers</div>
      </div>
    </div>
    <div class="col-6 col-md-3 mb-3">
      <div class="stat-box">
        <div class="stat-num" style="font-size:1.2rem">{{ number_format($stats['btc_balance'],4) }}</div>
        <div style="color:var(--muted);font-size:.85rem">BTC Balance</div>
      </div>
    </div>
    <div class="col-6 col-md-3 mb-3">
      <div class="stat-box">
        <div class="stat-num" style="font-size:1.2rem">{{ number_format($stats['xmr_balance'],4) }}</div>
        <div style="color:var(--muted);font-size:.85rem">XMR Balance</div>
      </div>
    </div>
  </div>

  <div class="row">
    <div class="col-lg-7 mb-4">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h6 class="mb-0">Active Trades</h6>
          <a href="{{ route('trades.index') }}" class="btn btn-sm btn-outline-accent">All Trades</a>
        </div>
        <div class="card-body p-0">
          <table class="table table-hover mb-0">
            <thead><tr><th>ID</th><th>Crypto</th><th>Amount</th><th>Status</th><th></th></tr></thead>
            <tbody>
            @forelse($activeTrades as $t)
              <tr>
                <td><code>{{ $t->trade_id }}</code></td>
                <td>{{ $t->crypto }}</td>
                <td>{{ number_format($t->fiat_amount,2) }} {{ $t->fiat_currency }}</td>
                <td><span class="trade-badge badge-{{ $t->status }}">{{ $t->status }}</span></td>
                <td><a href="{{ route('trades.show',$t) }}" class="btn btn-sm btn-outline-accent">View</a></td>
              </tr>
            @empty
              <tr><td colspan="5" class="text-center py-3" style="color:var(--muted)">No active trades.</td></tr>
            @endforelse
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="col-lg-5 mb-4">
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h6 class="mb-0">My Offers</h6>
          <a href="{{ route('offers.create') }}" class="btn btn-sm btn-accent">+ New</a>
        </div>
        <div class="card-body p-0">
          <table class="table table-hover mb-0">
            <thead><tr><th>Type</th><th>Crypto</th><th>Active</th><th></th></tr></thead>
            <tbody>
            @forelse($myOffers as $o)
              <tr>
                <td><span class="badge {{ $o->type=='buy'?'badge-success':'badge-danger' }}">{{ $o->type }}</span></td>
                <td>{{ $o->crypto }}</td>
                <td>
                  @if($o->is_active)
                    <span class="text-success"><i class="fas fa-circle" style="font-size:.5rem"></i> Yes</span>
                  @else
                    <span style="color:var(--muted)"><i class="fas fa-circle" style="font-size:.5rem"></i> No</span>
                  @endif
                </td>
                <td><a href="{{ route('offers.show',$o) }}" class="btn btn-sm btn-outline-accent">View</a></td>
              </tr>
            @empty
              <tr><td colspan="4" class="text-center py-3" style="color:var(--muted)">No offers yet.</td></tr>
            @endforelse
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/profile/show.blade.php", r"""@extends('layouts.app')
@section('title', $user->username . ' — Profile')
@section('content')
<div class="container mt-4">
  <div class="row">
    <div class="col-lg-4 mb-4">
      <div class="card text-center">
        <div class="card-body py-4">
          <img src="{{ $user->avatar }}" class="rounded-circle mb-3" width="80" height="80" alt="">
          <h4>{{ $user->username }}</h4>
          <p style="color:var(--muted)">
            <i class="fas fa-check-circle text-success mr-1"></i>{{ $user->completed_trades }} completed trades
          </p>
          @if($user->bio)
            <p style="font-size:.9rem">{{ $user->bio }}</p>
          @endif
          <small style="color:var(--muted)">
            Member since {{ $user->created_at->format('M Y') }}
          </small>
        </div>
      </div>
    </div>
    <div class="col-lg-8">
      <div class="card">
        <div class="card-header"><h6 class="mb-0">Active Offers</h6></div>
        <div class="card-body p-0">
          <table class="table table-hover mb-0">
            <thead><tr>
              <th>Type</th><th>Crypto</th><th>Payment</th><th>Margin</th><th>Limits</th><th></th>
            </tr></thead>
            <tbody>
            @forelse($offers as $o)
              <tr>
                <td><span class="badge {{ $o->type=='buy'?'badge-success':'badge-danger' }}">{{ strtoupper($o->type) }}</span></td>
                <td>{{ $o->crypto }}</td>
                <td><small>{{ $o->payment_method }}</small></td>
                <td>
                  @if($o->price_margin>=0)<span class="text-success">+{{ $o->price_margin }}%</span>
                  @else<span class="text-danger">{{ $o->price_margin }}%</span>@endif
                </td>
                <td><small>{{ $o->min_amount }}–{{ $o->max_amount }} {{ $o->fiat_currency }}</small></td>
                <td>
                  <a href="{{ route('offers.show',$o) }}"
                     class="btn btn-sm {{ $o->type=='buy' ? 'btn-buy' : 'btn-sell' }}">
                    {{ $o->type=='buy' ? 'Sell' : 'Buy' }}
                  </a>
                </td>
              </tr>
            @empty
              <tr><td colspan="6" class="text-center py-3" style="color:var(--muted)">No active offers.</td></tr>
            @endforelse
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/errors/500.blade.php", r"""@extends('layouts.app')
@section('title','500 Server Error')
@section('content')
<div class="container mt-5 text-center py-5">
  <h1 class="display-1 font-weight-bold" style="color:var(--red)">500</h1>
  <h3 class="mb-3">Internal Server Error</h3>
  <p style="color:var(--muted)">Something went wrong on our end. Please try again shortly.</p>
  <a href="{{ url('/') }}" class="btn btn-accent">← Go Home</a>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/errors/404.blade.php", r"""@extends('layouts.app')
@section('title','404 Not Found')
@section('content')
<div class="container mt-5 text-center py-5">
  <h1 class="display-1 font-weight-bold" style="color:var(--yellow)">404</h1>
  <h3 class="mb-3">Page Not Found</h3>
  <p style="color:var(--muted)">The page you're looking for doesn't exist or has been moved.</p>
  <a href="{{ url('/') }}" class="btn btn-accent">← Go Home</a>
</div>
@endsection
""")
    ok("Blade views written")


# ============================================================================
# Laravel App – Assets, Seeders, .env
# ============================================================================
def write_assets():
    log("Writing frontend assets")
    wf(f"{APP_ROOT}/webpack.mix.js", r"""const mix = require('laravel-mix');
mix.js('resources/js/app.js', 'public/js')
   .sass('resources/sass/app.scss', 'public/css');
""")
    wf(f"{APP_ROOT}/resources/js/app.js", r"""require('./bootstrap');
""")
    wf(f"{APP_ROOT}/resources/js/bootstrap.js", r"""window._ = require('lodash');
window.axios = require('axios');
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
const token = document.head.querySelector('meta[name="csrf-token"]');
if (token) window.axios.defaults.headers.common['X-CSRF-TOKEN'] = token.content;
""")
    wf(f"{APP_ROOT}/resources/sass/app.scss", "@import '~bootstrap/scss/bootstrap';\n")
    ok("Assets written")


def write_seeders():
    log("Writing DatabaseSeeder")
    # Use f-string so the random ADMIN_PASS is baked into the PHP file.
    seeder_content = f"""<?php

namespace Database\\Seeders;

use App\\Models\\User;
use Illuminate\\Database\\Seeder;
use Illuminate\\Support\\Facades\\Hash;

class DatabaseSeeder extends Seeder
{{
    public function run()
    {{
        User::updateOrCreate(
            ['username' => 'admin'],
            [
                'email'     => 'admin@capitalmonero.com',
                'password'  => Hash::make('{ADMIN_PASS}'),
                'role'      => 'admin',
                'is_active' => true,
            ]
        );
    }}
}}
"""
    wf(f"{APP_ROOT}/database/seeders/DatabaseSeeder.php", seeder_content)
    ok("Seeder written")


def write_env():
    log("Writing .env")
    env_path = Path(f"{APP_ROOT}/.env")
    new_vals = {
        "APP_NAME":            "CapitalMonero",
        "APP_ENV":             "production",
        "APP_DEBUG":           "false",
        "APP_URL":             f"https://{DOMAIN}",
        "DB_CONNECTION":       "mysql",
        "DB_HOST":             "127.0.0.1",
        "DB_PORT":             "3306",
        "DB_DATABASE":         DB_NAME,
        "DB_USERNAME":         DB_USER,
        "DB_PASSWORD":         DB_PASS,
        "SESSION_DRIVER":      "file",
        "CACHE_DRIVER":        "file",
        "QUEUE_CONNECTION":    "sync",
        "BROADCAST_DRIVER":    "null",
        "MAIL_MAILER":         "log",
        "REDIS_HOST":          "127.0.0.1",
        "REDIS_PORT":          "6379",
        "SESSION_SECURE_COOKIE": "false",
    }
    if env_path.exists():
        content = env_path.read_text()
        for k, v in new_vals.items():
            pattern = rf"^{re.escape(k)}=.*$"
            if re.search(pattern, content, re.MULTILINE):
                content = re.sub(pattern, f"{k}={v}", content, flags=re.MULTILINE)
            else:
                content += f"\n{k}={v}\n"
        env_path.write_text(content)
        ok("Patched existing .env")
    else:
        lines = "\n".join(f"{k}={v}" for k, v in new_vals.items())
        wf(str(env_path), f"APP_KEY=\n{lines}\n")
        ok("Created .env")

    wf(f"{APP_ROOT}/.env.example", "\n".join(
        f"{k}=" for k in new_vals.keys()) + "\n")


# ============================================================================
# Build orchestrator
# ============================================================================
def build_laravel_app():
    log("=== Building Laravel 8 application files ===")
    Path(APP_ROOT).mkdir(parents=True, exist_ok=True)
    make_storage_dirs()
    write_env()
    write_migration()
    write_models()
    write_controllers()
    write_middleware()
    write_kernel()
    write_providers()
    write_exceptions()
    write_console()
    write_routes()
    write_config()
    write_bootstrap()
    write_public()
    write_lang()
    write_views()
    write_assets()
    write_seeders()
    ok("=== All application files written ===")


# ============================================================================
# Post-build: artisan commands + permissions
# ============================================================================
def post_build():
    log("Running post-build steps")

    artisan = [PHP_BIN, "artisan"]

    # Ensure vendor/ exists before running artisan
    if not Path(f"{APP_ROOT}/vendor/autoload.php").exists():
        log("vendor/autoload.php missing – running composer install")
        c_env = {"COMPOSER_ALLOW_SUPERUSER": "1", "COMPOSER_NO_INTERACTION": "1"}
        c_bin = shutil.which("composer") or COMPOSER
        run_checked([c_bin, "install", "--no-interaction", "--prefer-dist",
                     "--optimize-autoloader", "--no-scripts", "--no-audit"],
                    cwd=APP_ROOT, env=c_env, msg="composer install failed")

    # Clear any cached config first (stale cache causes 500)
    run(artisan + ["config:clear"],   cwd=APP_ROOT)
    run(artisan + ["cache:clear"],    cwd=APP_ROOT)
    run(artisan + ["route:clear"],    cwd=APP_ROOT)
    run(artisan + ["view:clear"],     cwd=APP_ROOT)

    # Generate key if missing
    env_text = Path(f"{APP_ROOT}/.env").read_text()
    if "APP_KEY=\n" in env_text or "APP_KEY=base64" not in env_text:
        run_checked(artisan + ["key:generate", "--force"],
                    cwd=APP_ROOT, msg="key:generate failed")

    # Run migrations
    run_checked(artisan + ["migrate", "--force"],
                cwd=APP_ROOT, msg="migrate failed")

    # Seed
    run(artisan + ["db:seed", "--force"], cwd=APP_ROOT)

    # Cache for production
    run(artisan + ["config:cache"],  cwd=APP_ROOT)
    run(artisan + ["route:cache"],   cwd=APP_ROOT)
    run(artisan + ["view:cache"],    cwd=APP_ROOT)
    run(artisan + ["storage:link"],  cwd=APP_ROOT)

    # Package discovery
    c_env = {"COMPOSER_ALLOW_SUPERUSER": "1"}
    c_bin = shutil.which("composer") or COMPOSER
    run([c_bin, "run-script", "post-autoload-dump", "--no-interaction"],
        cwd=APP_ROOT, env=c_env)

    # Permissions
    # Set file/dir ownership so Apache can read the app
    run(["chown", "-R", "www-data:www-data", APP_ROOT])
    run(["find", APP_ROOT, "-type", "f", "-exec", "chmod", "644", "{}", "+"])
    run(["find", APP_ROOT, "-type", "d", "-exec", "chmod", "755", "{}", "+"])
    # storage/ and bootstrap/cache/ must be writable by www-data
    run(["chmod", "-R", "775",
         f"{APP_ROOT}/storage",
         f"{APP_ROOT}/bootstrap/cache"])
    # Protect .env from group/other read
    env_file = Path(f"{APP_ROOT}/.env")
    if env_file.exists():
        os.chmod(str(env_file), 0o640)

    run(["systemctl", "restart", "apache2"])
    ok("Post-build complete")


# ============================================================================
# Diagnostic: collect 500-error clues from logs
# ============================================================================
def debug_500():
    log("=== 500 Diagnostics ===")

    # Laravel log
    laravel_log = f"{APP_ROOT}/storage/logs/laravel.log"
    if Path(laravel_log).exists():
        content = Path(laravel_log).read_text(errors="replace")
        lines   = content.splitlines()
        # Show last 40 lines
        print("\n--- Last 40 lines of laravel.log ---")
        for l in lines[-40:]:
            print(f"  {l}")
    else:
        warn("No laravel.log found")

    # Apache error log
    for alog in ["/var/log/apache2/capitalmonero_error.log",
                 "/var/log/apache2/error.log"]:
        if Path(alog).exists():
            r = run(["tail", "-n", "30", alog], quiet=True)
            print(f"\n--- {alog} (last 30 lines) ---")
            for l in r.stdout.splitlines():
                print(f"  {l}")
            break

    # PHP syntax check on public/index.php
    r = run([PHP_BIN, "-l", f"{APP_ROOT}/public/index.php"], quiet=True)
    if r.returncode == 0:
        ok("public/index.php syntax OK")
    else:
        err(f"public/index.php syntax error: {r.stdout.strip()}")

    # Check .env has APP_KEY
    env_path = Path(f"{APP_ROOT}/.env")
    if env_path.exists():
        env_text = env_path.read_text()
        if "APP_KEY=base64:" in env_text:
            ok("APP_KEY is set")
        else:
            err("APP_KEY is missing or empty — run: php artisan key:generate")

    # DB test
    r = run([PHP_BIN, "artisan", "tinker", "--execute",
             "echo DB::connection()->getPdo() ? 'DB_OK' : 'DB_FAIL';"],
            cwd=APP_ROOT, quiet=True)
    if "DB_OK" in r.stdout:
        ok("Database reachable from Laravel")
    else:
        err(f"DB unreachable: {r.stderr.strip()[:200]}")


# ============================================================================
# Final verification
# ============================================================================
def verify():
    log("=== Final Verification ===")

    services = ["mariadb", "redis-server", "apache2",
                "tor", "capitalmonero-bitcoind", "capitalmonero-monerod"]
    for svc in services:
        r = run(["systemctl", "is-active", svc], quiet=True)
        status = r.stdout.strip() or "unknown"
        symbol = "OK" if status == "active" else "WARN"
        print(f"  [{symbol}] {svc}: {status}")

    # Ports
    for port in [80, 443]:
        r = run(["ss", "-tlnp"], quiet=True)
        if f":{port} " in r.stdout or f":{port}\n" in r.stdout:
            ok(f"Port {port} listening")
        else:
            warn(f"Port {port} may not be listening (check ss -tlnp)")

    # Redis
    r = run(["redis-cli", "ping"], quiet=True)
    if "PONG" in r.stdout:
        ok("Redis PONG")
    else:
        warn("Redis not responding")

    # Apache config test
    r = run(["apachectl", "configtest"], quiet=True)
    if r.returncode == 0:
        ok("Apache config OK")
    else:
        warn(f"Apache config issue: {r.stderr.strip()[:200]}")

    debug_500()

    print()
    print("=" * 62)
    print("  CapitalMonero Exchange — Deployment Complete")
    print("=" * 62)
    print(f"  Clearnet : https://{DOMAIN}/")
    print(f"  Onion    : http://{ONION}/")
    print(f"  App root : {APP_ROOT}")
    print(f"  Admin    : username=admin  password={ADMIN_PASS}")
    print(f"             *** CHANGE PASSWORD IMMEDIATELY ***")
    print("=" * 62)


# ============================================================================
# Main
# ============================================================================
def main():
    if os.geteuid() != 0:
        sys.exit("[FATAL] Run as root: sudo python3 fix_capitalmonero.py")

    log("CapitalMonero Exchange — Fix Script v2")
    log(f"App root : {APP_ROOT}")
    log(f"PHP      : {PHP_BIN}")

    install_system_packages()
    ensure_composer()
    fix_database()
    fix_composer()
    fix_npm()
    fix_monerod()
    fix_https()
    build_laravel_app()
    post_build()
    verify()

    log("All fixes applied. Review any WARN/ERR messages above.")


if __name__ == "__main__":
    main()
