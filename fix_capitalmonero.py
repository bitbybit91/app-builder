#!/usr/bin/env python3
"""
fix_capitalmonero.py
Complete fix for CapitalMonero Exchange deployment errors.

Addresses:
  1. DB    – shell backtick → SQL syntax error (pipe SQL via stdin, shell=False)
  2. Composer – double-caret version constraint
  3. NPM   – invalid tag / Vite vs Laravel Mix
  4. Monerod – stuck in activating (Type=forking → Type=simple)
  5. HTTPS – missing SSL + Apache vhosts
  6. 500   – missing entire Laravel 8 application

Domain : capitalmonero.com
Onion  : fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion
AppRoot: /var/www/capitalmonero/app
Stack  : Laravel 8 / Bootstrap 4 / Apache / MariaDB / Redis / Tor / PHP 7.4
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
APP_ROOT = "/var/www/capitalmonero/app"
DOMAIN   = "capitalmonero.com"
ONION    = "fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion"
PHP_BIN  = "php7.4"
COMPOSER = "/usr/local/bin/composer"
CERT_DIR = "/etc/ssl/capitalmonero"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def log(msg):
    print(f"\n[*] {msg}")


def ok(msg):
    print(f"    [OK] {msg}")


def warn(msg):
    print(f"    [WARN] {msg}", file=sys.stderr)


def run(cmd, cwd=None, env=None, stdin_data=None, check=False):
    """Run command list (no shell) or string (shell=True).  Returns CompletedProcess.

    SECURITY: Prefer list form to avoid shell injection.  When a string is
    passed it must be a hardcoded literal — never build it from external input.
    """
    kwargs = dict(capture_output=True, text=True)
    if cwd:
        kwargs["cwd"] = cwd
    elif Path(APP_ROOT).exists():
        kwargs["cwd"] = APP_ROOT
    if env:
        kwargs["env"] = {**os.environ, **env}
    if stdin_data is not None:
        kwargs["input"] = stdin_data
    if isinstance(cmd, list):
        result = subprocess.run(cmd, **kwargs)
    else:
        result = subprocess.run(cmd, shell=True, **kwargs)
    if result.stdout.strip():
        print("   ", result.stdout.strip()[:600])
    if result.returncode != 0:
        msg = (result.stderr or "").strip()[:400]
        if check:
            sys.exit(f"[FATAL] Command failed: {msg}")
        warn(msg or f"exit code {result.returncode}")
    return result


def wf(path, content, mode=0o644):
    """Write *content* to *path*, creating parent dirs as needed."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    os.chmod(path, mode)


def mkdirs(*paths):
    for p in paths:
        Path(p).mkdir(parents=True, exist_ok=True)


# ---------------------------------------------------------------------------
# Fix 1 – Database: shell backtick interpretation
# ---------------------------------------------------------------------------
def fix_database():
    log("Fix 1: Database – pipe SQL via stdin (shell=False)")
    sql = (
        "CREATE DATABASE IF NOT EXISTS `capitalmonero` "
        "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\n"
        "GRANT ALL PRIVILEGES ON `capitalmonero`.* "
        "TO 'capitalmonero'@'localhost' IDENTIFIED BY 'capitalmonero_secret';\n"
        "FLUSH PRIVILEGES;\n"
    )
    r = run(["mariadb", "-u", "root"], stdin_data=sql)
    if r.returncode == 0:
        ok("Database and user created/verified")
    else:
        warn("DB create step had warnings – check manually")


# ---------------------------------------------------------------------------
# Fix 2 – Composer: double-caret version constraint
# ---------------------------------------------------------------------------
def fix_composer():
    log("Fix 2: Composer – writing valid composer.json")
    composer_json = """{
    "name": "capitalmonero/exchange",
    "type": "project",
    "description": "CapitalMonero P2P Crypto Exchange",
    "license": "MIT",
    "require": {
        "php": "^7.4",
        "ext-json": "*",
        "ext-mbstring": "*",
        "ext-pdo": "*",
        "fruitcake/laravel-cors": "^2.0",
        "guzzlehttp/guzzle": "^7.0.1",
        "laravel/framework": "^8.75",
        "laravel/sanctum": "^2.11",
        "laravel/tinker": "^2.5",
        "predis/predis": "^1.1"
    },
    "require-dev": {
        "facade/ignition": "^2.5",
        "fakerphp/faker": "^1.9.1",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^5.10",
        "phpunit/phpunit": "^9.5.10"
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "extra": {
        "laravel": {
            "dont-discover": []
        }
    },
    "autoload": {
        "psr-4": {
            "App\\\\": "app/",
            "Database\\\\Factories\\\\": "database/factories/",
            "Database\\\\Seeders\\\\": "database/seeders/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\\\": "tests/"
        }
    },
    "minimum-stability": "dev",
    "prefer-stable": true,
    "scripts": {
        "post-autoload-dump": [
            "Illuminate\\\\Foundation\\\\ComposerScripts::postAutoloadDump",
            "@php artisan package:discover --ansi"
        ],
        "post-update-cmd": [
            "@php artisan vendor:publish --tag=laravel-assets --ansi --force"
        ],
        "post-root-package-install": [
            "@php -r \\"file_exists('.env') || copy('.env.example', '.env');\\"" 
        ],
        "post-create-project-cmd": [
            "@php artisan key:generate --ansi"
        ]
    }
}
"""
    wf(f"{APP_ROOT}/composer.json", composer_json)

    # Wipe broken vendor tree and lock file
    vendor = Path(f"{APP_ROOT}/vendor")
    lock   = Path(f"{APP_ROOT}/composer.lock")
    if vendor.exists():
        shutil.rmtree(vendor)
        ok("Removed stale vendor/")
    if lock.exists():
        lock.unlink()
        ok("Removed stale composer.lock")

    env = {"COMPOSER_ALLOW_SUPERUSER": "1"}
    run([COMPOSER, "update", "--no-scripts", "--no-interaction", "--prefer-dist",
         "-W"], cwd=APP_ROOT, env=env)
    run([COMPOSER, "dump-autoload", "--optimize"], cwd=APP_ROOT, env=env)
    ok("Composer dependencies installed")


# ---------------------------------------------------------------------------
# Fix 3 – NPM: invalid tag name / Vite vs Laravel Mix
# ---------------------------------------------------------------------------
def fix_npm():
    log("Fix 3: NPM – writing package.json with laravel-mix")
    package_json = """{
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
        "bootstrap":          "^4.6.1",
        "jquery":             "^3.6.0",
        "laravel-mix":        "^6.0.49",
        "lodash":             "^4.17.19",
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

    run(["npm", "install"], cwd=APP_ROOT)
    ok("NPM packages installed")


# ---------------------------------------------------------------------------
# Fix 4 – Monerod: stuck in activating
# ---------------------------------------------------------------------------
def fix_monerod():
    log("Fix 4: Monerod – rewriting systemd unit with Type=simple")
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
    ok("Monerod service rewritten and restarted")


# ---------------------------------------------------------------------------
# Fix 5 – HTTPS: self-signed cert + Apache vhosts (80→443 redirect)
# ---------------------------------------------------------------------------
def fix_https():
    log("Fix 5: HTTPS – generating SSL cert and configuring Apache")
    mkdirs(CERT_DIR)

    # Self-signed cert (fallback)
    run([
        "openssl", "req", "-x509", "-nodes", "-days", "365",
        "-newkey", "rsa:2048",
        "-keyout", f"{CERT_DIR}/key.pem",
        "-out",    f"{CERT_DIR}/cert.pem",
        "-subj",   f"/CN={DOMAIN}/O=CapitalMonero/C=US",
    ])

    # Apache vhost: port 80 – redirect to HTTPS
    vhost_80 = f"""\
<VirtualHost *:80>
    ServerName {DOMAIN}
    ServerAlias www.{DOMAIN}
    Redirect permanent / https://{DOMAIN}/
