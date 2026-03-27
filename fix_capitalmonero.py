#!/usr/bin/env python3
"""
fix_capitalmonero.py — Full build/repair script for the CapitalMonero Laravel 8 application.
Run as: sudo python3 fix_capitalmonero.py
"""

import os
import sys
import subprocess
import secrets
import string
import json
import time
import shutil
import tempfile


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

APP_DIR = "/var/www/capitalmonero"
DOMAIN  = "capitalmonero.local"
TOR_ONION = ""            # fill in if known, e.g. "abc123.onion"
DB_NAME = "capitalmonero"
DB_USER = "capitalmonero"


def run(cmd, cwd=None, check=True, capture=False, env=None):
    """Run a shell command, printing it first."""
    print(f"  $ {cmd}")
    kwargs = dict(cwd=cwd or APP_DIR, shell=True, check=check)
    if capture:
        kwargs["capture_output"] = True
        kwargs["text"] = True
    if env:
        kwargs["env"] = env
    return subprocess.run(cmd, **kwargs)


def run_ok(cmd, cwd=None):
    """Run a command, return True on success, False on failure (never raises)."""
    try:
        run(cmd, cwd=cwd, check=True)
        return True
    except subprocess.CalledProcessError:
        return False


def gen_password(length=32):
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def write_file(path, content, mode=0o644):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as fh:
        fh.write(content)
    os.chmod(path, mode)
    print(f"  wrote {path}")


def write_raw(path, content, mode=0o644):
    """Write binary/raw content (bytes or str)."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if isinstance(content, str):
        content = content.encode()
    with open(path, "wb") as fh:
        fh.write(content)
    os.chmod(path, mode)
    print(f"  wrote {path}")


def mkdir(path, mode=0o755):
    os.makedirs(path, exist_ok=True)
    os.chmod(path, mode)


# ---------------------------------------------------------------------------
# Phase 1 — Database
# ---------------------------------------------------------------------------

def phase1_database():
    print("\n=== Phase 1: Database ===")

    # Ensure MariaDB is running
    if not run_ok("systemctl is-active --quiet mariadb"):
        run("systemctl start mariadb")
        time.sleep(2)

    db_password = gen_password()

    sql = f"""