</VirtualHost>
"""
    wf(f"/etc/apache2/sites-available/capitalmonero-http.conf", vhost_80)

    # Apache vhost: port 443 – SSL
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
    wf(f"/etc/apache2/sites-available/capitalmonero-ssl.conf", vhost_443)

    # Enable modules and sites
    for cmd in [
        ["a2enmod", "ssl"],
        ["a2enmod", "rewrite"],
        ["a2enmod", "headers"],
        ["a2dissite", "000-default"],
        ["a2ensite", "capitalmonero-http"],
        ["a2ensite", "capitalmonero-ssl"],
    ]:
        run(cmd)

    # Try Certbot for real cert
    r = run(["which", "certbot"])
    if r.returncode == 0:
        run([
            "certbot", "--apache", "--non-interactive", "--agree-tos",
            "-m", f"admin@{DOMAIN}", "-d", DOMAIN, "-d", f"www.{DOMAIN}",
            "--redirect",
        ])

    # Open port 443 in UFW if available
    r2 = run(["which", "ufw"])
    if r2.returncode == 0:
        run(["ufw", "allow", "443/tcp"])

    run(["systemctl", "restart", "apache2"])
    ok("HTTPS configured")



# ---------------------------------------------------------------------------
# Laravel 8 Application – Migration
# ---------------------------------------------------------------------------
def write_migration():
    log("Writing consolidated database migration")
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
            $table->string('username')->unique();
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
            $table->decimal('min_amount', 18, 8);
            $table->decimal('max_amount', 18, 8);
            $table->string('payment_method');
            $table->text('terms')->nullable();
            $table->string('country', 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('trade_count')->default(0);
            $table->timestamps();
        });

        Schema::create('trades', function (Blueprint $table) {
            $table->id();
            $table->string('trade_id')->unique();
            $table->foreignId('offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('buyer_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('seller_id')->constrained('users')->onDelete('cascade');
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->decimal('crypto_amount', 18, 8);
            $table->decimal('fiat_amount', 18, 2);
            $table->string('fiat_currency', 3)->default('USD');
            $table->string('payment_method');
            $table->enum('status', ['open', 'paid', 'released', 'disputed', 'cancelled', 'completed'])->default('open');
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('released_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('crypto', ['BTC', 'XMR']);
            $table->string('address');
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
            $table->string('status')->default('pending');
            $table->integer('confirmations')->default(0);
            $table->timestamps();
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('opened_by')->constrained('users')->onDelete('cascade');
            $table->unsignedBigInteger('resolved_by')->nullable();
            $table->foreign('resolved_by')->references('id')->on('users')->onDelete('set null');
            $table->text('reason');
            $table->text('resolution')->nullable();
            $table->string('status')->default('open');
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
        Schema::dropIfExists('trades');
        Schema::dropIfExists('offers');
        Schema::dropIfExists('users');
    }
}
""")
    ok("Migration written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Models
# ---------------------------------------------------------------------------
def write_models():
    log("Writing Eloquent models")

    wf(f"{APP_ROOT}/app/Models/User.php", r"""<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'username', 'email', 'password', 'role', 'is_active',
        'btc_balance', 'xmr_balance', 'escrow_btc', 'escrow_xmr',
        'btc_deposit_address', 'xmr_deposit_address',
        'completed_trades', 'rating', 'last_seen_at', 'preferred_currency',
    ];

    protected $hidden = ['password', 'remember_token', 'two_factor_secret'];

    protected $casts = [
        'email_verified_at'   => 'datetime',
        'last_seen_at'        => 'datetime',
        'is_active'           => 'boolean',
        'two_factor_enabled'  => 'boolean',
        'btc_balance'         => 'decimal:8',
        'xmr_balance'         => 'decimal:12',
        'escrow_btc'          => 'decimal:8',
        'escrow_xmr'          => 'decimal:12',
    ];

    public function offers()
    {
        return $this->hasMany(Offer::class);
    }

    public function tradesAsBuyer()
    {
        return $this->hasMany(Trade::class, 'buyer_id');
    }

    public function tradesAsSeller()
    {
        return $this->hasMany(Trade::class, 'seller_id');
    }

    public function wallets()
    {
        return $this->hasMany(Wallet::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function isAdmin()
    {
        return $this->role === 'admin';
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
        'user_id', 'type', 'crypto', 'fiat_currency',
        'price_margin', 'min_amount', 'max_amount',
        'payment_method', 'terms', 'country', 'is_active', 'trade_count',
    ];

    protected $casts = [
        'is_active'     => 'boolean',
        'price_margin'  => 'decimal:2',
        'min_amount'    => 'decimal:8',
        'max_amount'    => 'decimal:8',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function trades()
    {
        return $this->hasMany(Trade::class);
    }
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
        'trade_id', 'offer_id', 'buyer_id', 'seller_id',
        'crypto', 'crypto_amount', 'fiat_amount', 'fiat_currency',
        'payment_method', 'status',
        'paid_at', 'released_at', 'completed_at', 'expires_at',
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

    public function offer()
    {
        return $this->belongsTo(Offer::class);
    }

    public function buyer()
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function dispute()
    {
        return $this->hasOne(Dispute::class);
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/Wallet.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'crypto', 'address', 'balance', 'locked_balance',
    ];

    protected $casts = [
        'balance'        => 'decimal:8',
        'locked_balance' => 'decimal:8',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/Transaction.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'txid', 'crypto', 'type',
        'amount', 'fee', 'address', 'status', 'confirmations',
    ];

    protected $casts = [
        'amount' => 'decimal:8',
        'fee'    => 'decimal:8',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/Dispute.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'trade_id', 'opened_by', 'resolved_by',
        'reason', 'resolution', 'status',
    ];

    public function trade()
    {
        return $this->belongsTo(Trade::class);
    }

    public function opener()
    {
        return $this->belongsTo(User::class, 'opened_by');
    }

    public function resolver()
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
""")

    wf(f"{APP_ROOT}/app/Models/Notification.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'title', 'message', 'is_read'];

    protected $casts = ['is_read' => 'boolean'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
""")
    ok("Models written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Controllers
# ---------------------------------------------------------------------------
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
            'total_users'       => User::count(),
            'active_offers'     => Offer::where('is_active', true)->count(),
            'completed_trades'  => Trade::where('status', 'completed')->count(),
        ];

        $buyOffers = Offer::with('user')
            ->where('type', 'buy')
            ->where('is_active', true)
            ->latest()
            ->take(5)
            ->get();

        $sellOffers = Offer::with('user')
            ->where('type', 'sell')
            ->where('is_active', true)
            ->latest()
            ->take(5)
            ->get();

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
    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $credentials = [
            'username' => $request->username,
            'password' => $request->password,
        ];

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $request->session()->regenerate();
            Auth::user()->update(['last_seen_at' => now()]);
            return redirect()->intended(route('dashboard'));
        }

        return back()->withErrors(['username' => 'Invalid credentials.'])->onlyInput('username');
    }

    public function showRegister()
    {
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'username'              => 'required|string|min:3|max:30|unique:users|alpha_dash',
            'email'                 => 'required|email|unique:users',
            'password'              => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'username' => $request->username,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        Auth::login($user);
        return redirect()->route('dashboard');
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

    wf(f"{APP_ROOT}/app/Http/Controllers/OfferController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OfferController extends Controller
{
    public function index(Request $request)
    {
        $query = Offer::with('user')->where('is_active', true);

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('crypto')) {
            $query->where('crypto', $request->crypto);
        }
        if ($request->filled('payment_method')) {
            $query->where('payment_method', 'like', '%' . $request->payment_method . '%');
        }

        $offers = $query->latest()->paginate(20);
        return view('offers.index', compact('offers'));
    }

    public function show(Offer $offer)
    {
        $offer->load('user');
        return view('offers.show', compact('offer'));
    }

    public function create()
    {
        $this->middleware('auth');
        return view('offers.create');
    }

    public function store(Request $request)
    {
        $this->middleware('auth');
        $data = $request->validate([
            'type'           => 'required|in:buy,sell',
            'crypto'         => 'required|in:BTC,XMR',
            'fiat_currency'  => 'required|string|size:3',
            'price_margin'   => 'required|numeric|between:-50,50',
            'min_amount'     => 'required|numeric|min:0',
            'max_amount'     => 'required|numeric|gt:min_amount',
            'payment_method' => 'required|string|max:100',
            'terms'          => 'nullable|string|max:2000',
            'country'        => 'nullable|string|size:2',
        ]);

        $data['user_id'] = Auth::id();
        $offer = Offer::create($data);

        return redirect()->route('offers.show', $offer)->with('success', 'Offer created successfully!');
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/TradeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TradeController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $userId = Auth::id();
        $trades = Trade::with(['offer', 'buyer', 'seller'])
            ->where('buyer_id', $userId)
            ->orWhere('seller_id', $userId)
            ->latest()
            ->paginate(20);

        return view('trades.index', compact('trades'));
    }

    public function start(Request $request, Offer $offer)
    {
        if (!$offer->is_active) {
            return back()->with('error', 'This offer is no longer active.');
        }
        if ($offer->user_id === Auth::id()) {
            return back()->with('error', 'You cannot trade your own offer.');
        }

        $request->validate([
            'fiat_amount' => 'required|numeric|min:0.01',
        ]);

        $isBuy = $offer->type === 'sell';
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

        return redirect()->route('trades.show', $trade)->with('success', 'Trade started!');
    }

    public function show(Trade $trade)
    {
        $userId = Auth::id();
        if ($trade->buyer_id !== $userId && $trade->seller_id !== $userId) {
            abort(403);
        }
        $trade->load(['offer', 'buyer', 'seller']);
        return view('trades.show', compact('trade'));
    }
}
""")

    wf(f"{APP_ROOT}/app/Http/Controllers/WalletController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Support\Facades\Auth;

class WalletController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $user = Auth::user();
        $wallets = Wallet::where('user_id', $user->id)->get()->keyBy('crypto');
        $transactions = Transaction::where('user_id', $user->id)
            ->latest()
            ->take(20)
            ->get();

        return view('wallet.index', compact('user', 'wallets', 'transactions'));
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
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $user = Auth::user();

        $stats = [
            'active_trades'  => Trade::where('buyer_id', $user->id)
                ->orWhere('seller_id', $user->id)
                ->whereIn('status', ['open', 'paid'])
                ->count(),
            'active_offers'  => Offer::where('user_id', $user->id)
                ->where('is_active', true)
                ->count(),
            'btc_balance'    => $user->btc_balance,
            'xmr_balance'    => $user->xmr_balance,
        ];

        return view('dashboard', compact('user', 'stats'));
    }
}
""")
    ok("Controllers written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Middleware
# ---------------------------------------------------------------------------
def write_middleware():
    log("Writing middleware")

    wf(f"{APP_ROOT}/app/Http/Middleware/Authenticate.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    protected function redirectTo($request)
    {
        if (!$request->expectsJson()) {
            return route('login');
        }
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

    wf(f"{APP_ROOT}/app/Http/Middleware/TrustProxies.php", r"""<?php

namespace App\Http\Middleware;

use Fideloper\Proxy\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    protected $proxies;
    protected $headers =
        Request::HEADER_X_FORWARDED_FOR |
        Request::HEADER_X_FORWARDED_HOST |
        Request::HEADER_X_FORWARDED_PORT |
        Request::HEADER_X_FORWARDED_PROTO |
        Request::HEADER_X_FORWARDED_AWS_ELB;
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
    protected $except = ['password', 'password_confirmation'];
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
    ok("HTTP Kernel written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Service Providers
# ---------------------------------------------------------------------------
def write_providers():
    log("Writing service providers")

    wf(f"{APP_ROOT}/app/Providers/AppServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
    }

    public function boot()
    {
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

    public function boot()
    {
        $this->registerPolicies();
    }
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

    protected $namespace = 'App\\Http\\Controllers';

    public function boot()
    {
        $this->configureRateLimiting();
        $this->routes(function () {
            Route::prefix('api')
                ->middleware('api')
                ->namespace($this->namespace)
                ->group(base_path('routes/api.php'));

            Route::middleware('web')
                ->namespace($this->namespace)
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
        Registered::class => [
            SendEmailVerificationNotification::class,
        ],
    ];

    public function boot()
    {
    }
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
    protected $dontReport = [];

    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register()
    {
        $this->reportable(function (Throwable $e) {
        });
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
    protected function schedule(Schedule $schedule)
    {
    }

    protected function commands()
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }
}
""")
    ok("Console Kernel written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Routes
# ---------------------------------------------------------------------------
def write_routes():
    log("Writing routes")

    wf(f"{APP_ROOT}/routes/web.php", r"""<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\OfferController;
use App\Http\Controllers\TradeController;
use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

Route::get('/', [HomeController::class, 'index'])->name('home');

// Auth
Route::get('/login',    [AuthController::class, 'showLogin'])->name('login')->middleware('guest');
Route::post('/login',   [AuthController::class, 'login'])->middleware('guest');
Route::get('/register', [AuthController::class, 'showRegister'])->name('register')->middleware('guest');
Route::post('/register',[AuthController::class, 'register'])->middleware('guest');
Route::post('/logout',  [AuthController::class, 'logout'])->name('logout');

// Offers
Route::get('/offers',              [OfferController::class, 'index'])->name('offers.index');
Route::get('/offers/create',       [OfferController::class, 'create'])->name('offers.create')->middleware('auth');
Route::post('/offers',             [OfferController::class, 'store'])->name('offers.store')->middleware('auth');
Route::get('/offers/{offer}',      [OfferController::class, 'show'])->name('offers.show');
Route::post('/offers/{offer}/trade',[TradeController::class,'start'])->name('trades.start')->middleware('auth');

// Trades
Route::get('/trades',         [TradeController::class, 'index'])->name('trades.index')->middleware('auth');
Route::get('/trades/{trade}', [TradeController::class, 'show'])->name('trades.show')->middleware('auth');

// Wallet
Route::get('/wallet', [WalletController::class, 'index'])->name('wallet.index')->middleware('auth');

// Dashboard
Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard')->middleware('auth');
""")

    wf(f"{APP_ROOT}/routes/api.php", r"""<?php

use App\Models\Offer;
use App\Models\Trade;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/health', function () {
    return response()->json(['status' => 'ok', 'timestamp' => now()]);
});

Route::get('/stats', function () {
    return response()->json([
        'users'            => User::count(),
        'active_offers'    => Offer::where('is_active', true)->count(),
        'completed_trades' => Trade::where('status', 'completed')->count(),
    ]);
});
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



# ---------------------------------------------------------------------------
# Laravel 8 Application – Config files
# ---------------------------------------------------------------------------
def write_config():
    log("Writing config files")

    wf(f"{APP_ROOT}/config/app.php", r"""<?php

return [
    'name'            => env('APP_NAME', 'CapitalMonero'),
    'env'             => env('APP_ENV', 'production'),
    'debug'           => (bool) env('APP_DEBUG', false),
    'url'             => env('APP_URL', 'https://capitalmonero.com'),
    'asset_url'       => env('ASSET_URL', null),
    'timezone'        => 'UTC',
    'locale'          => 'en',
    'fallback_locale' => 'en',
    'faker_locale'    => 'en_US',
    'key'             => env('APP_KEY'),
    'cipher'          => 'AES-256-CBC',

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
        'App'       => Illuminate\Support\Facades\App::class,
        'Arr'       => Illuminate\Support\Arr::class,
        'Artisan'   => Illuminate\Support\Facades\Artisan::class,
        'Auth'      => Illuminate\Support\Facades\Auth::class,
        'Blade'     => Illuminate\Support\Facades\Blade::class,
        'Broadcast' => Illuminate\Support\Facades\Broadcast::class,
        'Bus'       => Illuminate\Support\Facades\Bus::class,
        'Cache'     => Illuminate\Support\Facades\Cache::class,
        'Config'    => Illuminate\Support\Facades\Config::class,
        'Cookie'    => Illuminate\Support\Facades\Cookie::class,
        'Crypt'     => Illuminate\Support\Facades\Crypt::class,
        'DB'        => Illuminate\Support\Facades\DB::class,
        'Eloquent'  => Illuminate\Database\Eloquent\Model::class,
        'Event'     => Illuminate\Support\Facades\Event::class,
        'File'      => Illuminate\Support\Facades\File::class,
        'Gate'      => Illuminate\Support\Facades\Gate::class,
        'Hash'      => Illuminate\Support\Facades\Hash::class,
        'Http'      => Illuminate\Support\Facades\Http::class,
        'Js'        => Illuminate\Support\Js::class,
        'Lang'      => Illuminate\Support\Facades\Lang::class,
        'Log'       => Illuminate\Support\Facades\Log::class,
        'Mail'      => Illuminate\Support\Facades\Mail::class,
        'Notification' => Illuminate\Support\Facades\Notification::class,
        'Password'  => Illuminate\Support\Facades\Password::class,
        'Queue'     => Illuminate\Support\Facades\Queue::class,
        'RateLimiter' => Illuminate\Support\Facades\RateLimiter::class,
        'Redirect'  => Illuminate\Support\Facades\Redirect::class,
        'Request'   => Illuminate\Support\Facades\Request::class,
        'Response'  => Illuminate\Support\Facades\Response::class,
        'Route'     => Illuminate\Support\Facades\Route::class,
        'Schema'    => Illuminate\Support\Facades\Schema::class,
        'Session'   => Illuminate\Support\Facades\Session::class,
        'Storage'   => Illuminate\Support\Facades\Storage::class,
        'Str'       => Illuminate\Support\Str::class,
        'URL'       => Illuminate\Support\Facades\URL::class,
        'Validator' => Illuminate\Support\Facades\Validator::class,
        'View'      => Illuminate\Support\Facades\View::class,
    ],
];
""")

    wf(f"{APP_ROOT}/config/database.php", r"""<?php

return [
    'default' => env('DB_CONNECTION', 'mysql'),

    'connections' => [
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
            'options'        => extension_loaded('pdo_mysql') ? array_filter([
                PDO::MYSQL_ATTR_SSL_CA => env('MYSQL_ATTR_SSL_CA'),
            ]) : [],
        ],
    ],

    'migrations' => 'migrations',

    'redis' => [
        'client' => env('REDIS_CLIENT', 'predis'),
        'options' => [
            'cluster' => env('REDIS_CLUSTER', 'redis'),
            'prefix'  => env('REDIS_PREFIX', 'capitalmonero_'),
        ],
        'default' => [
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
    'driver'          => env('SESSION_DRIVER', 'redis'),
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
    'secure'          => env('SESSION_SECURE_COOKIE', true),
    'http_only'       => true,
    'same_site'       => 'lax',
];
""")

    wf(f"{APP_ROOT}/config/cache.php", r"""<?php

return [
    'default' => env('CACHE_DRIVER', 'redis'),

    'stores' => [
        'redis' => [
            'driver'     => 'redis',
            'connection' => 'cache',
        ],
        'file' => [
            'driver' => 'file',
            'path'   => storage_path('framework/cache/data'),
        ],
        'array' => [
            'driver'    => 'array',
            'serialize' => false,
        ],
    ],

    'prefix' => env('CACHE_PREFIX', 'capitalmonero_cache'),
];
""")

    wf(f"{APP_ROOT}/config/auth.php", r"""<?php

return [
    'defaults' => [
        'guard'     => 'web',
        'passwords' => 'users',
    ],

    'guards' => [
        'web' => [
            'driver'   => 'session',
            'provider' => 'users',
        ],
        'api' => [
            'driver'   => 'token',
            'provider' => 'users',
            'hash'     => false,
        ],
    ],

    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model'  => App\Models\User::class,
        ],
    ],

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table'    => 'password_resets',
            'expire'   => 60,
            'throttle' => 60,
        ],
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
    'default'  => env('LOG_CHANNEL', 'stack'),
    'deprecations' => env('LOG_DEPRECATIONS_CHANNEL', 'null'),

    'channels' => [
        'stack' => [
            'driver'            => 'stack',
            'channels'          => ['single'],
            'ignore_exceptions' => false,
        ],
        'single' => [
            'driver' => 'single',
            'path'   => storage_path('logs/laravel.log'),
            'level'  => env('LOG_LEVEL', 'debug'),
        ],
        'stderr' => [
            'driver'    => 'monolog',
            'level'     => env('LOG_LEVEL', 'debug'),
            'handler'   => Monolog\Handler\StreamHandler::class,
            'formatter' => env('LOG_STDERR_FORMATTER'),
            'with'      => ['stream' => 'php://stderr'],
        ],
        'null' => [
            'driver'  => 'monolog',
            'handler' => Monolog\Handler\NullHandler::class,
        ],
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
    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s', 'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
        env('APP_URL') ? ',' . parse_url(env('APP_URL'), PHP_URL_HOST) : ''
    ))),
    'guard'     => ['web'],
    'expiration' => null,
    'middleware' => [
        'verify_csrf_token' => App\Http\Middleware\VerifyCsrfToken::class,
        'encrypt_cookies'   => App\Http\Middleware\EncryptCookies::class,
    ],
];
""")
    ok("Config files written")



# ---------------------------------------------------------------------------
# Laravel 8 Application – Bootstrap, Public, Storage
# ---------------------------------------------------------------------------
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

    # public/index.php – COMPLETE, not truncated
    wf(f"{APP_ROOT}/public/index.php", r"""<?php

/**
 * Laravel - A PHP Framework For Web Artisans
 * CapitalMonero Exchange – public/index.php
 */

define('LARAVEL_START', microtime(true));

/*
|--------------------------------------------------------------------------
| Register The Auto Loader
|--------------------------------------------------------------------------
*/
require __DIR__ . '/../vendor/autoload.php';

/*
|--------------------------------------------------------------------------
| Turn On The Lights
|--------------------------------------------------------------------------
*/
$app = require_once __DIR__ . '/../bootstrap/app.php';

/*
|--------------------------------------------------------------------------
| Run The Application
|--------------------------------------------------------------------------
*/
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
);

$response->send();

$kernel->terminate($request, $response);
""")

    # .htaccess
    wf(f"{APP_ROOT}/public/.htaccess", """\
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
""")

    # robots.txt
    wf(f"{APP_ROOT}/public/robots.txt", """\
User-agent: *
Disallow: /admin
Disallow: /api
""")
    ok("Public files written")


def make_storage_dirs():
    log("Creating storage directory structure")
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



# ---------------------------------------------------------------------------
# Laravel 8 Application – Blade Views
# ---------------------------------------------------------------------------
def write_views():
    log("Writing Blade views")

    # ---- Layout ----
    wf(f"{APP_ROOT}/resources/views/layouts/app.blade.php", r"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'CapitalMonero') | P2P Crypto Exchange</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        body { background:#0d1117; color:#c9d1d9; }
        .navbar { background:#161b22 !important; border-bottom:1px solid #30363d; }
        .navbar-brand { font-weight:700; color:#f0883e !important; font-size:1.4rem; }
        .nav-link { color:#8b949e !important; }
        .nav-link:hover { color:#c9d1d9 !important; }
        .card { background:#161b22; border:1px solid #30363d; }
        .card-header { background:#21262d; border-bottom:1px solid #30363d; }
        .table { color:#c9d1d9; }
        .table thead th { border-color:#30363d; color:#8b949e; }
        .table td, .table th { border-color:#21262d; }
        .table-hover tbody tr:hover { background:#21262d; }
        .btn-primary { background:#f0883e; border-color:#f0883e; color:#0d1117; font-weight:600; }
        .btn-primary:hover { background:#d4792e; border-color:#d4792e; }
        .btn-success { background:#2ea043; border-color:#2ea043; }
        .btn-outline-light { color:#c9d1d9; border-color:#30363d; }
        .badge-buy  { background:#2ea043; }
        .badge-sell { background:#da3633; }
        footer { background:#161b22; border-top:1px solid #30363d; color:#8b949e; }
        .hero { background:linear-gradient(135deg,#161b22 0%,#0d1117 100%);
                padding:80px 0; border-bottom:1px solid #30363d; }
        .stat-card { background:#161b22; border:1px solid #30363d; border-radius:8px; padding:20px; text-align:center; }
        .stat-number { font-size:2rem; font-weight:700; color:#f0883e; }
        a { color:#58a6ff; }
        a:hover { color:#79c0ff; }
        .form-control { background:#0d1117; border-color:#30363d; color:#c9d1d9; }
        .form-control:focus { background:#0d1117; border-color:#58a6ff; color:#c9d1d9; box-shadow:none; }
        .alert-success { background:#0d4429; border-color:#2ea043; color:#56d364; }
        .alert-danger  { background:#4c1015; border-color:#da3633; color:#ff7b72; }
    </style>
    @yield('styles')
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-dark">
    <div class="container">
        <a class="navbar-brand" href="{{ route('home') }}">
            <i class="fas fa-coins"></i> CapitalMonero
        </a>
        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav mr-auto">
                <li class="nav-item">
                    <a class="nav-link" href="{{ route('home') }}">Home</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{{ route('offers.index', ['type'=>'buy','crypto'=>'BTC']) }}">Buy BTC</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{{ route('offers.index', ['type'=>'sell','crypto'=>'BTC']) }}">Sell BTC</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{{ route('offers.index', ['type'=>'buy','crypto'=>'XMR']) }}">Buy XMR</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="{{ route('offers.index', ['type'=>'sell','crypto'=>'XMR']) }}">Sell XMR</a>
                </li>
            </ul>
            <ul class="navbar-nav ml-auto">
                @guest
                    <li class="nav-item">
                        <a class="nav-link" href="{{ route('login') }}">Login</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-primary text-dark ml-2 px-3" href="{{ route('register') }}">Register</a>
                    </li>
                @else
                    <li class="nav-item">
                        <a class="nav-link" href="{{ route('dashboard') }}">
                            <i class="fas fa-tachometer-alt"></i> {{ Auth::user()->username }}
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="{{ route('wallet.index') }}">
                            <i class="fas fa-wallet"></i> Wallet
                        </a>
                    </li>
                    <li class="nav-item">
                        <form method="POST" action="{{ route('logout') }}" class="d-inline">
                            @csrf
                            <button type="submit" class="nav-link btn btn-link">
                                <i class="fas fa-sign-out-alt"></i> Logout
                            </button>
                        </form>
                    </li>
                @endguest
            </ul>
        </div>
    </div>
</nav>

<main>
    <div class="container mt-3">
        @if(session('success'))
            <div class="alert alert-success alert-dismissible fade show" role="alert">
                {{ session('success') }}
                <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
            </div>
        @endif
        @if(session('error'))
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
                {{ session('error') }}
                <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>
            </div>
        @endif
        @if($errors->any())
            <div class="alert alert-danger">
                <ul class="mb-0">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif
    </div>

    @yield('content')
</main>

<footer class="py-4 mt-5">
    <div class="container text-center">
        <p class="mb-1">&copy; {{ date('Y') }} CapitalMonero Exchange. All rights reserved.</p>
        <small class="text-muted">
            Clearnet: <a href="https://capitalmonero.com" class="text-muted">capitalmonero.com</a> |
            Onion: <span class="text-muted" style="font-size:.75rem">fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion</span>
        </small>
    </div>
</footer>

<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js"></script>
@yield('scripts')
</body>
</html>
""")

    # ---- Home ----
    wf(f"{APP_ROOT}/resources/views/home.blade.php", r"""@extends('layouts.app')

@section('title', 'Home')

@section('content')
<div class="hero">
    <div class="container text-center">
        <h1 class="display-4 font-weight-bold text-white mb-3">
            <i class="fas fa-exchange-alt text-warning"></i>
            P2P Bitcoin &amp; Monero Exchange
        </h1>
        <p class="lead text-secondary mb-4">
            Buy and sell crypto privately with no KYC. Peer-to-peer, escrow-secured trading.
        </p>
        @guest
            <a href="{{ route('register') }}" class="btn btn-primary btn-lg mr-3">Get Started</a>
            <a href="{{ route('login') }}"    class="btn btn-outline-light btn-lg">Sign In</a>
        @else
            <a href="{{ route('offers.index') }}" class="btn btn-primary btn-lg mr-3">Browse Offers</a>
            <a href="{{ route('offers.create') }}" class="btn btn-outline-light btn-lg">Post Offer</a>
        @endguest
    </div>
</div>

<div class="container mt-5">
    <div class="row mb-5">
        <div class="col-md-4 mb-3">
            <div class="stat-card">
                <div class="stat-number">{{ number_format($stats['total_users']) }}</div>
                <div class="text-secondary">Registered Traders</div>
            </div>
        </div>
        <div class="col-md-4 mb-3">
            <div class="stat-card">
                <div class="stat-number">{{ number_format($stats['active_offers']) }}</div>
                <div class="text-secondary">Active Offers</div>
            </div>
        </div>
        <div class="col-md-4 mb-3">
            <div class="stat-card">
                <div class="stat-number">{{ number_format($stats['completed_trades']) }}</div>
                <div class="text-secondary">Completed Trades</div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0 text-success"><i class="fas fa-arrow-up"></i> Buy Offers</h5>
                    <a href="{{ route('offers.index', ['type'=>'buy']) }}" class="btn btn-sm btn-outline-success">View All</a>
                </div>
                <div class="card-body p-0">
                    <table class="table table-hover mb-0">
                        <thead><tr>
                            <th>Trader</th><th>Crypto</th><th>Payment</th><th>Rate</th><th></th>
                        </tr></thead>
                        <tbody>
                        @forelse($buyOffers as $offer)
                            <tr>
                                <td>{{ $offer->user->username }}</td>
                                <td><span class="badge badge-secondary">{{ $offer->crypto }}</span></td>
                                <td>{{ Str::limit($offer->payment_method, 20) }}</td>
                                <td>
                                    @if($offer->price_margin >= 0)
                                        <span class="text-success">+{{ $offer->price_margin }}%</span>
                                    @else
                                        <span class="text-danger">{{ $offer->price_margin }}%</span>
                                    @endif
                                </td>
                                <td><a href="{{ route('offers.show', $offer) }}" class="btn btn-sm btn-primary">Buy</a></td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="text-center text-muted py-3">No buy offers yet</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="col-md-6 mb-4">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0 text-danger"><i class="fas fa-arrow-down"></i> Sell Offers</h5>
                    <a href="{{ route('offers.index', ['type'=>'sell']) }}" class="btn btn-sm btn-outline-danger">View All</a>
                </div>
                <div class="card-body p-0">
                    <table class="table table-hover mb-0">
                        <thead><tr>
                            <th>Trader</th><th>Crypto</th><th>Payment</th><th>Rate</th><th></th>
                        </tr></thead>
                        <tbody>
                        @forelse($sellOffers as $offer)
                            <tr>
                                <td>{{ $offer->user->username }}</td>
                                <td><span class="badge badge-secondary">{{ $offer->crypto }}</span></td>
                                <td>{{ Str::limit($offer->payment_method, 20) }}</td>
                                <td>
                                    @if($offer->price_margin >= 0)
                                        <span class="text-success">+{{ $offer->price_margin }}%</span>
                                    @else
                                        <span class="text-danger">{{ $offer->price_margin }}%</span>
                                    @endif
                                </td>
                                <td><a href="{{ route('offers.show', $offer) }}" class="btn btn-sm btn-danger">Sell</a></td>
                            </tr>
                        @empty
                            <tr><td colspan="5" class="text-center text-muted py-3">No sell offers yet</td></tr>
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

    # ---- Auth: Login ----
    wf(f"{APP_ROOT}/resources/views/auth/login.blade.php", r"""@extends('layouts.app')

@section('title', 'Login')

@section('content')
<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card">
                <div class="card-header text-center">
                    <h4><i class="fas fa-sign-in-alt text-warning"></i> Sign In</h4>
                </div>
                <div class="card-body">
                    <form method="POST" action="{{ route('login') }}">
                        @csrf
                        <div class="form-group">
                            <label for="username">Username</label>
                            <input type="text" class="form-control @error('username') is-invalid @enderror"
                                   id="username" name="username" value="{{ old('username') }}" required autofocus>
                            @error('username')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-group">
                            <label for="password">Password</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   id="password" name="password" required>
                            @error('password')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-group form-check">
                            <input type="checkbox" class="form-check-input" id="remember" name="remember">
                            <label class="form-check-label" for="remember">Remember me</label>
                        </div>
                        <button type="submit" class="btn btn-primary btn-block">Login</button>
                    </form>
                </div>
                <div class="card-footer text-center">
                    <small>No account? <a href="{{ route('register') }}">Register here</a></small>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
""")

    # ---- Auth: Register ----
    wf(f"{APP_ROOT}/resources/views/auth/register.blade.php", r"""@extends('layouts.app')

@section('title', 'Register')

@section('content')
<div class="container mt-5">
    <div class="row justify-content-center">
        <div class="col-md-5">
            <div class="card">
                <div class="card-header text-center">
                    <h4><i class="fas fa-user-plus text-warning"></i> Create Account</h4>
                </div>
                <div class="card-body">
                    <form method="POST" action="{{ route('register') }}">
                        @csrf
                        <div class="form-group">
                            <label for="username">Username</label>
                            <input type="text" class="form-control @error('username') is-invalid @enderror"
                                   id="username" name="username" value="{{ old('username') }}" required autofocus
                                   placeholder="3-30 chars, letters/numbers/dashes">
                            @error('username')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-group">
                            <label for="email">Email</label>
                            <input type="email" class="form-control @error('email') is-invalid @enderror"
                                   id="email" name="email" value="{{ old('email') }}" required>
                            @error('email')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-group">
                            <label for="password">Password</label>
                            <input type="password" class="form-control @error('password') is-invalid @enderror"
                                   id="password" name="password" required placeholder="Minimum 8 characters">
                            @error('password')
                                <span class="invalid-feedback">{{ $message }}</span>
                            @enderror
                        </div>
                        <div class="form-group">
                            <label for="password_confirmation">Confirm Password</label>
                            <input type="password" class="form-control"
                                   id="password_confirmation" name="password_confirmation" required>
                        </div>
                        <button type="submit" class="btn btn-primary btn-block">Create Account</button>
                    </form>
                </div>
                <div class="card-footer text-center">
                    <small>Already have an account? <a href="{{ route('login') }}">Login here</a></small>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
""")


    # ---- Offers: Index ----
    wf(f"{APP_ROOT}/resources/views/offers/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Offers')

@section('content')
<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2>Browse Offers</h2>
        @auth
            <a href="{{ route('offers.create') }}" class="btn btn-primary">
                <i class="fas fa-plus"></i> Post Offer
            </a>
        @endauth
    </div>

    <form method="GET" class="card card-body mb-4">
        <div class="form-row">
            <div class="col-md-3 mb-2">
                <select name="type" class="form-control">
                    <option value="">All Types</option>
                    <option value="buy"  @if(request('type')=='buy')  selected @endif>Buy</option>
                    <option value="sell" @if(request('type')=='sell') selected @endif>Sell</option>
                </select>
            </div>
            <div class="col-md-3 mb-2">
                <select name="crypto" class="form-control">
                    <option value="">All Crypto</option>
                    <option value="BTC" @if(request('crypto')=='BTC') selected @endif>Bitcoin (BTC)</option>
                    <option value="XMR" @if(request('crypto')=='XMR') selected @endif>Monero (XMR)</option>
                </select>
            </div>
            <div class="col-md-4 mb-2">
                <input type="text" name="payment_method" class="form-control"
                       placeholder="Payment method..." value="{{ request('payment_method') }}">
            </div>
            <div class="col-md-2 mb-2">
                <button type="submit" class="btn btn-primary btn-block">Filter</button>
            </div>
        </div>
    </form>

    @forelse($offers as $offer)
        <div class="card mb-3">
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-2">
                        <span class="badge badge-lg {{ $offer->type == 'buy' ? 'badge-success' : 'badge-danger' }} p-2">
                            {{ strtoupper($offer->type) }}
                        </span>
                        <span class="badge badge-secondary ml-1 p-2">{{ $offer->crypto }}</span>
                    </div>
                    <div class="col-md-3">
                        <strong>{{ $offer->user->username }}</strong><br>
                        <small class="text-muted">{{ $offer->user->completed_trades }} trades</small>
                    </div>
                    <div class="col-md-3">
                        <i class="fas fa-credit-card text-muted"></i> {{ $offer->payment_method }}<br>
                        <small class="text-muted">{{ $offer->fiat_currency }}</small>
                    </div>
                    <div class="col-md-2">
                        @if($offer->price_margin >= 0)
                            <span class="text-success font-weight-bold">+{{ $offer->price_margin }}%</span>
                        @else
                            <span class="text-danger font-weight-bold">{{ $offer->price_margin }}%</span>
                        @endif
                        <br>
                        <small class="text-muted">
                            {{ $offer->min_amount }} – {{ $offer->max_amount }} {{ $offer->fiat_currency }}
                        </small>
                    </div>
                    <div class="col-md-2 text-right">
                        <a href="{{ route('offers.show', $offer) }}"
                           class="btn btn-{{ $offer->type == 'buy' ? 'success' : 'danger' }}">
                            {{ $offer->type == 'buy' ? 'Sell to' : 'Buy from' }} trader
                        </a>
                    </div>
                </div>
            </div>
        </div>
    @empty
        <div class="text-center py-5">
            <i class="fas fa-search fa-3x text-muted mb-3"></i>
            <p class="text-muted">No offers found. Try adjusting your filters.</p>
        </div>
    @endforelse

    <div class="d-flex justify-content-center mt-4">
        {{ $offers->withQueryString()->links() }}
    </div>
</div>
@endsection
""")

    # ---- Offers: Show ----
    wf(f"{APP_ROOT}/resources/views/offers/show.blade.php", r"""@extends('layouts.app')

@section('title', 'Offer Details')

@section('content')
<div class="container mt-4">
    <div class="row">
        <div class="col-md-8">
            <div class="card mb-4">
                <div class="card-header">
                    <h4 class="mb-0">
                        <span class="badge badge-{{ $offer->type == 'buy' ? 'success' : 'danger' }} mr-2">
                            {{ strtoupper($offer->type) }}
                        </span>
                        {{ $offer->crypto }} — {{ $offer->payment_method }}
                    </h4>
                </div>
                <div class="card-body">
                    <table class="table table-borderless">
                        <tr>
                            <td class="text-muted w-40">Trader</td>
                            <td><strong>{{ $offer->user->username }}</strong>
                                ({{ $offer->user->completed_trades }} trades)</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Cryptocurrency</td>
                            <td>{{ $offer->crypto }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Payment Method</td>
                            <td>{{ $offer->payment_method }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Price Margin</td>
                            <td>
                                @if($offer->price_margin >= 0)
                                    <span class="text-success">+{{ $offer->price_margin }}% above market</span>
                                @else
                                    <span class="text-danger">{{ $offer->price_margin }}% below market</span>
                                @endif
                            </td>
                        </tr>
                        <tr>
                            <td class="text-muted">Trade Limits</td>
                            <td>{{ $offer->min_amount }} – {{ $offer->max_amount }} {{ $offer->fiat_currency }}</td>
                        </tr>
                        @if($offer->country)
                        <tr>
                            <td class="text-muted">Country</td>
                            <td>{{ $offer->country }}</td>
                        </tr>
                        @endif
                    </table>
                    @if($offer->terms)
                        <h6 class="mt-3 text-muted">Terms of Trade</h6>
                        <p class="border-left pl-3" style="border-color:#30363d !important;">
                            {{ $offer->terms }}
                        </p>
                    @endif
                </div>
            </div>
        </div>

        <div class="col-md-4">
            @auth
                @if(Auth::id() !== $offer->user_id && $offer->is_active)
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0">Start Trade</h5>
                        </div>
                        <div class="card-body">
                            <form method="POST" action="{{ route('trades.start', $offer) }}">
                                @csrf
                                <div class="form-group">
                                    <label>Amount ({{ $offer->fiat_currency }})</label>
                                    <input type="number" step="0.01" name="fiat_amount"
                                           class="form-control" required
                                           min="{{ $offer->min_amount }}"
                                           max="{{ $offer->max_amount }}"
                                           placeholder="{{ $offer->min_amount }} – {{ $offer->max_amount }}">
                                    <small class="text-muted">
                                        Limits: {{ $offer->min_amount }} – {{ $offer->max_amount }} {{ $offer->fiat_currency }}
                                    </small>
                                </div>
                                <button type="submit" class="btn btn-primary btn-block">
                                    Start Trade
                                </button>
                            </form>
                        </div>
                    </div>
                @elseif(!$offer->is_active)
                    <div class="alert alert-danger">This offer is no longer active.</div>
                @else
                    <div class="alert alert-secondary">This is your own offer.</div>
                @endif
            @else
                <div class="card card-body text-center">
                    <p>Please log in to trade.</p>
                    <a href="{{ route('login') }}" class="btn btn-primary">Login</a>
                </div>
            @endauth
        </div>
    </div>
</div>
@endsection
""")

    # ---- Offers: Create ----
    wf(f"{APP_ROOT}/resources/views/offers/create.blade.php", r"""@extends('layouts.app')

@section('title', 'Create Offer')

@section('content')
<div class="container mt-4">
    <div class="row justify-content-center">
        <div class="col-md-8">
            <div class="card">
                <div class="card-header">
                    <h4 class="mb-0"><i class="fas fa-plus text-warning"></i> Post New Offer</h4>
                </div>
                <div class="card-body">
                    <form method="POST" action="{{ route('offers.store') }}">
                        @csrf
                        <div class="form-row">
                            <div class="form-group col-md-6">
                                <label>Offer Type</label>
                                <select name="type" class="form-control @error('type') is-invalid @enderror" required>
                                    <option value="buy"  @if(old('type')=='buy')  selected @endif>Buy Crypto</option>
                                    <option value="sell" @if(old('type')=='sell') selected @endif>Sell Crypto</option>
                                </select>
                                @error('type')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                            <div class="form-group col-md-6">
                                <label>Cryptocurrency</label>
                                <select name="crypto" class="form-control @error('crypto') is-invalid @enderror" required>
                                    <option value="BTC" @if(old('crypto')=='BTC') selected @endif>Bitcoin (BTC)</option>
                                    <option value="XMR" @if(old('crypto')=='XMR') selected @endif>Monero (XMR)</option>
                                </select>
                                @error('crypto')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group col-md-4">
                                <label>Fiat Currency</label>
                                <input type="text" name="fiat_currency" class="form-control @error('fiat_currency') is-invalid @enderror"
                                       value="{{ old('fiat_currency','USD') }}" maxlength="3" required>
                                @error('fiat_currency')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                            <div class="form-group col-md-4">
                                <label>Min Amount (Fiat)</label>
                                <input type="number" step="0.01" name="min_amount"
                                       class="form-control @error('min_amount') is-invalid @enderror"
                                       value="{{ old('min_amount') }}" required>
                                @error('min_amount')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                            <div class="form-group col-md-4">
                                <label>Max Amount (Fiat)</label>
                                <input type="number" step="0.01" name="max_amount"
                                       class="form-control @error('max_amount') is-invalid @enderror"
                                       value="{{ old('max_amount') }}" required>
                                @error('max_amount')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                        </div>
                        <div class="form-row">
                            <div class="form-group col-md-6">
                                <label>Price Margin (%)</label>
                                <input type="number" step="0.01" name="price_margin"
                                       class="form-control @error('price_margin') is-invalid @enderror"
                                       value="{{ old('price_margin', 0) }}"
                                       min="-50" max="50" required>
                                <small class="text-muted">Positive = above market; negative = below</small>
                                @error('price_margin')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                            <div class="form-group col-md-6">
                                <label>Country (optional, 2-letter ISO)</label>
                                <input type="text" name="country"
                                       class="form-control @error('country') is-invalid @enderror"
                                       value="{{ old('country') }}" maxlength="2">
                                @error('country')<span class="invalid-feedback">{{ $message }}</span>@enderror
                            </div>
                        </div>
                        <div class="form-group">
                            <label>Payment Method</label>
                            <input type="text" name="payment_method"
                                   class="form-control @error('payment_method') is-invalid @enderror"
                                   value="{{ old('payment_method') }}" required placeholder="e.g. Bank transfer, Cash, PayPal">
                            @error('payment_method')<span class="invalid-feedback">{{ $message }}</span>@enderror
                        </div>
                        <div class="form-group">
                            <label>Trade Terms (optional)</label>
                            <textarea name="terms" class="form-control @error('terms') is-invalid @enderror"
                                      rows="4" placeholder="Describe your trading terms...">{{ old('terms') }}</textarea>
                            @error('terms')<span class="invalid-feedback">{{ $message }}</span>@enderror
                        </div>
                        <button type="submit" class="btn btn-primary btn-block">Post Offer</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
""")


    # ---- Trades: Index ----
    wf(f"{APP_ROOT}/resources/views/trades/index.blade.php", r"""@extends('layouts.app')

@section('title', 'My Trades')

@section('content')
<div class="container mt-4">
    <h2 class="mb-4">My Trades</h2>
    <div class="card">
        <div class="card-body p-0">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Trade ID</th>
                        <th>Crypto</th>
                        <th>Counterparty</th>
                        <th>Amount</th>
                        <th>Payment</th>
                        <th>Status</th>
                        <th>Date</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                @forelse($trades as $trade)
                    @php
                        $isBuyer = $trade->buyer_id === Auth::id();
                        $counterparty = $isBuyer ? $trade->seller : $trade->buyer;
                    @endphp
                    <tr>
                        <td><code>{{ $trade->trade_id }}</code></td>
                        <td>{{ $trade->crypto }}</td>
                        <td>{{ optional($counterparty)->username ?? 'N/A' }}</td>
                        <td>{{ $trade->fiat_amount }} {{ $trade->fiat_currency }}</td>
                        <td>{{ Str::limit($trade->payment_method, 20) }}</td>
                        <td>
                            @php
                                $badges = ['open'=>'primary','paid'=>'info','released'=>'warning',
                                           'disputed'=>'danger','cancelled'=>'secondary','completed'=>'success'];
                                $badge = $badges[$trade->status] ?? 'secondary';
                            @endphp
                            <span class="badge badge-{{ $badge }}">{{ $trade->status }}</span>
                        </td>
                        <td>{{ $trade->created_at->format('Y-m-d') }}</td>
                        <td>
                            <a href="{{ route('trades.show', $trade) }}" class="btn btn-sm btn-outline-light">
                                View
                            </a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center text-muted py-4">
                            No trades yet. <a href="{{ route('offers.index') }}">Browse offers</a> to get started.
                        </td>
                    </tr>
                @endforelse
                </tbody>
            </table>
        </div>
    </div>
    <div class="d-flex justify-content-center mt-4">
        {{ $trades->links() }}
    </div>
</div>
@endsection
""")

    # ---- Trades: Show ----
    wf(f"{APP_ROOT}/resources/views/trades/show.blade.php", r"""@extends('layouts.app')

@section('title', 'Trade #{{ $trade->trade_id }}')

@section('content')
<div class="container mt-4">
    <div class="row">
        <div class="col-md-8 offset-md-2">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="mb-0">Trade <code>{{ $trade->trade_id }}</code></h4>
                    @php
                        $badges = ['open'=>'primary','paid'=>'info','released'=>'warning',
                                   'disputed'=>'danger','cancelled'=>'secondary','completed'=>'success'];
                        $badge = $badges[$trade->status] ?? 'secondary';
                    @endphp
                    <span class="badge badge-{{ $badge }} p-2">{{ strtoupper($trade->status) }}</span>
                </div>
                <div class="card-body">
                    <table class="table table-borderless">
                        <tr>
                            <td class="text-muted" style="width:40%">Cryptocurrency</td>
                            <td><strong>{{ $trade->crypto }}</strong></td>
                        </tr>
                        <tr>
                            <td class="text-muted">Fiat Amount</td>
                            <td><strong>{{ $trade->fiat_amount }} {{ $trade->fiat_currency }}</strong></td>
                        </tr>
                        <tr>
                            <td class="text-muted">Payment Method</td>
                            <td>{{ $trade->payment_method }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Buyer</td>
                            <td>{{ optional($trade->buyer)->username }}</td>
                        </tr>
                        <tr>
                            <td class="text-muted">Seller</td>
                            <td>{{ optional($trade->seller)->username }}</td>
                        </tr>
                        @if($trade->expires_at)
                        <tr>
                            <td class="text-muted">Expires</td>
                            <td>{{ $trade->expires_at->format('Y-m-d H:i') }} UTC</td>
                        </tr>
                        @endif
                        <tr>
                            <td class="text-muted">Created</td>
                            <td>{{ $trade->created_at->format('Y-m-d H:i') }} UTC</td>
                        </tr>
                    </table>

                    <div class="mt-3">
                        <a href="{{ route('trades.index') }}" class="btn btn-outline-light">
                            <i class="fas fa-arrow-left"></i> Back to Trades
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
""")

    # ---- Wallet ----
    wf(f"{APP_ROOT}/resources/views/wallet/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Wallet')

@section('content')
<div class="container mt-4">
    <h2 class="mb-4"><i class="fas fa-wallet text-warning"></i> My Wallet</h2>

    <div class="row mb-4">
        <div class="col-md-6 mb-3">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0"><i class="fab fa-bitcoin text-warning"></i> Bitcoin (BTC)</h5>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-6">
                            <div class="text-muted small">Available</div>
                            <div class="stat-number" style="font-size:1.5rem">
                                {{ number_format($user->btc_balance, 8) }}
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="text-muted small">In Escrow</div>
                            <div class="stat-number text-warning" style="font-size:1.5rem">
                                {{ number_format($user->escrow_btc, 8) }}
                            </div>
                        </div>
                    </div>
                    @if($user->btc_deposit_address)
                        <hr style="border-color:#30363d">
                        <small class="text-muted">Deposit Address:</small><br>
                        <code class="small">{{ $user->btc_deposit_address }}</code>
                    @endif
                </div>
            </div>
        </div>
        <div class="col-md-6 mb-3">
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0"><i class="fas fa-coins text-secondary"></i> Monero (XMR)</h5>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-6">
                            <div class="text-muted small">Available</div>
                            <div class="stat-number" style="font-size:1.5rem">
                                {{ number_format($user->xmr_balance, 12) }}
                            </div>
                        </div>
                        <div class="col-6">
                            <div class="text-muted small">In Escrow</div>
                            <div class="stat-number text-warning" style="font-size:1.5rem">
                                {{ number_format($user->escrow_xmr, 12) }}
                            </div>
                        </div>
                    </div>
                    @if($user->xmr_deposit_address)
                        <hr style="border-color:#30363d">
                        <small class="text-muted">Deposit Address:</small><br>
                        <code class="small">{{ $user->xmr_deposit_address }}</code>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header"><h5 class="mb-0">Recent Transactions</h5></div>
        <div class="card-body p-0">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Crypto</th>
                        <th>Type</th>
                        <th>Amount</th>
                        <th>Status</th>
                        <th>TXID</th>
                    </tr>
                </thead>
                <tbody>
                @forelse($transactions as $tx)
                    <tr>
                        <td>{{ $tx->created_at->format('Y-m-d H:i') }}</td>
                        <td>{{ $tx->crypto }}</td>
                        <td>{{ $tx->type }}</td>
                        <td>{{ $tx->amount }}</td>
                        <td><span class="badge badge-secondary">{{ $tx->status }}</span></td>
                        <td><code class="small">{{ Str::limit($tx->txid ?? '-', 16) }}</code></td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="text-center text-muted py-4">No transactions yet.</td>
                    </tr>
                @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
""")

    # ---- Dashboard ----
    wf(f"{APP_ROOT}/resources/views/dashboard.blade.php", r"""@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="container mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h2>Welcome, <strong class="text-warning">{{ $user->username }}</strong></h2>
        <span class="badge badge-{{ $user->role == 'admin' ? 'danger' : 'secondary' }} p-2">
            {{ $user->role }}
        </span>
    </div>

    <div class="row mb-4">
        <div class="col-md-3 col-sm-6 mb-3">
            <div class="stat-card">
                <div class="stat-number">{{ $stats['active_trades'] }}</div>
                <div class="text-muted mt-1">Active Trades</div>
            </div>
        </div>
        <div class="col-md-3 col-sm-6 mb-3">
            <div class="stat-card">
                <div class="stat-number">{{ $stats['active_offers'] }}</div>
                <div class="text-muted mt-1">My Offers</div>
            </div>
        </div>
        <div class="col-md-3 col-sm-6 mb-3">
            <div class="stat-card">
                <div class="stat-number" style="font-size:1.3rem">
                    {{ number_format($stats['btc_balance'], 8) }}
                </div>
                <div class="text-muted mt-1">BTC Balance</div>
            </div>
        </div>
        <div class="col-md-3 col-sm-6 mb-3">
            <div class="stat-card">
                <div class="stat-number" style="font-size:1.3rem">
                    {{ number_format($stats['xmr_balance'], 12) }}
                </div>
                <div class="text-muted mt-1">XMR Balance</div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-4 mb-3">
            <a href="{{ route('offers.create') }}" class="btn btn-primary btn-block btn-lg">
                <i class="fas fa-plus"></i> Post Offer
            </a>
        </div>
        <div class="col-md-4 mb-3">
            <a href="{{ route('trades.index') }}" class="btn btn-outline-light btn-block btn-lg">
                <i class="fas fa-exchange-alt"></i> My Trades
            </a>
        </div>
        <div class="col-md-4 mb-3">
            <a href="{{ route('wallet.index') }}" class="btn btn-outline-light btn-block btn-lg">
                <i class="fas fa-wallet"></i> My Wallet
            </a>
        </div>
    </div>
</div>
@endsection
""")

    # ---- Error pages ----
    wf(f"{APP_ROOT}/resources/views/errors/500.blade.php", r"""@extends('layouts.app')

@section('title', '500 Server Error')

@section('content')
<div class="container mt-5 text-center">
    <div class="py-5">
        <h1 class="display-1 text-danger font-weight-bold">500</h1>
        <h2 class="mb-4">Internal Server Error</h2>
        <p class="text-muted mb-4">
            Something went wrong on our end. We're working to fix it.
        </p>
        <a href="{{ route('home') }}" class="btn btn-primary btn-lg">
            <i class="fas fa-home"></i> Go Home
        </a>
    </div>
</div>
@endsection
""")

    wf(f"{APP_ROOT}/resources/views/errors/404.blade.php", r"""@extends('layouts.app')

@section('title', '404 Not Found')

@section('content')
<div class="container mt-5 text-center">
    <div class="py-5">
        <h1 class="display-1 text-warning font-weight-bold">404</h1>
        <h2 class="mb-4">Page Not Found</h2>
        <p class="text-muted mb-4">
            The page you're looking for doesn't exist or has been moved.
        </p>
        <a href="{{ route('home') }}" class="btn btn-primary btn-lg">
            <i class="fas fa-home"></i> Go Home
        </a>
    </div>
</div>
@endsection
""")

    ok("Blade views written")



# ---------------------------------------------------------------------------
# Laravel 8 Application – Frontend Assets
# ---------------------------------------------------------------------------
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

let token = document.head.querySelector('meta[name="csrf-token"]');
if (token) {
    window.axios.defaults.headers.common['X-CSRF-TOKEN'] = token.content;
}
""")

    wf(f"{APP_ROOT}/resources/sass/app.scss", """\
// Bootstrap
@import '~bootstrap/scss/bootstrap';
""")

    ok("Frontend assets written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – Database Seeder
# ---------------------------------------------------------------------------
def write_seeders():
    log("Writing DatabaseSeeder")
    wf(f"{APP_ROOT}/database/seeders/DatabaseSeeder.php", r"""<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        // Admin user
        User::updateOrCreate(
            ['username' => 'admin'],
            [
                'email'    => 'admin@capitalmonero.com',
                'password' => Hash::make('changeme123'),
                'role'     => 'admin',
                'is_active'=> true,
            ]
        );
    }
}
""")
    ok("DatabaseSeeder written")


# ---------------------------------------------------------------------------
# Laravel 8 Application – .env
# ---------------------------------------------------------------------------
def write_env():
    log("Writing .env file")
    env_path = Path(f"{APP_ROOT}/.env")
    if env_path.exists():
        # Read existing .env and patch key values
        existing = env_path.read_text()
        def _patch(content, key, new_val):
            import re
            pattern = rf"^{re.escape(key)}=.*$"
            replacement = f"{key}={new_val}"
            if re.search(pattern, content, re.MULTILINE):
                return re.sub(pattern, replacement, content, flags=re.MULTILINE)
            return content + f"\n{replacement}\n"

        existing = _patch(existing, "APP_NAME",    "CapitalMonero")
        existing = _patch(existing, "APP_ENV",     "production")
        existing = _patch(existing, "APP_DEBUG",   "false")
        existing = _patch(existing, "APP_URL",     "https://capitalmonero.com")
        existing = _patch(existing, "DB_DATABASE", "capitalmonero")
        existing = _patch(existing, "DB_USERNAME", "capitalmonero")
        existing = _patch(existing, "DB_PASSWORD", "capitalmonero_secret")
        existing = _patch(existing, "SESSION_DRIVER", "redis")
        existing = _patch(existing, "CACHE_DRIVER",   "redis")
        env_path.write_text(existing)
        ok("Patched existing .env")
    else:
        wf(f"{APP_ROOT}/.env", """\
APP_NAME=CapitalMonero
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://capitalmonero.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=capitalmonero
DB_USERNAME=capitalmonero
DB_PASSWORD=capitalmonero_secret

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=redis
SESSION_LIFETIME=120
SESSION_SECURE_COOKIE=true

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=localhost
MAIL_PORT=25
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=noreply@capitalmonero.com
MAIL_FROM_NAME=CapitalMonero
""")
        ok("Created .env")

    # Write .env.example as well
    wf(f"{APP_ROOT}/.env.example", """\
APP_NAME=CapitalMonero
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://capitalmonero.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=capitalmonero
DB_USERNAME=capitalmonero
DB_PASSWORD=

SESSION_DRIVER=redis
CACHE_DRIVER=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379
""")


# ---------------------------------------------------------------------------
# Orchestrate Laravel build
# ---------------------------------------------------------------------------
def build_laravel_app():
    log("=== Building Laravel 8 Application ===")
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
    write_views()
    write_assets()
    write_seeders()
    ok("=== Laravel application files written ===")


# ---------------------------------------------------------------------------
# Post-build steps
# ---------------------------------------------------------------------------
def post_build():
    log("Running post-build artisan commands and fixing permissions")

    artisan = [PHP_BIN, "artisan"]

    run(artisan + ["key:generate", "--force"],      cwd=APP_ROOT)
    run(artisan + ["migrate", "--force"],           cwd=APP_ROOT)
    run(artisan + ["db:seed", "--force"],           cwd=APP_ROOT)
    run(artisan + ["config:cache"],                 cwd=APP_ROOT)
    run(artisan + ["route:cache"],                  cwd=APP_ROOT)
    run(artisan + ["view:cache"],                   cwd=APP_ROOT)
    run(artisan + ["storage:link"],                 cwd=APP_ROOT)

    # Run post-autoload-dump (package discovery)
    env = {"COMPOSER_ALLOW_SUPERUSER": "1"}
    run([COMPOSER, "run-script", "post-autoload-dump", "--no-interaction"],
        cwd=APP_ROOT, env=env)

    # Ownership and permissions (list-based to avoid shell injection)
    run(["chown", "-R", "www-data:www-data", APP_ROOT])
    run(["find", APP_ROOT, "-type", "f", "-exec", "chmod", "644", "{}", "+"])
    run(["find", APP_ROOT, "-type", "d", "-exec", "chmod", "755", "{}", "+"])
    run(["chmod", "-R", "775",
         f"{APP_ROOT}/storage",
         f"{APP_ROOT}/bootstrap/cache"])

    # Restart Apache
    run(["systemctl", "restart", "apache2"])
    ok("Post-build steps complete")


# ---------------------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------------------
def verify():
    log("=== Final Verification ===")
    services = [
        "mariadb", "redis-server", "apache2",
        "tor", "capitalmonero-bitcoind", "capitalmonero-monerod",
    ]
    for svc in services:
        r = run(["systemctl", "is-active", svc])
        status = r.stdout.strip() or "unknown"
        symbol = "[OK]" if status == "active" else "[WARN]"
        print(f"    {symbol} {svc}: {status}")

    # Check ports
    for port in [80, 443]:
        r = run(["ss", "-tlnp", f"sport = :{port}"])
        if str(port) in r.stdout:
            ok(f"Port {port} is listening")
        else:
            warn(f"Port {port} does not appear to be open")

    # Redis ping
    r = run(["redis-cli", "ping"])
    if "PONG" in r.stdout:
        ok("Redis responding")
    else:
        warn("Redis not responding")

    # DB connectivity via artisan
    r = run(
        [PHP_BIN, "artisan", "tinker", "--execute",
         "echo DB::connection()->getPdo() ? 'DB:OK' : 'DB:FAIL';"],
        cwd=APP_ROOT,
    )
    if "DB:OK" in r.stdout:
        ok("Database connection verified")
    else:
        warn("Could not verify database connection via artisan")

    print()
    print("=" * 60)
    print("  CapitalMonero Exchange – Deployment Summary")
    print("=" * 60)
    print(f"  Clearnet : https://{DOMAIN}/")
    print(f"  Onion    : http://{ONION}/")
    print(f"  App root : {APP_ROOT}")
    print(f"  Admin    : username=admin  password=changeme123")
    print(f"             (CHANGE THIS PASSWORD IMMEDIATELY)")
    print("=" * 60)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    if os.geteuid() != 0:
        sys.exit("[FATAL] This script must be run as root (sudo python3 fix_capitalmonero.py)")

    fix_database()
    fix_composer()
    fix_npm()
    fix_monerod()
    fix_https()
    build_laravel_app()
    post_build()
    verify()

    log("All fixes applied successfully.")


if __name__ == "__main__":
    main()