DROP DATABASE IF EXISTS `{DB_NAME}`;
CREATE DATABASE `{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '{DB_USER}'@'localhost';
CREATE USER '{DB_USER}'@'localhost' IDENTIFIED BY '{db_password}';
GRANT ALL PRIVILEGES ON `{DB_NAME}`.* TO '{DB_USER}'@'localhost';
FLUSH PRIVILEGES;
"""
    sql_file = tempfile.NamedTemporaryFile(mode="w", suffix=".sql", delete=False)
    sql_file.write(sql)
    sql_file.close()

    try:
        run(f"mysql -u root < {sql_file.name}")
    finally:
        os.unlink(sql_file.name)

    # .env
    import base64 as _base64
    app_key = "base64:" + _base64.b64encode(secrets.token_bytes(32)).decode()
    env_content = f"""APP_NAME=CapitalMonero
APP_ENV=production
APP_KEY={app_key}
APP_DEBUG=false
APP_URL=https://{DOMAIN}

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE={DB_NAME}
DB_USERNAME={DB_USER}
DB_PASSWORD={db_password}

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@{DOMAIN}"
MAIL_FROM_NAME="${{APP_NAME}}"
"""
    write_file(f"{APP_DIR}/.env", env_content)

    # credentials.json
    creds = {"db_name": DB_NAME, "db_user": DB_USER, "db_password": db_password}
    write_file(
        f"{APP_DIR}/credentials.json",
        json.dumps(creds, indent=2) + "\n",
        mode=0o600,
    )

    print("  Phase 1 complete.")
    return db_password


# ---------------------------------------------------------------------------
# Phase 2 — Composer
# ---------------------------------------------------------------------------

def phase2_composer():
    print("\n=== Phase 2: Composer ===")

    composer_json = {
        "name": "capitalmonero/app",
        "type": "project",
        "description": "CapitalMonero P2P exchange",
        "keywords": ["laravel", "framework"],
        "license": "MIT",
        "require": {
            "php": "^7.3|^8.0",
            "fruitcake/laravel-cors": "^2.0",
            "guzzlehttp/guzzle": "^7.0.1",
            "laravel/framework": "^8.75",
            "laravel/sanctum": "^2.11",
            "laravel/tinker": "^2.5",
            "predis/predis": "^1.1",
        },
        "require-dev": {
            "facade/ignition": "^2.5",
            "fakerphp/faker": "^1.9.1",
            "laravel/sail": "^1.0.1",
            "mockery/mockery": "^1.4.4",
            "nunomaduro/collision": "^5.10",
            "phpunit/phpunit": "^9.5.10",
        },
        "autoload": {
            "psr-4": {"App\\": "app/", "Database\\Factories\\": "database/factories/", "Database\\Seeders\\": "database/seeders/"},
        },
        "autoload-dev": {
            "psr-4": {"Tests\\": "tests/"},
        },
        "scripts": {
            "post-autoload-dump": [
                "Illuminate\\Foundation\\ComposerScripts::postAutoloadDump",
                "@php artisan package:discover --ansi",
            ],
            "post-update-cmd": ["@php artisan vendor:publish --tag=laravel-assets --ansi --force"],
            "post-root-package-install": ["@php -r \"file_exists('.env') || copy('.env.example', '.env');\""],
            "post-create-project-cmd": ["@php artisan key:generate --ansi"],
        },
        "extra": {"laravel": {"dont-discover": []}},
        "config": {
            "optimize-autoloader": True,
            "preferred-install": "dist",
            "sort-packages": True,
            "allow-plugins": {"pestphp/pest-plugin": True, "php-http/discovery": True},
            "audit": {"abandoned": "report", "block-insecure": False},
        },
        "minimum-stability": "dev",
        "prefer-stable": True,
    }

    write_file(
        f"{APP_DIR}/composer.json",
        json.dumps(composer_json, indent=4) + "\n",
    )

    # Remove old vendor / lock
    for path in [f"{APP_DIR}/vendor", f"{APP_DIR}/composer.lock"]:
        if os.path.isdir(path):
            shutil.rmtree(path)
            print(f"  removed dir {path}")
        elif os.path.isfile(path):
            os.unlink(path)
            print(f"  removed {path}")

    env = os.environ.copy()
    env["COMPOSER_ALLOW_SUPERUSER"] = "1"

    base_cmd = "composer update --no-interaction --prefer-dist --optimize-autoloader --no-scripts"
    if not run_ok(base_cmd + f" -d {APP_DIR}"):
        print("  Retrying with --ignore-platform-reqs …")
        run(base_cmd + f" --ignore-platform-reqs -d {APP_DIR}", check=False)

    run(f"composer dump-autoload --optimize -d {APP_DIR}", check=False)
    print("  Phase 2 complete.")


# ---------------------------------------------------------------------------
# Phase 3 — NPM
# ---------------------------------------------------------------------------

def phase3_npm():
    print("\n=== Phase 3: NPM / laravel-mix ===")

    package_json = {
        "private": True,
        "scripts": {
            "dev": "npm run development",
            "development": "mix",
            "watch": "mix watch",
            "watch-poll": "mix watch -- --watch-options-poll=1000",
            "hot": "mix watch --hot",
            "prod": "npm run production",
            "production": "mix --production",
        },
        "devDependencies": {
            "axios": "^1.6.0",
            "laravel-mix": "^6.0.6",
            "lodash": "^4.17.21",
            "postcss": "^8.1.14",
            "resolve-url-loader": "^3.1.2",
            "sass": "^1.32.11",
            "sass-loader": "^11.0.1",
        },
    }

    write_file(
        f"{APP_DIR}/package.json",
        json.dumps(package_json, indent=2) + "\n",
    )

    for path in [f"{APP_DIR}/node_modules", f"{APP_DIR}/package-lock.json"]:
        if os.path.isdir(path):
            shutil.rmtree(path)
        elif os.path.isfile(path):
            os.unlink(path)

    if not run_ok(f"npm install --prefix {APP_DIR}"):
        run(f"npm install --legacy-peer-deps --prefix {APP_DIR}", check=False)

    print("  Phase 3 complete.")


# ---------------------------------------------------------------------------
# Phase 4 — Monerod
# ---------------------------------------------------------------------------

def phase4_monerod():
    print("\n=== Phase 4: Monerod systemd unit ===")

    unit = """\
[Unit]
Description=Monero Daemon
After=network.target

[Service]
Type=simple
User=monero
ExecStart=/usr/bin/monerod --non-interactive --restricted-rpc --rpc-bind-ip=127.0.0.1 --rpc-bind-port=18081 --confirm-external-bind --log-file=/var/log/monerod.log
Restart=on-failure
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
"""
    write_file("/etc/systemd/system/monerod.service", unit)

    for cmd in [
        "systemctl daemon-reload",
        "systemctl restart monerod",
        "systemctl enable monerod",
    ]:
        run_ok(cmd)

    print("  Phase 4 complete.")


# ---------------------------------------------------------------------------
# Phase 5 — HTTPS / Apache
# ---------------------------------------------------------------------------

def phase5_https():
    print("\n=== Phase 5: HTTPS / Apache ===")

    ssl_dir = "/etc/ssl/capitalmonero"
    mkdir(ssl_dir)

    # Self-signed cert
    run(
        f'openssl req -x509 -nodes -days 3650 -newkey rsa:2048 '
        f'-keyout {ssl_dir}/privkey.pem '
        f'-out {ssl_dir}/fullchain.pem '
        f'-subj "/CN={DOMAIN}"',
        check=False,
    )

    # HTTP vhost
    http_vhost = f"""\
<VirtualHost *:80>
    ServerName {DOMAIN}
    RewriteEngine On
    RewriteRule ^ https://%{{HTTP_HOST}}%{{REQUEST_URI}} [R=301,L]
</VirtualHost>
"""
    write_file(f"/etc/apache2/sites-available/capitalmonero.conf", http_vhost)

    # HTTPS vhost
    https_vhost = f"""\
<VirtualHost *:443>
    ServerName {DOMAIN}
    DocumentRoot {APP_DIR}/public

    SSLEngine on
    SSLCertificateFile {ssl_dir}/fullchain.pem
    SSLCertificateKeyFile {ssl_dir}/privkey.pem

    <Directory {APP_DIR}/public>
        AllowOverride All
        Require all granted
        Options -Indexes +FollowSymLinks
    </Directory>

    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options SAMEORIGIN
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"

    ErrorLog ${{APACHE_LOG_DIR}}/capitalmonero_error.log
    CustomLog ${{APACHE_LOG_DIR}}/capitalmonero_access.log combined
</VirtualHost>
"""
    write_file("/etc/apache2/sites-available/capitalmonero-ssl.conf", https_vhost)

    # Onion vhost (only written if TOR_ONION is set)
    if TOR_ONION:
        onion_vhost = f"""\
<VirtualHost *:80>
    ServerName {TOR_ONION}
    DocumentRoot {APP_DIR}/public
    <Directory {APP_DIR}/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
"""
        write_file("/etc/apache2/sites-available/capitalmonero-onion.conf", onion_vhost)

    # Enable modules & sites
    for mod in ["ssl", "rewrite", "headers"]:
        run_ok(f"a2enmod {mod}")

    run_ok(f"a2ensite capitalmonero.conf")
    run_ok(f"a2ensite capitalmonero-ssl.conf")
    if TOR_ONION:
        run_ok("a2ensite capitalmonero-onion.conf")

    # Try certbot
    run_ok(
        f"certbot --apache -d {DOMAIN} --non-interactive --agree-tos "
        f"--email admin@{DOMAIN} --redirect"
    )

    # UFW
    run_ok("ufw allow 443/tcp")

    print("  Phase 5 complete.")


# ---------------------------------------------------------------------------
# Phase 6 — Build complete application
# ---------------------------------------------------------------------------

def phase6_application():
    print("\n=== Phase 6: Build application files ===")

    # --- Directories ---
    for d in [
        f"{APP_DIR}/app/Console",
        f"{APP_DIR}/app/Exceptions",
        f"{APP_DIR}/app/Http/Controllers",
        f"{APP_DIR}/app/Http/Middleware",
        f"{APP_DIR}/app/Models",
        f"{APP_DIR}/app/Providers",
        f"{APP_DIR}/bootstrap/cache",
        f"{APP_DIR}/config",
        f"{APP_DIR}/database/migrations",
        f"{APP_DIR}/database/seeders",
        f"{APP_DIR}/public",
        f"{APP_DIR}/resources/js",
        f"{APP_DIR}/resources/sass",
        f"{APP_DIR}/resources/views/auth",
        f"{APP_DIR}/resources/views/errors",
        f"{APP_DIR}/resources/views/layouts",
        f"{APP_DIR}/resources/views/offers",
        f"{APP_DIR}/resources/views/trades",
        f"{APP_DIR}/resources/views/wallet",
        f"{APP_DIR}/routes",
        f"{APP_DIR}/storage/app/public",
        f"{APP_DIR}/storage/framework/cache/data",
        f"{APP_DIR}/storage/framework/sessions",
        f"{APP_DIR}/storage/framework/testing",
        f"{APP_DIR}/storage/framework/views",
        f"{APP_DIR}/storage/logs",
    ]:
        mkdir(d)

    # -----------------------------------------------------------------------
    # Migration
    # -----------------------------------------------------------------------
    migration = r"""<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateAllTables extends Migration
{
    public function up()
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->boolean('is_admin')->default(false);
            $table->rememberToken();
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

        Schema::create('offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['buy', 'sell']);
            $table->string('currency', 10)->default('XMR');
            $table->string('payment_method');
            $table->decimal('price', 18, 8);
            $table->decimal('min_amount', 18, 8);
            $table->decimal('max_amount', 18, 8);
            $table->text('terms')->nullable();
            $table->boolean('active')->default(true);
            $table->timestamps();
        });

        Schema::create('trades', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('buyer_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('seller_id')->constrained('users')->onDelete('cascade');
            $table->decimal('amount', 18, 8);
            $table->decimal('price', 18, 8);
            $table->enum('status', ['open', 'paid', 'released', 'disputed', 'cancelled'])->default('open');
            $table->timestamps();
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('currency', 10)->default('XMR');
            $table->decimal('balance', 18, 8)->default(0);
            $table->string('address')->nullable();
            $table->timestamps();
        });

        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('wallet_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['deposit', 'withdrawal', 'trade_lock', 'trade_release']);
            $table->decimal('amount', 18, 8);
            $table->string('txid')->nullable();
            $table->string('status')->default('pending');
            $table->timestamps();
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('opened_by')->constrained('users')->onDelete('cascade');
            $table->text('reason');
            $table->enum('status', ['open', 'resolved', 'closed'])->default('open');
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type');
            $table->morphs('notifiable');
            $table->text('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('disputes');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('trades');
        Schema::dropIfExists('offers');
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('password_resets');
        Schema::dropIfExists('users');
    }
}
"""
    write_file(
        f"{APP_DIR}/database/migrations/2021_01_01_000000_create_all_tables.php",
        migration,
    )

    # -----------------------------------------------------------------------
    # Models
    # -----------------------------------------------------------------------
    user_model = r"""<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = ['name', 'email', 'password'];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    public function offers()
    {
        return $this->hasMany(Offer::class);
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }
}
"""
    write_file(f"{APP_DIR}/app/Models/User.php", user_model)

    offer_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Offer extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'type', 'currency', 'payment_method', 'price', 'min_amount', 'max_amount', 'terms', 'active'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function trades()
    {
        return $this->hasMany(Trade::class);
    }
}
"""
    write_file(f"{APP_DIR}/app/Models/Offer.php", offer_model)

    trade_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trade extends Model
{
    use HasFactory;

    protected $fillable = ['offer_id', 'buyer_id', 'seller_id', 'amount', 'price', 'status'];

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
}
"""
    write_file(f"{APP_DIR}/app/Models/Trade.php", trade_model)

    wallet_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'currency', 'balance', 'address'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
}
"""
    write_file(f"{APP_DIR}/app/Models/Wallet.php", wallet_model)

    transaction_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = ['wallet_id', 'type', 'amount', 'txid', 'status'];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class);
    }
}
"""
    write_file(f"{APP_DIR}/app/Models/Transaction.php", transaction_model)

    dispute_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = ['trade_id', 'opened_by', 'reason', 'status'];

    public function trade()
    {
        return $this->belongsTo(Trade::class);
    }
}
"""
    write_file(f"{APP_DIR}/app/Models/Dispute.php", dispute_model)

    notification_model = r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = ['type', 'data', 'read_at'];
}
"""
    write_file(f"{APP_DIR}/app/Models/Notification.php", notification_model)

    # -----------------------------------------------------------------------
    # Controllers
    # -----------------------------------------------------------------------
    base_controller = r"""<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

class Controller extends BaseController
{
    use AuthorizesRequests, DispatchesJobs, ValidatesRequests;
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/Controller.php", base_controller)

    home_controller = r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Http\Request;

class HomeController extends Controller
{
    public function index()
    {
        $buyOffers  = Offer::where('type', 'buy')->where('active', true)->latest()->take(5)->get();
        $sellOffers = Offer::where('type', 'sell')->where('active', true)->latest()->take(5)->get();
        $stats = [
            'total_trades'  => Trade::count(),
            'total_offers'  => Offer::where('active', true)->count(),
        ];
        return view('home', compact('buyOffers', 'sellOffers', 'stats'));
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/HomeController.php", home_controller)

    auth_controller = r"""<?php

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
        $credentials = $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $request->session()->regenerate();
            return redirect()->intended('/dashboard');
        }

        return back()->withErrors(['email' => 'Invalid credentials.'])->onlyInput('email');
    }

    public function showRegister()
    {
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'name'                  => 'required|string|max:255',
            'email'                 => 'required|string|email|max:255|unique:users',
            'password'              => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        Auth::login($user);
        return redirect('/dashboard');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/');
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/AuthController.php", auth_controller)

    offer_controller = r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use Illuminate\Http\Request;

class OfferController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth')->except(['index', 'show']);
    }

    public function index()
    {
        $offers = Offer::with('user')->where('active', true)->latest()->paginate(20);
        return view('offers.index', compact('offers'));
    }

    public function show(Offer $offer)
    {
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
            'payment_method' => 'required|string|max:255',
            'price'          => 'required|numeric|min:0',
            'min_amount'     => 'required|numeric|min:0',
            'max_amount'     => 'required|numeric|min:0',
            'terms'          => 'nullable|string',
        ]);

        $data['user_id']  = auth()->id();
        $data['currency'] = 'XMR';
        Offer::create($data);
        return redirect('/offers')->with('success', 'Offer created.');
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/OfferController.php", offer_controller)

    trade_controller = r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Http\Request;

class TradeController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $userId = auth()->id();
        $trades = Trade::where('buyer_id', $userId)->orWhere('seller_id', $userId)->latest()->paginate(20);
        return view('trades.index', compact('trades'));
    }

    public function show(Trade $trade)
    {
        return view('trades.show', compact('trade'));
    }

    public function store(Request $request, Offer $offer)
    {
        $data = $request->validate([
            'amount' => 'required|numeric|min:0',
        ]);

        $trade = Trade::create([
            'offer_id'  => $offer->id,
            'buyer_id'  => auth()->id(),
            'seller_id' => $offer->user_id,
            'amount'    => $data['amount'],
            'price'     => $offer->price,
            'status'    => 'open',
        ]);

        return redirect("/trades/{$trade->id}")->with('success', 'Trade opened.');
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/TradeController.php", trade_controller)

    wallet_controller = r"""<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $wallet = Wallet::firstOrCreate(
            ['user_id' => auth()->id()],
            ['currency' => 'XMR', 'balance' => 0]
        );
        return view('wallet.index', compact('wallet'));
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/WalletController.php", wallet_controller)

    dashboard_controller = r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $userId = auth()->id();
        $myOffers = Offer::where('user_id', $userId)->latest()->take(5)->get();
        $myTrades = Trade::where('buyer_id', $userId)->orWhere('seller_id', $userId)->latest()->take(5)->get();
        return view('dashboard', compact('myOffers', 'myTrades'));
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Controllers/DashboardController.php", dashboard_controller)

    # -----------------------------------------------------------------------
    # Middleware
    # -----------------------------------------------------------------------
    authenticate_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    protected function redirectTo($request)
    {
        if (! $request->expectsJson()) {
            return route('login');
        }
    }
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/Authenticate.php", authenticate_mw)

    redirect_if_auth_mw = r"""<?php

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
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/RedirectIfAuthenticated.php", redirect_if_auth_mw)

    trust_proxies_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    protected $proxies = '*';
    protected $headers = Request::HEADER_X_FORWARDED_FOR |
                         Request::HEADER_X_FORWARDED_HOST |
                         Request::HEADER_X_FORWARDED_PORT |
                         Request::HEADER_X_FORWARDED_PROTO |
                         Request::HEADER_X_FORWARDED_AWS_ELB;
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/TrustProxies.php", trust_proxies_mw)

    verify_csrf_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    protected $except = [];
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/VerifyCsrfToken.php", verify_csrf_mw)

    trim_strings_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\TrimStrings as Middleware;

class TrimStrings extends Middleware
{
    protected $except = ['password', 'password_confirmation'];
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/TrimStrings.php", trim_strings_mw)

    prevent_req_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance as Middleware;

class PreventRequestsDuringMaintenance extends Middleware
{
    protected $except = [];
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/PreventRequestsDuringMaintenance.php", prevent_req_mw)

    encrypt_cookies_mw = r"""<?php

namespace App\Http\Middleware;

use Illuminate\Cookie\Middleware\EncryptCookies as Middleware;

class EncryptCookies extends Middleware
{
    protected $except = [];
}
"""
    write_file(f"{APP_DIR}/app/Http/Middleware/EncryptCookies.php", encrypt_cookies_mw)

    # -----------------------------------------------------------------------
    # HTTP Kernel
    # -----------------------------------------------------------------------
    kernel = r"""<?php

namespace App\Http;

use Illuminate\Foundation\Http\Kernel as HttpKernel;

class Kernel extends HttpKernel
{
    protected $middleware = [
        \App\Http\Middleware\TrustProxies::class,
        \Illuminate\Http\Middleware\HandleCors::class,
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
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
        'api' => [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],
    ];

    protected $routeMiddleware = [
        'auth'             => \App\Http\Middleware\Authenticate::class,
        'auth.basic'       => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'auth.session'     => \Illuminate\Session\Middleware\AuthenticateSession::class,
        'cache.headers'    => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can'              => \Illuminate\Auth\Middleware\Authorize::class,
        'guest'            => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
        'signed'           => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle'         => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified'         => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
    ];
}
"""
    write_file(f"{APP_DIR}/app/Http/Kernel.php", kernel)

    # -----------------------------------------------------------------------
    # Providers
    # -----------------------------------------------------------------------
    app_service_provider = r"""<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;

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
"""
    write_file(f"{APP_DIR}/app/Providers/AppServiceProvider.php", app_service_provider)

    auth_service_provider = r"""<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [];

    public function boot()
    {
        $this->registerPolicies();
    }
}
"""
    write_file(f"{APP_DIR}/app/Providers/AuthServiceProvider.php", auth_service_provider)

    route_service_provider = r"""<?php

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
            return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
        });
    }
}
"""
    write_file(f"{APP_DIR}/app/Providers/RouteServiceProvider.php", route_service_provider)

    event_service_provider = r"""<?php

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
"""
    write_file(f"{APP_DIR}/app/Providers/EventServiceProvider.php", event_service_provider)

    broadcast_service_provider = r"""<?php

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
"""
    write_file(f"{APP_DIR}/app/Providers/BroadcastServiceProvider.php", broadcast_service_provider)

    # -----------------------------------------------------------------------
    # Exception Handler
    # -----------------------------------------------------------------------
    exception_handler = r"""<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontReport = [];

    protected $dontFlash = ['current_password', 'password', 'password_confirmation'];

    public function register()
    {
        $this->reportable(function (Throwable $e) {
        });
    }
}
"""
    write_file(f"{APP_DIR}/app/Exceptions/Handler.php", exception_handler)

    # -----------------------------------------------------------------------
    # Console Kernel
    # -----------------------------------------------------------------------
    console_kernel = r"""<?php

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
        $this->load(__DIR__.'/Commands');
        require base_path('routes/console.php');
    }
}
"""
    write_file(f"{APP_DIR}/app/Console/Kernel.php", console_kernel)

    # -----------------------------------------------------------------------
    # Routes
    # -----------------------------------------------------------------------
    web_routes = r"""<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\OfferController;
use App\Http\Controllers\TradeController;
use App\Http\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

Route::get('/', [HomeController::class, 'index'])->name('home');

Route::get('/login',   [AuthController::class, 'showLogin'])->name('login')->middleware('guest');
Route::post('/login',  [AuthController::class, 'login']);
Route::get('/register', [AuthController::class, 'showRegister'])->name('register')->middleware('guest');
Route::post('/register', [AuthController::class, 'register']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

Route::resource('offers', OfferController::class);
Route::post('/offers/{offer}/trade', [TradeController::class, 'store'])->name('trades.create');
Route::resource('trades', TradeController::class)->only(['index', 'show']);

Route::get('/wallet', [WalletController::class, 'index'])->name('wallet.index');
"""
    write_file(f"{APP_DIR}/routes/web.php", web_routes)

    api_routes = r"""<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::get('/health', function () {
    return response()->json(['status' => 'ok']);
});

Route::get('/stats', function () {
    return response()->json([
        'offers' => \App\Models\Offer::where('active', true)->count(),
        'trades' => \App\Models\Trade::count(),
    ]);
});
"""
    write_file(f"{APP_DIR}/routes/api.php", api_routes)

    channels_routes = r"""<?php

use Illuminate\Support\Facades\Broadcast;
"""
    write_file(f"{APP_DIR}/routes/channels.php", channels_routes)

    console_routes = r"""<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
"""
    write_file(f"{APP_DIR}/routes/console.php", console_routes)

    # -----------------------------------------------------------------------
    # Config files
    # -----------------------------------------------------------------------
    app_config = r"""<?php

return [
    'name'            => env('APP_NAME', 'CapitalMonero'),
    'env'             => env('APP_ENV', 'production'),
    'debug'           => (bool) env('APP_DEBUG', false),
    'url'             => env('APP_URL', 'http://localhost'),
    'asset_url'       => null,
    'timezone'        => 'UTC',
    'locale'          => 'en',
    'fallback_locale' => 'en',
    'faker_locale'    => 'en_US',
    'key'             => env('APP_KEY'),
    'cipher'          => 'AES-256-CBC',
    'maintenance'     => ['driver' => 'file'],
    'providers'       => [
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
        'Cache'     => Illuminate\Support\Facades\Cache::class,
        'Config'    => Illuminate\Support\Facades\Config::class,
        'Cookie'    => Illuminate\Support\Facades\Cookie::class,
        'Crypt'     => Illuminate\Support\Facades\Crypt::class,
        'DB'        => Illuminate\Support\Facades\DB::class,
        'Event'     => Illuminate\Support\Facades\Event::class,
        'File'      => Illuminate\Support\Facades\File::class,
        'Gate'      => Illuminate\Support\Facades\Gate::class,
        'Hash'      => Illuminate\Support\Facades\Hash::class,
        'Http'      => Illuminate\Support\Facades\Http::class,
        'Lang'      => Illuminate\Support\Facades\Lang::class,
        'Log'       => Illuminate\Support\Facades\Log::class,
        'Mail'      => Illuminate\Support\Facades\Mail::class,
        'Notification' => Illuminate\Support\Facades\Notification::class,
        'Password'  => Illuminate\Support\Facades\Password::class,
        'Queue'     => Illuminate\Support\Facades\Queue::class,
        'Redirect'  => Illuminate\Support\Facades\Redirect::class,
        'Redis'     => Illuminate\Support\Facades\Redis::class,
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
"""
    write_file(f"{APP_DIR}/config/app.php", app_config)

    database_config = r"""<?php

return [
    'default' => env('DB_CONNECTION', 'mysql'),
    'connections' => [
        'sqlite' => [
            'driver'   => 'sqlite',
            'url'      => env('DATABASE_URL'),
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix'   => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ],
        'mysql' => [
            'driver'         => 'mysql',
            'url'            => env('DATABASE_URL'),
            'host'           => env('DB_HOST', '127.0.0.1'),
            'port'           => env('DB_PORT', '3306'),
            'database'       => env('DB_DATABASE', 'forge'),
            'username'       => env('DB_USERNAME', 'forge'),
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
        'client'  => env('REDIS_CLIENT', 'predis'),
        'options' => ['cluster' => env('REDIS_CLUSTER', 'redis'), 'prefix' => env('REDIS_PREFIX', '')],
        'default' => ['url' => env('REDIS_URL'), 'host' => env('REDIS_HOST', '127.0.0.1'), 'username' => env('REDIS_USERNAME'), 'password' => env('REDIS_PASSWORD'), 'port' => env('REDIS_PORT', '6379'), 'database' => env('REDIS_DB', '0')],
        'cache'   => ['url' => env('REDIS_URL'), 'host' => env('REDIS_HOST', '127.0.0.1'), 'username' => env('REDIS_USERNAME'), 'password' => env('REDIS_PASSWORD'), 'port' => env('REDIS_PORT', '6379'), 'database' => env('REDIS_CACHE_DB', '1')],
    ],
];
"""
    write_file(f"{APP_DIR}/config/database.php", database_config)

    session_config = r"""<?php

return [
    'driver'          => env('SESSION_DRIVER', 'redis'),
    'lifetime'        => env('SESSION_LIFETIME', 120),
    'expire_on_close' => false,
    'encrypt'         => false,
    'files'           => storage_path('framework/sessions'),
    'connection'      => env('SESSION_CONNECTION'),
    'table'           => 'sessions',
    'store'           => env('SESSION_STORE'),
    'lottery'         => [2, 100],
    'cookie'          => env('SESSION_COOKIE', \Illuminate\Support\Str::slug(env('APP_NAME', 'laravel'), '_').'_session'),
    'path'            => '/',
    'domain'          => env('SESSION_DOMAIN'),
    'secure'          => env('SESSION_SECURE_COOKIE', true),
    'http_only'       => true,
    'same_site'       => 'lax',
];
"""
    write_file(f"{APP_DIR}/config/session.php", session_config)

    cache_config = r"""<?php

return [
    'default' => env('CACHE_DRIVER', 'redis'),
    'stores'  => [
        'apc'       => ['driver' => 'apc'],
        'array'     => ['driver' => 'array', 'serialize' => false],
        'database'  => ['driver' => 'database', 'table' => 'cache', 'connection' => null, 'lock_connection' => null],
        'file'      => ['driver' => 'file', 'path' => storage_path('framework/cache/data')],
        'memcached' => ['driver' => 'memcached', 'persistent_id' => env('MEMCACHED_PERSISTENT_ID'), 'sasl' => [env('MEMCACHED_USERNAME'), env('MEMCACHED_PASSWORD')], 'options' => [], 'servers' => [['host' => env('MEMCACHED_HOST', '127.0.0.1'), 'port' => env('MEMCACHED_PORT', 11211), 'weight' => 100]]],
        'redis'     => ['driver' => 'redis', 'connection' => 'cache', 'lock_connection' => 'default'],
        'dynamodb'  => ['driver' => 'dynamodb', 'key' => env('AWS_ACCESS_KEY_ID'), 'secret' => env('AWS_SECRET_ACCESS_KEY'), 'region' => env('AWS_DEFAULT_REGION', 'us-east-1'), 'table' => env('DYNAMODB_CACHE_TABLE', 'cache'), 'endpoint' => env('DYNAMODB_ENDPOINT')],
        'octane'    => ['driver' => 'octane'],
    ],
    'prefix' => env('CACHE_PREFIX', \Illuminate\Support\Str::slug(env('APP_NAME', 'laravel'), '_').'_cache_'),
];
"""
    write_file(f"{APP_DIR}/config/cache.php", cache_config)

    auth_config = r"""<?php

return [
    'defaults' => ['guard' => 'web', 'passwords' => 'users'],
    'guards'   => [
        'web' => ['driver' => 'session', 'provider' => 'users'],
        'api' => ['driver' => 'token',   'provider' => 'users', 'hash' => false],
    ],
    'providers' => [
        'users' => ['driver' => 'eloquent', 'model' => App\Models\User::class],
    ],
    'passwords' => [
        'users' => ['provider' => 'users', 'table' => 'password_resets', 'expire' => 60, 'throttle' => 60],
    ],
    'password_timeout' => 10800,
];
"""
    write_file(f"{APP_DIR}/config/auth.php", auth_config)

    view_config = r"""<?php

return [
    'paths'    => [resource_path('views')],
    'compiled' => env('VIEW_COMPILED_PATH', realpath(storage_path('framework/views'))),
];
"""
    write_file(f"{APP_DIR}/config/view.php", view_config)

    logging_config = r"""<?php

use Monolog\Handler\NullHandler;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogUdpHandler;

return [
    'default'  => env('LOG_CHANNEL', 'stack'),
    'deprecations' => ['channel' => env('LOG_DEPRECATIONS_CHANNEL', 'null'), 'trace' => false],
    'channels' => [
        'stack'     => ['driver' => 'stack', 'channels' => ['single'], 'ignore_exceptions' => false],
        'single'    => ['driver' => 'single', 'path' => storage_path('logs/laravel.log'), 'level' => env('LOG_LEVEL', 'debug')],
        'daily'     => ['driver' => 'daily', 'path' => storage_path('logs/laravel.log'), 'level' => env('LOG_LEVEL', 'debug'), 'days' => 14],
        'slack'     => ['driver' => 'slack', 'url' => env('LOG_SLACK_WEBHOOK_URL'), 'username' => 'Laravel Log', 'emoji' => ':boom:', 'level' => env('LOG_LEVEL', 'critical')],
        'papertrail'=> ['driver' => 'monolog', 'level' => env('LOG_LEVEL', 'debug'), 'handler' => env('LOG_PAPERTRAIL_HANDLER', SyslogUdpHandler::class), 'handler_with' => ['host' => env('PAPERTRAIL_URL'), 'port' => env('PAPERTRAIL_PORT')]],
        'stderr'    => ['driver' => 'monolog', 'level' => env('LOG_LEVEL', 'debug'), 'handler' => StreamHandler::class, 'formatter' => env('LOG_STDERR_FORMATTER'), 'with' => ['stream' => 'php://stderr']],
        'syslog'    => ['driver' => 'syslog', 'level' => env('LOG_LEVEL', 'debug')],
        'errorlog'  => ['driver' => 'errorlog', 'level' => env('LOG_LEVEL', 'debug')],
        'null'      => ['driver' => 'monolog', 'handler' => NullHandler::class],
        'emergency' => ['path' => storage_path('logs/laravel.log')],
    ],
];
"""
    write_file(f"{APP_DIR}/config/logging.php", logging_config)

    cors_config = r"""<?php

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
"""
    write_file(f"{APP_DIR}/config/cors.php", cors_config)

    sanctum_config = r"""<?php

return [
    'stateful'  => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf('%s%s', 'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1', app()->environment('local') ? ','.parse_url(config('app.url'), PHP_URL_HOST) : ''))),
    'guard'     => ['web'],
    'expiration'=> null,
    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', ''),
    'middleware' => [
        'authenticate_session' => Laravel\Sanctum\Http\Middleware\AuthenticateSession::class,
        'encrypt_cookies'      => App\Http\Middleware\EncryptCookies::class,
        'verify_csrf_token'    => App\Http\Middleware\VerifyCsrfToken::class,
    ],
];
"""
    write_file(f"{APP_DIR}/config/sanctum.php", sanctum_config)

    # Copy remaining config files from vendor if available
    for cfg in ["broadcasting", "filesystems", "hashing", "mail", "queue"]:
        src = f"{APP_DIR}/vendor/laravel/framework/src/Illuminate/Foundation/Application.php"
        vendor_cfg = f"{APP_DIR}/vendor/laravel/laravel/config/{cfg}.php"
        dst = f"{APP_DIR}/config/{cfg}.php"
        if os.path.isfile(vendor_cfg) and not os.path.isfile(dst):
            shutil.copy(vendor_cfg, dst)
            print(f"  copied {dst}")

    # -----------------------------------------------------------------------
    # Bootstrap
    # -----------------------------------------------------------------------
    bootstrap_app = r"""<?php

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
"""
    write_file(f"{APP_DIR}/bootstrap/app.php", bootstrap_app)
    write_file(f"{APP_DIR}/bootstrap/cache/.gitignore", "*\n!.gitignore\n")

    # -----------------------------------------------------------------------
    # Public
    # -----------------------------------------------------------------------
    public_index = r"""<?php

define('LARAVEL_START', microtime(true));

/*
|--------------------------------------------------------------------------
| Check If The Application Is Under Maintenance
|--------------------------------------------------------------------------
*/

if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

/*
|--------------------------------------------------------------------------
| Register The Auto Loader
|--------------------------------------------------------------------------
*/

require __DIR__.'/../vendor/autoload.php';

/*
|--------------------------------------------------------------------------
| Run The Application
|--------------------------------------------------------------------------
*/

$app = require_once __DIR__.'/../bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
)->send();

$kernel->terminate($request, $response);
"""
    write_file(f"{APP_DIR}/public/index.php", public_index)

    htaccess = r"""<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
"""
    write_file(f"{APP_DIR}/public/.htaccess", htaccess)

    robots_txt = "User-agent: *\nDisallow: /admin\n"
    write_file(f"{APP_DIR}/public/robots.txt", robots_txt)

    # -----------------------------------------------------------------------
    # Storage .gitignore files
    # -----------------------------------------------------------------------
    for d, content in [
        (f"{APP_DIR}/storage/app",                   "*\n!public/\n!.gitignore\n"),
        (f"{APP_DIR}/storage/app/public",             "*\n!.gitignore\n"),
        (f"{APP_DIR}/storage/framework/cache",        "*\n!data/\n!.gitignore\n"),
        (f"{APP_DIR}/storage/framework/cache/data",   "*\n!.gitignore\n"),
        (f"{APP_DIR}/storage/framework/sessions",     "*\n!.gitignore\n"),
        (f"{APP_DIR}/storage/framework/testing",      "*\n!.gitignore\n"),
        (f"{APP_DIR}/storage/framework/views",        "*\n!.gitignore\n"),
        (f"{APP_DIR}/storage/logs",                   "*\n!.gitignore\n"),
    ]:
        write_file(f"{d}/.gitignore", content)

    # -----------------------------------------------------------------------
    # Views
    # -----------------------------------------------------------------------

    # layouts/app.blade.php
    layout_app = r"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ config('app.name', 'CapitalMonero') }}</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body { background-color: #1a1a2e; color: #e0e0e0; }
        .navbar { background-color: #16213e !important; }
        .card  { background-color: #16213e; border-color: #0f3460; color: #e0e0e0; }
        .btn-primary { background-color: #0f3460; border-color: #0f3460; }
        a { color: #e94560; }
        a:hover { color: #c73652; }
        .table { color: #e0e0e0; }
        .table thead th { border-color: #0f3460; }
        .table td, .table th { border-color: #0f3460; }
    </style>
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-dark">
    <a class="navbar-brand" href="/">&#9899; CapitalMonero</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navMenu">
        <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navMenu">
        <ul class="navbar-nav mr-auto">
            <li class="nav-item"><a class="nav-link" href="{{ route('home') }}">Home</a></li>
            <li class="nav-item"><a class="nav-link" href="{{ route('offers.index') }}">Offers</a></li>
            @auth
            <li class="nav-item"><a class="nav-link" href="{{ route('trades.index') }}">My Trades</a></li>
            <li class="nav-item"><a class="nav-link" href="{{ route('wallet.index') }}">Wallet</a></li>
            <li class="nav-item"><a class="nav-link" href="{{ route('dashboard') }}">Dashboard</a></li>
            @endauth
        </ul>
        <ul class="navbar-nav ml-auto">
            @guest
            <li class="nav-item"><a class="nav-link" href="{{ route('login') }}">Login</a></li>
            <li class="nav-item"><a class="nav-link" href="{{ route('register') }}">Register</a></li>
            @else
            <li class="nav-item">
                <form action="{{ route('logout') }}" method="POST" class="d-inline">
                    @csrf
                    <button type="submit" class="btn btn-link nav-link">Logout ({{ auth()->user()->name }})</button>
                </form>
            </li>
            @endguest
        </ul>
    </div>
</nav>
<div class="container mt-4">
    @if(session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif
    @if($errors->any())
        <div class="alert alert-danger">
            <ul class="mb-0">@foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach</ul>
        </div>
    @endif
    @yield('content')
</div>
<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
"""
    write_file(f"{APP_DIR}/resources/views/layouts/app.blade.php", layout_app)

    # home.blade.php
    home_view = r"""@extends('layouts.app')
@section('content')
<div class="jumbotron" style="background-color:#16213e;">
    <h1 class="display-4">&#9899; CapitalMonero</h1>
    <p class="lead">Private Monero P2P Exchange — Trade XMR securely and anonymously.</p>
    <a class="btn btn-primary btn-lg" href="{{ route('offers.index') }}">Browse Offers</a>
    @guest <a class="btn btn-outline-secondary btn-lg ml-2" href="{{ route('register') }}">Get Started</a> @endguest
</div>

<div class="row mb-4">
    <div class="col-md-6">
        <div class="card text-center">
            <div class="card-body">
                <h3>{{ $stats['total_offers'] }}</h3>
                <p>Active Offers</p>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card text-center">
            <div class="card-body">
                <h3>{{ $stats['total_trades'] }}</h3>
                <p>Total Trades</p>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-6">
        <h4>Buy XMR Offers</h4>
        <table class="table table-sm">
            <thead><tr><th>Payment</th><th>Price</th><th>Limits</th><th></th></tr></thead>
            <tbody>
            @forelse($buyOffers as $o)
            <tr>
                <td>{{ $o->payment_method }}</td>
                <td>{{ $o->price }}</td>
                <td>{{ $o->min_amount }} – {{ $o->max_amount }} XMR</td>
                <td><a href="{{ route('offers.show', $o) }}" class="btn btn-sm btn-primary">Buy</a></td>
            </tr>
            @empty
            <tr><td colspan="4">No buy offers.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="col-md-6">
        <h4>Sell XMR Offers</h4>
        <table class="table table-sm">
            <thead><tr><th>Payment</th><th>Price</th><th>Limits</th><th></th></tr></thead>
            <tbody>
            @forelse($sellOffers as $o)
            <tr>
                <td>{{ $o->payment_method }}</td>
                <td>{{ $o->price }}</td>
                <td>{{ $o->min_amount }} – {{ $o->max_amount }} XMR</td>
                <td><a href="{{ route('offers.show', $o) }}" class="btn btn-sm btn-primary">Sell</a></td>
            </tr>
            @empty
            <tr><td colspan="4">No sell offers.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/home.blade.php", home_view)

    # auth/login.blade.php
    login_view = r"""@extends('layouts.app')
@section('content')
<div class="row justify-content-center">
    <div class="col-md-5">
        <div class="card">
            <div class="card-header">Login</div>
            <div class="card-body">
                <form method="POST" action="/login">
                    @csrf
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="email" class="form-control" value="{{ old('email') }}" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" name="password" class="form-control" required>
                    </div>
                    <div class="form-check mb-3">
                        <input type="checkbox" name="remember" class="form-check-input" id="remember">
                        <label class="form-check-label" for="remember">Remember Me</label>
                    </div>
                    <button type="submit" class="btn btn-primary btn-block">Login</button>
                </form>
                <div class="mt-3 text-center">
                    <a href="{{ route('register') }}">Don't have an account? Register</a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/auth/login.blade.php", login_view)

    # auth/register.blade.php
    register_view = r"""@extends('layouts.app')
@section('content')
<div class="row justify-content-center">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">Register</div>
            <div class="card-body">
                <form method="POST" action="/register">
                    @csrf
                    <div class="form-group">
                        <label>Name</label>
                        <input type="text" name="name" class="form-control" value="{{ old('name') }}" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="email" class="form-control" value="{{ old('email') }}" required>
                    </div>
                    <div class="form-group">
                        <label>Password</label>
                        <input type="password" name="password" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label>Confirm Password</label>
                        <input type="password" name="password_confirmation" class="form-control" required>
                    </div>
                    <button type="submit" class="btn btn-primary btn-block">Register</button>
                </form>
                <div class="mt-3 text-center">
                    <a href="{{ route('login') }}">Already have an account? Login</a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/auth/register.blade.php", register_view)

    # offers/index.blade.php
    offers_index = r"""@extends('layouts.app')
@section('content')
<div class="d-flex justify-content-between align-items-center mb-3">
    <h2>All Offers</h2>
    @auth <a href="{{ route('offers.create') }}" class="btn btn-primary">Post Offer</a> @endauth
</div>
<table class="table">
    <thead><tr><th>Type</th><th>Trader</th><th>Payment</th><th>Price</th><th>Limits</th><th></th></tr></thead>
    <tbody>
    @forelse($offers as $o)
    <tr>
        <td><span class="badge badge-{{ $o->type === 'buy' ? 'success' : 'danger' }}">{{ strtoupper($o->type) }}</span></td>
        <td>{{ $o->user->name }}</td>
        <td>{{ $o->payment_method }}</td>
        <td>{{ $o->price }}</td>
        <td>{{ $o->min_amount }} – {{ $o->max_amount }} XMR</td>
        <td><a href="{{ route('offers.show', $o) }}" class="btn btn-sm btn-primary">View</a></td>
    </tr>
    @empty
    <tr><td colspan="6" class="text-center">No offers available.</td></tr>
    @endforelse
    </tbody>
</table>
{{ $offers->links() }}
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/offers/index.blade.php", offers_index)

    # offers/show.blade.php
    offers_show = r"""@extends('layouts.app')
@section('content')
<div class="card">
    <div class="card-header">
        <span class="badge badge-{{ $offer->type === 'buy' ? 'success' : 'danger' }}">{{ strtoupper($offer->type) }}</span>
        Offer by {{ $offer->user->name }}
    </div>
    <div class="card-body">
        <dl class="row">
            <dt class="col-sm-3">Payment Method</dt><dd class="col-sm-9">{{ $offer->payment_method }}</dd>
            <dt class="col-sm-3">Price</dt><dd class="col-sm-9">{{ $offer->price }}</dd>
            <dt class="col-sm-3">Limits</dt><dd class="col-sm-9">{{ $offer->min_amount }} – {{ $offer->max_amount }} XMR</dd>
            <dt class="col-sm-3">Terms</dt><dd class="col-sm-9">{{ $offer->terms ?? 'No terms specified.' }}</dd>
        </dl>
        @auth
        @if(auth()->id() !== $offer->user_id)
        <form method="POST" action="{{ route('trades.create', $offer) }}">
            @csrf
            <div class="form-group">
                <label>Amount (XMR)</label>
                <input type="number" step="0.00000001" name="amount" class="form-control" min="{{ $offer->min_amount }}" max="{{ $offer->max_amount }}" required>
            </div>
            <button type="submit" class="btn btn-primary">Start Trade</button>
        </form>
        @endif
        @else
        <a href="{{ route('login') }}" class="btn btn-primary">Login to Trade</a>
        @endauth
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/offers/show.blade.php", offers_show)

    # offers/create.blade.php
    offers_create = r"""@extends('layouts.app')
@section('content')
<div class="card">
    <div class="card-header">Post a New Offer</div>
    <div class="card-body">
        <form method="POST" action="{{ route('offers.store') }}">
            @csrf
            <div class="form-group">
                <label>Type</label>
                <select name="type" class="form-control" required>
                    <option value="buy">Buy XMR</option>
                    <option value="sell">Sell XMR</option>
                </select>
            </div>
            <div class="form-group">
                <label>Payment Method</label>
                <input type="text" name="payment_method" class="form-control" required>
            </div>
            <div class="form-group">
                <label>Price (per XMR)</label>
                <input type="number" step="0.01" name="price" class="form-control" required>
            </div>
            <div class="form-row">
                <div class="form-group col-md-6">
                    <label>Min Amount (XMR)</label>
                    <input type="number" step="0.00000001" name="min_amount" class="form-control" required>
                </div>
                <div class="form-group col-md-6">
                    <label>Max Amount (XMR)</label>
                    <input type="number" step="0.00000001" name="max_amount" class="form-control" required>
                </div>
            </div>
            <div class="form-group">
                <label>Terms (optional)</label>
                <textarea name="terms" class="form-control" rows="3"></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Post Offer</button>
        </form>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/offers/create.blade.php", offers_create)

    # trades/index.blade.php
    trades_index = r"""@extends('layouts.app')
@section('content')
<h2>My Trades</h2>
<table class="table">
    <thead><tr><th>ID</th><th>Amount</th><th>Price</th><th>Status</th><th>Date</th><th></th></tr></thead>
    <tbody>
    @forelse($trades as $t)
    <tr>
        <td>{{ $t->id }}</td>
        <td>{{ $t->amount }} XMR</td>
        <td>{{ $t->price }}</td>
        <td><span class="badge badge-info">{{ $t->status }}</span></td>
        <td>{{ $t->created_at->diffForHumans() }}</td>
        <td><a href="{{ route('trades.show', $t) }}" class="btn btn-sm btn-primary">View</a></td>
    </tr>
    @empty
    <tr><td colspan="6" class="text-center">No trades yet.</td></tr>
    @endforelse
    </tbody>
</table>
{{ $trades->links() }}
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/trades/index.blade.php", trades_index)

    # trades/show.blade.php
    trades_show = r"""@extends('layouts.app')
@section('content')
<div class="card">
    <div class="card-header">Trade #{{ $trade->id }}</div>
    <div class="card-body">
        <dl class="row">
            <dt class="col-sm-3">Amount</dt><dd class="col-sm-9">{{ $trade->amount }} XMR</dd>
            <dt class="col-sm-3">Price</dt><dd class="col-sm-9">{{ $trade->price }}</dd>
            <dt class="col-sm-3">Status</dt><dd class="col-sm-9"><span class="badge badge-info">{{ $trade->status }}</span></dd>
            <dt class="col-sm-3">Buyer</dt><dd class="col-sm-9">{{ $trade->buyer->name }}</dd>
            <dt class="col-sm-3">Seller</dt><dd class="col-sm-9">{{ $trade->seller->name }}</dd>
            <dt class="col-sm-3">Opened</dt><dd class="col-sm-9">{{ $trade->created_at->format('Y-m-d H:i') }}</dd>
        </dl>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/trades/show.blade.php", trades_show)

    # wallet/index.blade.php
    wallet_view = r"""@extends('layouts.app')
@section('content')
<h2>My Wallet</h2>
<div class="card">
    <div class="card-body">
        <h4>Balance: {{ $wallet->balance }} {{ $wallet->currency }}</h4>
        @if($wallet->address)
        <p>Deposit Address: <code>{{ $wallet->address }}</code></p>
        @else
        <p class="text-muted">No deposit address generated yet.</p>
        @endif
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/wallet/index.blade.php", wallet_view)

    # dashboard.blade.php
    dashboard_view = r"""@extends('layouts.app')
@section('content')
<h2>Dashboard</h2>
<div class="row">
    <div class="col-md-6">
        <h4>My Offers</h4>
        <table class="table table-sm">
            <thead><tr><th>Type</th><th>Payment</th><th>Price</th></tr></thead>
            <tbody>
            @forelse($myOffers as $o)
            <tr>
                <td>{{ $o->type }}</td>
                <td>{{ $o->payment_method }}</td>
                <td>{{ $o->price }}</td>
            </tr>
            @empty
            <tr><td colspan="3">No offers yet.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
    <div class="col-md-6">
        <h4>Recent Trades</h4>
        <table class="table table-sm">
            <thead><tr><th>Amount</th><th>Status</th></tr></thead>
            <tbody>
            @forelse($myTrades as $t)
            <tr>
                <td>{{ $t->amount }} XMR</td>
                <td>{{ $t->status }}</td>
            </tr>
            @empty
            <tr><td colspan="2">No trades yet.</td></tr>
            @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/dashboard.blade.php", dashboard_view)

    # errors/404.blade.php
    error_404 = r"""@extends('layouts.app')
@section('content')
<div class="text-center mt-5">
    <h1 style="font-size:6rem;">404</h1>
    <p class="lead">Page Not Found</p>
    <a href="/" class="btn btn-primary">Go Home</a>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/errors/404.blade.php", error_404)

    # errors/500.blade.php
    error_500 = r"""@extends('layouts.app')
@section('content')
<div class="text-center mt-5">
    <h1 style="font-size:6rem;">500</h1>
    <p class="lead">Internal Server Error</p>
    <a href="/" class="btn btn-primary">Go Home</a>
</div>
@endsection
"""
    write_file(f"{APP_DIR}/resources/views/errors/500.blade.php", error_500)

    # -----------------------------------------------------------------------
    # Frontend assets
    # -----------------------------------------------------------------------
    webpack_mix = r"""const mix = require('laravel-mix');

mix.js('resources/js/app.js', 'public/js')
   .sass('resources/sass/app.scss', 'public/css')
   .sourceMaps();
"""
    write_file(f"{APP_DIR}/webpack.mix.js", webpack_mix)

    app_js = r"""require('./bootstrap');
"""
    write_file(f"{APP_DIR}/resources/js/app.js", app_js)

    bootstrap_js = r"""window._ = require('lodash');
window.axios = require('axios');
window.axios.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';
"""
    write_file(f"{APP_DIR}/resources/js/bootstrap.js", bootstrap_js)

    app_scss = r"""// Variables
$body-bg: #1a1a2e;
$body-color: #e0e0e0;

// Bootstrap
@import '~bootstrap/scss/bootstrap';
"""
    write_file(f"{APP_DIR}/resources/sass/app.scss", app_scss)

    # -----------------------------------------------------------------------
    # Seeders
    # -----------------------------------------------------------------------
    db_seeder = r"""<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        User::firstOrCreate(
            ['email' => 'admin@capitalmonero.local'],
            [
                'name'     => 'Admin',
                'password' => Hash::make('changeme123!'),
                'is_admin' => true,
            ]
        );
    }
}
"""
    write_file(f"{APP_DIR}/database/seeders/DatabaseSeeder.php", db_seeder)

    print("  Phase 6 complete.")


# ---------------------------------------------------------------------------
# Phase 7 — Laravel Finalization
# ---------------------------------------------------------------------------

def phase7_finalize():
    print("\n=== Phase 7: Laravel Finalization ===")

    for cmd in [
        "php artisan key:generate --force",
        "php artisan migrate --force",
        "php artisan db:seed --force",
        "php artisan config:cache",
        "php artisan route:cache",
        "php artisan view:cache",
        "php artisan storage:link",
        f"composer run-script post-autoload-dump -d {APP_DIR}",
    ]:
        run_ok(cmd)

    # File permissions
    www_user = "www-data"
    run_ok(f"chown -R {www_user}:{www_user} {APP_DIR}")
    run_ok(f"find {APP_DIR} -type f -exec chmod 644 {{}} \\;")
    run_ok(f"find {APP_DIR} -type d -exec chmod 755 {{}} \\;")
    for d in ["storage", "bootstrap/cache"]:
        run_ok(f"chmod -R 775 {APP_DIR}/{d}")

    run_ok("systemctl restart apache2")
    print("  Phase 7 complete.")


# ---------------------------------------------------------------------------
# Phase 8 — Verification
# ---------------------------------------------------------------------------

def phase8_verify():
    print("\n=== Phase 8: Verification ===")

    results = {}

    for svc in ["apache2", "mariadb", "redis-server"]:
        ok = run_ok(f"systemctl is-active --quiet {svc}")
        results[svc] = "✓ active" if ok else "✗ not active"

    for port in [80, 443]:
        ok = run_ok(f"ss -tlnp | grep -q :{port}")
        results[f"port {port}"] = "✓ listening" if ok else "✗ not listening"

    ok = run_ok(
        f"mysql -u {DB_USER} -e 'SELECT 1' {DB_NAME} 2>/dev/null"
    )
    results["db connectivity"] = "✓ ok" if ok else "✗ failed"

    ok = run_ok("redis-cli ping 2>/dev/null | grep -q PONG")
    results["redis"] = "✓ ok" if ok else "✗ failed"

    print("\n--- Summary ---")
    for k, v in results.items():
        print(f"  {k:<20} {v}")

    print("\n  Phase 8 complete.")
    print("\n=== Setup Complete ===")
    print(f"  URL: https://{DOMAIN}")
    print(f"  Admin: admin@capitalmonero.local / changeme123!")
    print("  Please change the admin password immediately after first login.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if os.geteuid() != 0:
        print("ERROR: This script must be run as root (sudo).")
        sys.exit(1)

    mkdir(APP_DIR)

    phase1_database()
    phase2_composer()
    phase3_npm()
    phase4_monerod()
    phase5_https()
    phase6_application()
    phase7_finalize()
    phase8_verify()


if __name__ == "__main__":
    main()
