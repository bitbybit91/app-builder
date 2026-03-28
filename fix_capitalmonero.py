import subprocess, os, sys, secrets, string, json
from pathlib import Path
from datetime import datetime

APP_DIR = "/var/www/capitalmonero"
DOMAIN = "capitalmonero.com"
TOR_ONION = "fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion"
DB_NAME = "capitalmonero"
DB_USER = "capitalmonero"


def run(cmd, **kwargs):
    print(f"[RUN] {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, **kwargs)
    if result.stdout:
        print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    return result


def write_file(path, content, mode=0o644):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    os.chmod(path, mode)
    print(f"[FILE] {path}")


def gen_password(length=24):
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def phase1_database():
    print("\n=== Phase 1: Database ===")
    db_pass = gen_password(24)
    run("systemctl start mariadb || systemctl start mysql")
    Path(APP_DIR).mkdir(parents=True, exist_ok=True)
    sql_content = "\n".join([
        f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;",
        f"CREATE USER IF NOT EXISTS '{DB_USER}'@'localhost' IDENTIFIED BY '{db_pass}';",
        f"GRANT ALL PRIVILEGES ON `{DB_NAME}`.* TO '{DB_USER}'@'localhost';",
        "FLUSH PRIVILEGES;",
        "",
    ])
    sql_file = f"{APP_DIR}/setup_tmp.sql"
    Path(sql_file).write_text(sql_content)
    run(f"mysql -u root < {sql_file}")
    try:
        Path(sql_file).unlink()
    except Exception:
        pass
    app_key = "base64:" + secrets.token_urlsafe(32)
    monero_pass = gen_password(16)
    env_lines = [
        "APP_NAME=CapitalMonero",
        "APP_ENV=production",
        f"APP_KEY={app_key}",
        "APP_DEBUG=false",
        f"APP_URL=https://{DOMAIN}",
        "",
        "LOG_CHANNEL=stack",
        "LOG_LEVEL=error",
        "",
        "DB_CONNECTION=mysql",
        "DB_HOST=127.0.0.1",
        "DB_PORT=3306",
        f"DB_DATABASE={DB_NAME}",
        f"DB_USERNAME={DB_USER}",
        f"DB_PASSWORD={db_pass}",
        "",
        "BROADCAST_DRIVER=log",
        "CACHE_DRIVER=file",
        "FILESYSTEM_DRIVER=local",
        "QUEUE_CONNECTION=database",
        "SESSION_DRIVER=file",
        "SESSION_LIFETIME=120",
        "SESSION_SECURE_COOKIE=true",
        "",
        "REDIS_HOST=127.0.0.1",
        "REDIS_PASSWORD=null",
        "REDIS_PORT=6379",
        "",
        "MAIL_MAILER=smtp",
        "MAIL_HOST=mailhog",
        "MAIL_PORT=1025",
        "MAIL_USERNAME=null",
        "MAIL_PASSWORD=null",
        "MAIL_ENCRYPTION=null",
        f"MAIL_FROM_ADDRESS=noreply@{DOMAIN}",
        'MAIL_FROM_NAME="${APP_NAME}"',
        "",
        "MONERO_RPC_HOST=127.0.0.1",
        "MONERO_RPC_PORT=18081",
        "MONERO_RPC_USER=monero",
        f"MONERO_RPC_PASS={monero_pass}",
        "",
        f"TOR_ONION={TOR_ONION}",
        "",
    ]
    write_file(f"{APP_DIR}/.env", "\n".join(env_lines), 0o600)
    creds = {
        "db_name": DB_NAME,
        "db_user": DB_USER,
        "db_pass": db_pass,
        "app_key": app_key,
        "domain": DOMAIN,
        "tor_onion": TOR_ONION,
        "created": datetime.now().isoformat(),
    }
    write_file(f"{APP_DIR}/credentials.json", json.dumps(creds, indent=2), 0o600)
    print("[OK] Phase 1 complete")



def phase2_composer():
    print("\n=== Phase 2: Composer ===")
    composer_json = r"""{
    "name": "capitalmonero/exchange",
    "type": "project",
    "require": {
        "php": "^7.4|^8.0",
        "fruitcake/laravel-cors": "^2.0",
        "guzzlehttp/guzzle": "^7.0.1",
        "laravel/framework": "^8.75",
        "laravel/sanctum": "^2.11",
        "laravel/tinker": "^2.5",
        "pragmarx/google2fa": "^8.0",
        "bacon/bacon-qr-code": "^2.0"
    },
    "require-dev": {
        "fakerphp/faker": "^1.9.1",
        "laravel/sail": "^1.0.1",
        "mockery/mockery": "^1.4.4",
        "nunomaduro/collision": "^5.10",
        "phpunit/phpunit": "^9.5.10"
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
    },
    "extra": {
        "laravel": {
            "dont-discover": []
        }
    },
    "config": {
        "optimize-autoloader": true,
        "preferred-install": "dist",
        "sort-packages": true
    },
    "minimum-stability": "dev",
    "prefer-stable": true,
    "audit": {
        "abandoned": "report",
        "block-insecure": false
    }
}
"""
    write_file(f"{APP_DIR}/composer.json", composer_json)
    run(f"rm -rf {APP_DIR}/vendor {APP_DIR}/composer.lock")
    run(f"cd {APP_DIR} && composer update --no-interaction --no-audit 2>&1 || "
        f"composer update --no-interaction --ignore-platform-reqs 2>&1")
    run(f"cd {APP_DIR} && composer dump-autoload")
    print("[OK] Phase 2 complete")


def phase3_npm():
    print("\n=== Phase 3: NPM ===")
    package_json = r"""{
    "private": true,
    "scripts": {
        "dev": "npm run development",
        "development": "mix",
        "watch": "mix watch",
        "watch-poll": "mix watch -- --watch-options-poll=1000",
        "hot": "mix watch --hot",
        "prod": "npm run production",
        "production": "mix --production"
    },
    "devDependencies": {
        "axios": "^0.21",
        "laravel-mix": "^6.0.6",
        "lodash": "^4.17.19",
        "postcss": "^8.1.14"
    }
}
"""
    write_file(f"{APP_DIR}/package.json", package_json)
    run(f"rm -rf {APP_DIR}/node_modules")
    run(f"cd {APP_DIR} && npm install --legacy-peer-deps 2>&1")
    print("[OK] Phase 3 complete")


def phase4_monerod():
    print("\n=== Phase 4: Monerod ===")
    monerod_service = r"""[Unit]
Description=Monero Daemon
After=network.target

[Service]
Type=simple
User=monero
Group=monero
ExecStart=/usr/local/bin/monerod --non-interactive --restricted-rpc \
    --rpc-bind-ip=127.0.0.1 --rpc-bind-port=18081 \
    --confirm-external-bind --log-level=0 \
    --data-dir=/var/lib/monero
Restart=always
RestartSec=10
TimeoutStartSec=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
"""
    write_file("/etc/systemd/system/monerod.service", monerod_service)
    run("id -u monero &>/dev/null || useradd -r -M -d /var/lib/monero -s /bin/false monero")
    run("mkdir -p /var/lib/monero && chown monero:monero /var/lib/monero")
    run("systemctl daemon-reload")
    run("systemctl restart monerod || true")
    run("systemctl enable monerod || true")
    print("[OK] Phase 4 complete")


def phase5_webserver():
    print("\n=== Phase 5: Web Server ===")
    run("openssl req -x509 -nodes -days 3650 -newkey rsa:2048 "
        "-keyout /etc/ssl/private/capitalmonero.key "
        "-out /etc/ssl/certs/capitalmonero.crt "
        f'-subj "/CN={DOMAIN}"')

    nginx_conf = f"""server {{
    listen 80;
    server_name {DOMAIN} www.{DOMAIN};
    return 301 https://$host$request_uri;
}}

server {{
    listen 443 ssl http2;
    server_name {DOMAIN} www.{DOMAIN};

    ssl_certificate /etc/ssl/certs/capitalmonero.crt;
    ssl_certificate_key /etc/ssl/private/capitalmonero.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root {APP_DIR}/public;
    index index.php index.html;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;" always;

    location / {{
        try_files $uri $uri/ /index.php?$query_string;
    }}

    location ~ \\.php$ {{
        fastcgi_pass unix:/run/php/php8.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }}

    location ~ /\\.(?!well-known).* {{
        deny all;
    }}

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {{
        expires 1y;
        add_header Cache-Control "public, immutable";
    }}

    client_max_body_size 10M;
}}
"""
    write_file(f"/etc/nginx/sites-available/{DOMAIN}", nginx_conf)
    run(f"ln -sf /etc/nginx/sites-available/{DOMAIN} /etc/nginx/sites-enabled/{DOMAIN}")
    run(f"rm -f /etc/nginx/sites-enabled/default")

    apache_vhost = f"""<VirtualHost *:80>
    ServerName {DOMAIN}
    Redirect permanent / https://{DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
    ServerName {DOMAIN}
    DocumentRoot {APP_DIR}/public

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/capitalmonero.crt
    SSLCertificateKeyFile /etc/ssl/private/capitalmonero.key

    <Directory {APP_DIR}/public>
        AllowOverride All
        Require all granted
    </Directory>

    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    ErrorLog ${{APACHE_LOG_DIR}}/{DOMAIN}-error.log
    CustomLog ${{APACHE_LOG_DIR}}/{DOMAIN}-access.log combined
</VirtualHost>
"""
    write_file(f"/etc/apache2/sites-available/{DOMAIN}.conf", apache_vhost)

    tor_conf = f"""HiddenServiceDir /var/lib/tor/capitalmonero/
HiddenServicePort 80 127.0.0.1:80
HiddenServicePort 443 127.0.0.1:443
"""
    write_file("/etc/tor/hidden_service.conf", tor_conf)

    run(f"certbot --nginx -d {DOMAIN} --non-interactive --agree-tos "
        f"-m admin@{DOMAIN} 2>&1 || true")
    run("ufw allow 80/tcp || true")
    run("ufw allow 443/tcp || true")
    run("ufw allow 9050/tcp || true")

    queue_service = f"""[Unit]
Description=CapitalMonero Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory={APP_DIR}
ExecStart=/usr/bin/php artisan queue:work --sleep=3 --tries=3 --max-time=3600
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
"""
    write_file("/etc/systemd/system/capitalmonero-queue.service", queue_service)

    scheduler_service = f"""[Unit]
Description=CapitalMonero Scheduler
After=network.target

[Service]
Type=oneshot
User=www-data
WorkingDirectory={APP_DIR}
ExecStart=/usr/bin/php artisan schedule:run
"""
    write_file("/etc/systemd/system/capitalmonero-scheduler.service", scheduler_service)

    scheduler_timer = """[Unit]
Description=CapitalMonero Scheduler Timer

[Timer]
OnCalendar=*:*:00
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target
"""
    write_file("/etc/systemd/system/capitalmonero-scheduler.timer", scheduler_timer)

    run("systemctl daemon-reload")
    run("systemctl enable capitalmonero-queue || true")
    run("systemctl start capitalmonero-queue || true")
    run("systemctl enable capitalmonero-scheduler.timer || true")
    run("systemctl start capitalmonero-scheduler.timer || true")
    run("nginx -t && systemctl reload nginx || systemctl restart nginx || true")
    print("[OK] Phase 5 complete")



def phase6_application():
    print("\n=== Phase 6: Application Files ===")

    dirs = [
        "app/Http/Controllers", "app/Http/Middleware", "app/Models",
        "app/Console/Commands", "app/Console", "app/Providers", "app/Exceptions",
        "bootstrap/cache", "public/css", "public/js",
        "database/migrations", "database/seeders", "database/factories",
        "resources/views/layouts", "resources/views/auth", "resources/views/offers",
        "resources/views/trades", "resources/views/wallet", "resources/views/messages",
        "resources/views/disputes", "resources/views/admin", "resources/views/errors",
        "resources/views/reviews", "resources/views/reviews/partials",
        "routes", "config",
        "storage/app/public", "storage/framework/cache/data",
        "storage/framework/sessions", "storage/framework/testing",
        "storage/framework/views", "storage/logs",
    ]
    for d in dirs:
        Path(f"{APP_DIR}/{d}").mkdir(parents=True, exist_ok=True)

    # ── artisan ──────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/artisan", r"""#!/usr/bin/env php
<?php
define('LARAVEL_START', microtime(true));
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$status = $kernel->handle(
    $input = new Symfony\Component\Console\Input\ArgvInput,
    new Symfony\Component\Console\Output\ConsoleOutput
);
$kernel->terminate($input, $status);
exit($status);
""", 0o755)

    # ── bootstrap/app.php ────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/bootstrap/app.php", r"""<?php

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

    # ── public/index.php ─────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/public/index.php", r"""<?php

define('LARAVEL_START', microtime(true));

if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

require __DIR__.'/../vendor/autoload.php';

$app = require_once __DIR__.'/../bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$response = $kernel->handle(
    $request = Illuminate\Http\Request::capture()
)->send();

$kernel->terminate($request, $response);
""")

    # ── public/.htaccess ─────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/public/.htaccess", r"""<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
""")

    # ── app/Http/Kernel.php ──────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Http/Kernel.php", r"""<?php

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
        'admin'            => \App\Http\Middleware\AdminMiddleware::class,
        '2fa'              => \App\Http\Middleware\TwoFactorMiddleware::class,
        'brute'            => \App\Http\Middleware\BruteForceMiddleware::class,
    ];
}
""")

    # ── app/Console/Kernel.php ───────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Console/Kernel.php", r"""<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    protected $commands = [
        Commands\CheckDeposits::class,
        Commands\ExpireTrades::class,
        Commands\ProcessEscrow::class,
    ];

    protected function schedule(Schedule $schedule)
    {
        $schedule->command('app:check-deposits')->everyMinute();
        $schedule->command('app:expire-trades')->everyMinute();
        $schedule->command('app:process-escrow')->everyFiveMinutes();
    }

    protected function commands()
    {
        $this->load(__DIR__.'/Commands');
        require base_path('routes/console.php');
    }
}
""")

    # ── app/Exceptions/Handler.php ───────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Exceptions/Handler.php", r"""<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
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
        $this->reportable(function (Throwable $e) {});
    }

    public function render($request, Throwable $exception)
    {
        if ($request->expectsJson()) {
            return response()->json(['error' => $exception->getMessage()], 500);
        }
        return parent::render($request, $exception);
    }
}
""")

    # ── app/Providers/AppServiceProvider.php ─────────────────────────────────
    write_file(f"{APP_DIR}/app/Providers/AppServiceProvider.php", r"""<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Schema;

class AppServiceProvider extends ServiceProvider
{
    public function register() {}

    public function boot()
    {
        Schema::defaultStringLength(191);
    }
}
""")

    # ── app/Providers/AuthServiceProvider.php ────────────────────────────────
    write_file(f"{APP_DIR}/app/Providers/AuthServiceProvider.php", r"""<?php

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

    # ── app/Providers/RouteServiceProvider.php ───────────────────────────────
    write_file(f"{APP_DIR}/app/Providers/RouteServiceProvider.php", r"""<?php

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

        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(5)->by($request->input('email').'|'.$request->ip());
        });
    }
}
""")


    # ── Middleware ────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Http/Middleware/Authenticate.php", r"""<?php

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

    write_file(f"{APP_DIR}/app/Http/Middleware/RedirectIfAuthenticated.php", r"""<?php

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

    write_file(f"{APP_DIR}/app/Http/Middleware/AdminMiddleware.php", r"""<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (!Auth::check() || !Auth::user()->is_admin) {
            abort(403, 'Unauthorized');
        }
        return $next($request);
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/TwoFactorMiddleware.php", r"""<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TwoFactorMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = Auth::user();
        if ($user && $user->two_factor_enabled && !session('2fa_verified')) {
            return redirect()->route('2fa.verify');
        }
        return $next($request);
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/BruteForceMiddleware.php", r"""<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\RateLimiter;

class BruteForceMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $key = 'brute_' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 10)) {
            return response()->json(['error' => 'Too many requests. Try again later.'], 429);
        }
        RateLimiter::hit($key, 600);
        return $next($request);
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/TrustProxies.php", r"""<?php

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
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/VerifyCsrfToken.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    protected $except = [];
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/TrimStrings.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\TrimStrings as Middleware;

class TrimStrings extends Middleware
{
    protected $except = ['current_password', 'password', 'password_confirmation'];
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/PreventRequestsDuringMaintenance.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance as Middleware;

class PreventRequestsDuringMaintenance extends Middleware
{
    protected $except = [];
}
""")

    write_file(f"{APP_DIR}/app/Http/Middleware/EncryptCookies.php", r"""<?php

namespace App\Http\Middleware;

use Illuminate\Cookie\Middleware\EncryptCookies as Middleware;

class EncryptCookies extends Middleware
{
    protected $except = [];
}
""")


    # ── Models ────────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Models/User.php", r"""<?php

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
        'name', 'username', 'email', 'password', 'two_factor_secret',
        'two_factor_enabled', 'is_admin', 'is_banned', 'banned_reason',
        'pgp_key', 'telegram', 'trade_count', 'positive_feedback', 'negative_feedback',
    ];

    protected $hidden = ['password', 'remember_token', 'two_factor_secret'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'two_factor_enabled' => 'boolean',
        'is_admin' => 'boolean',
        'is_banned' => 'boolean',
        'trade_count' => 'integer',
        'positive_feedback' => 'integer',
        'negative_feedback' => 'integer',
    ];

    public function offers()
    {
        return $this->hasMany(Offer::class);
    }

    public function buyTrades()
    {
        return $this->hasMany(Trade::class, 'buyer_id');
    }

    public function sellTrades()
    {
        return $this->hasMany(Trade::class, 'seller_id');
    }

    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'reviewed_id');
    }

    public function disputes()
    {
        return $this->hasMany(Dispute::class, 'opened_by');
    }

    public function getFeedbackScoreAttribute()
    {
        $total = $this->positive_feedback + $this->negative_feedback;
        if ($total === 0) return 0;
        return round(($this->positive_feedback / $total) * 100);
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Offer.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Offer extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'type', 'payment_method', 'currency', 'price_type',
        'fixed_price', 'margin', 'min_amount', 'max_amount', 'terms',
        'is_active', 'trade_count',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'fixed_price' => 'decimal:2',
        'margin' => 'decimal:2',
        'min_amount' => 'decimal:8',
        'max_amount' => 'decimal:8',
        'trade_count' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function trades()
    {
        return $this->hasMany(Trade::class);
    }

    public function getEffectivePriceAttribute()
    {
        if ($this->price_type === 'fixed') {
            return $this->fixed_price;
        }
        return null;
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Trade.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Trade extends Model
{
    use HasFactory;

    protected $fillable = [
        'offer_id', 'buyer_id', 'seller_id', 'amount_xmr', 'amount_fiat',
        'currency', 'price', 'status', 'trade_hash', 'escrow_address',
        'payment_window', 'funded_at', 'payment_sent_at', 'completed_at', 'cancelled_at',
    ];

    protected $casts = [
        'amount_xmr' => 'decimal:12',
        'amount_fiat' => 'decimal:2',
        'price' => 'decimal:2',
        'payment_window' => 'integer',
        'funded_at' => 'datetime',
        'payment_sent_at' => 'datetime',
        'completed_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    const STATUS_PENDING   = 'pending';
    const STATUS_FUNDED    = 'funded';
    const STATUS_PAID      = 'payment_sent';
    const STATUS_COMPLETED = 'completed';
    const STATUS_DISPUTED  = 'disputed';
    const STATUS_CANCELLED = 'cancelled';

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

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function dispute()
    {
        return $this->hasOne(Dispute::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Wallet.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Wallet extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'address', 'view_key', 'balance', 'locked_balance'];

    protected $casts = [
        'balance' => 'decimal:12',
        'locked_balance' => 'decimal:12',
    ];

    protected $hidden = ['view_key'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getAvailableBalanceAttribute()
    {
        return max('0', bcsub((string)$this->balance, (string)$this->locked_balance, 12));
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Message.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = ['trade_id', 'user_id', 'content', 'is_system', 'is_file', 'file_path'];

    protected $casts = [
        'is_system' => 'boolean',
        'is_file' => 'boolean',
    ];

    public function trade()
    {
        return $this->belongsTo(Trade::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Dispute.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Dispute extends Model
{
    use HasFactory;

    protected $fillable = [
        'trade_id', 'opened_by', 'reason', 'details',
        'status', 'admin_id', 'resolution', 'resolved_at',
    ];

    protected $casts = [
        'resolved_at' => 'datetime',
    ];

    public function trade()
    {
        return $this->belongsTo(Trade::class);
    }

    public function opener()
    {
        return $this->belongsTo(User::class, 'opened_by');
    }

    public function messages()
    {
        return $this->hasMany(DisputeMessage::class);
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Review.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    use HasFactory;

    protected $fillable = ['trade_id', 'reviewer_id', 'reviewed_id', 'rating', 'comment'];

    protected $casts = ['rating' => 'integer'];

    public function trade()
    {
        return $this->belongsTo(Trade::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }

    public function reviewed()
    {
        return $this->belongsTo(User::class, 'reviewed_id');
    }
}
""")


    # ── Controllers ───────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Http/Controllers/AuthController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;
use PragmaRX\Google2FA\Google2FA;

class AuthController extends Controller
{
    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $key = 'login_' . $request->ip();
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            throw ValidationException::withMessages([
                'email' => "Too many login attempts. Try again in {$seconds} seconds.",
            ]);
        }

        if (!Auth::attempt($request->only('email', 'password'), $request->boolean('remember'))) {
            RateLimiter::hit($key, 60);
            throw ValidationException::withMessages([
                'email' => 'The provided credentials are incorrect.',
            ]);
        }

        RateLimiter::clear($key);
        $request->session()->regenerate();

        $user = Auth::user();
        if ($user->is_banned) {
            Auth::logout();
            return back()->withErrors(['email' => 'Your account has been suspended: ' . $user->banned_reason]);
        }

        if ($user->two_factor_enabled) {
            return redirect()->route('2fa.verify');
        }

        return redirect()->intended('/dashboard');
    }

    public function showRegister()
    {
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:100',
            'username' => 'required|string|max:30|unique:users|alpha_dash',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'username' => $request->username,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        Wallet::create([
            'user_id'        => $user->id,
            'address'        => '',
            'balance'        => 0,
            'locked_balance' => 0,
        ]);

        Auth::login($user);
        $request->session()->regenerate();

        return redirect('/dashboard')->with('success', 'Welcome to CapitalMonero!');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/');
    }

    public function showTwoFactor()
    {
        if (!Auth::check()) {
            return redirect()->route('login');
        }
        return view('auth.two-factor');
    }

    public function verifyTwoFactor(Request $request)
    {
        $request->validate(['code' => 'required|string|size:6']);
        $user = Auth::user();
        $g2fa = new Google2FA();
        $valid = $g2fa->verifyKey($user->two_factor_secret, $request->code);
        if (!$valid) {
            return back()->withErrors(['code' => 'Invalid 2FA code.']);
        }
        session(['2fa_verified' => true]);
        return redirect()->intended('/dashboard');
    }

    public function enableTwoFactor(Request $request)
    {
        $user = Auth::user();
        $g2fa = new Google2FA();
        $secret = $g2fa->generateSecretKey();
        $user->update(['two_factor_secret' => $secret, 'two_factor_enabled' => false]);
        $qrUrl = $g2fa->getQRCodeUrl('CapitalMonero', $user->email, $secret);
        return view('auth.2fa-setup', compact('secret', 'qrUrl'));
    }

    public function disableTwoFactor(Request $request)
    {
        $request->validate(['password' => 'required|string']);
        $user = Auth::user();
        if (!Hash::check($request->password, $user->password)) {
            return back()->withErrors(['password' => 'Incorrect password.']);
        }
        $user->update(['two_factor_secret' => null, 'two_factor_enabled' => false]);
        session()->forget('2fa_verified');
        return back()->with('success', '2FA has been disabled.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/HomeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HomeController extends Controller
{
    public function index()
    {
        $buyOffers  = Offer::where('type', 'buy')->where('is_active', true)
            ->with('user')->latest()->take(6)->get();
        $sellOffers = Offer::where('type', 'sell')->where('is_active', true)
            ->with('user')->latest()->take(6)->get();
        return view('home', compact('buyOffers', 'sellOffers'));
    }

    public function dashboard()
    {
        $user = Auth::user();
        $recentTrades = Trade::where('buyer_id', $user->id)
            ->orWhere('seller_id', $user->id)
            ->with(['buyer', 'seller', 'offer'])
            ->latest()
            ->take(5)
            ->get();
        $activeOffers = $user->offers()->where('is_active', true)->count();
        $completedTrades = Trade::where(function ($q) use ($user) {
            $q->where('buyer_id', $user->id)->orWhere('seller_id', $user->id);
        })->where('status', 'completed')->count();
        return view('dashboard', compact('user', 'recentTrades', 'activeOffers', 'completedTrades'));
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/OfferController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OfferController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth')->except(['index', 'show']);
    }

    public function index(Request $request)
    {
        $query = Offer::where('is_active', true)->with('user');
        if ($request->type) {
            $query->where('type', $request->type);
        }
        if ($request->payment_method) {
            $query->where('payment_method', $request->payment_method);
        }
        if ($request->currency) {
            $query->where('currency', $request->currency);
        }
        $offers = $query->latest()->paginate(20);
        return view('offers.index', compact('offers'));
    }

    public function create()
    {
        return view('offers.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'type'           => 'required|in:buy,sell',
            'payment_method' => 'required|string|max:100',
            'currency'       => 'required|string|max:10',
            'price_type'     => 'required|in:fixed,margin',
            'fixed_price'    => 'nullable|numeric|min:0',
            'margin'         => 'nullable|numeric|min:-50|max:50',
            'min_amount'     => 'required|numeric|min:0.001',
            'max_amount'     => 'required|numeric|gt:min_amount',
            'terms'          => 'nullable|string|max:2000',
        ]);

        $offer = Auth::user()->offers()->create($request->all());
        return redirect()->route('offers.show', $offer)->with('success', 'Offer created successfully.');
    }

    public function show(Offer $offer)
    {
        $offer->load('user');
        return view('offers.show', compact('offer'));
    }

    public function edit(Offer $offer)
    {
        $this->authorize('update', $offer);
        return view('offers.edit', compact('offer'));
    }

    public function update(Request $request, Offer $offer)
    {
        $this->authorize('update', $offer);
        $request->validate([
            'min_amount' => 'required|numeric|min:0.001',
            'max_amount' => 'required|numeric|gt:min_amount',
            'terms'      => 'nullable|string|max:2000',
            'is_active'  => 'boolean',
        ]);
        $offer->update($request->only('min_amount', 'max_amount', 'terms', 'is_active', 'fixed_price', 'margin'));
        return redirect()->route('offers.show', $offer)->with('success', 'Offer updated.');
    }

    public function destroy(Offer $offer)
    {
        $this->authorize('delete', $offer);
        $offer->delete();
        return redirect()->route('offers.index')->with('success', 'Offer deleted.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/TradeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Offer;
use App\Models\Trade;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class TradeController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $user = Auth::user();
        $trades = Trade::where('buyer_id', $user->id)
            ->orWhere('seller_id', $user->id)
            ->with(['buyer', 'seller', 'offer'])
            ->latest()
            ->paginate(20);
        return view('trades.index', compact('trades'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'offer_id'    => 'required|exists:offers,id',
            'amount_fiat' => 'required|numeric|min:1',
        ]);

        $offer = Offer::findOrFail($request->offer_id);
        if (!$offer->is_active) {
            return back()->withErrors(['offer_id' => 'This offer is no longer active.']);
        }
        if ($offer->user_id === Auth::id()) {
            return back()->withErrors(['offer_id' => 'You cannot trade your own offer.']);
        }

        $amountXmr = ($offer->price_type === 'fixed' && $offer->fixed_price > 0)
            ? $request->amount_fiat / $offer->fixed_price
            : 0;

        $trade = Trade::create([
            'offer_id'      => $offer->id,
            'buyer_id'      => $offer->type === 'sell' ? Auth::id() : $offer->user_id,
            'seller_id'     => $offer->type === 'sell' ? $offer->user_id : Auth::id(),
            'amount_xmr'    => $amountXmr,
            'amount_fiat'   => $request->amount_fiat,
            'currency'      => $offer->currency,
            'price'         => $offer->fixed_price,
            'status'        => Trade::STATUS_PENDING,
            'trade_hash'    => Str::random(32),
            'payment_window'=> $offer->payment_window ?? 60,
        ]);

        Message::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'content'   => 'Trade started.',
            'is_system' => true,
        ]);

        return redirect()->route('trades.show', $trade)->with('success', 'Trade initiated!');
    }

    public function show(Trade $trade)
    {
        $this->authorizeTradeAccess($trade);
        $trade->load(['buyer', 'seller', 'offer', 'messages.user', 'dispute']);
        return view('trades.show', compact('trade'));
    }

    public function markPaid(Trade $trade)
    {
        $this->authorizeTradeAccess($trade);
        if (Auth::id() !== $trade->buyer_id) {
            abort(403);
        }
        if ($trade->status !== Trade::STATUS_FUNDED) {
            return back()->withErrors(['status' => 'Trade is not in funded state.']);
        }
        $trade->update(['status' => Trade::STATUS_PAID, 'payment_sent_at' => now()]);
        Message::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'content'   => 'Buyer has marked payment as sent.',
            'is_system' => true,
        ]);
        return back()->with('success', 'Payment marked as sent.');
    }

    public function complete(Trade $trade)
    {
        $this->authorizeTradeAccess($trade);
        if (Auth::id() !== $trade->seller_id) {
            abort(403);
        }
        if ($trade->status !== Trade::STATUS_PAID) {
            return back()->withErrors(['status' => 'Trade is not in payment sent state.']);
        }
        $trade->update(['status' => Trade::STATUS_COMPLETED, 'completed_at' => now()]);
        $trade->buyer->increment('trade_count');
        $trade->seller->increment('trade_count');
        Message::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'content'   => 'Trade completed. XMR released to buyer.',
            'is_system' => true,
        ]);
        return back()->with('success', 'Trade completed successfully.');
    }

    public function cancel(Trade $trade)
    {
        $this->authorizeTradeAccess($trade);
        if (!in_array($trade->status, [Trade::STATUS_PENDING, Trade::STATUS_FUNDED])) {
            return back()->withErrors(['status' => 'Trade cannot be cancelled at this stage.']);
        }
        $trade->update(['status' => Trade::STATUS_CANCELLED, 'cancelled_at' => now()]);
        Message::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'content'   => 'Trade has been cancelled.',
            'is_system' => true,
        ]);
        return back()->with('success', 'Trade cancelled.');
    }

    public function dispute(Request $request, Trade $trade)
    {
        $this->authorizeTradeAccess($trade);
        $request->validate(['reason' => 'required|string|max:1000']);
        if (!in_array($trade->status, [Trade::STATUS_FUNDED, Trade::STATUS_PAID])) {
            return back()->withErrors(['status' => 'Trade cannot be disputed at this stage.']);
        }
        $trade->update(['status' => Trade::STATUS_DISPUTED]);
        \App\Models\Dispute::create([
            'trade_id'  => $trade->id,
            'opened_by' => Auth::id(),
            'reason'    => $request->reason,
            'details'   => $request->details ?? '',
            'status'    => 'open',
        ]);
        Message::create([
            'trade_id'  => $trade->id,
            'user_id'   => Auth::id(),
            'content'   => 'A dispute has been opened.',
            'is_system' => true,
        ]);
        return back()->with('success', 'Dispute opened. An admin will review.');
    }

    private function authorizeTradeAccess(Trade $trade)
    {
        $user = Auth::user();
        if ($trade->buyer_id !== $user->id && $trade->seller_id !== $user->id && !$user->is_admin) {
            abort(403);
        }
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/WalletController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class WalletController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $wallet = Auth::user()->wallet;
        if (!$wallet) {
            $wallet = Wallet::create([
                'user_id'        => Auth::id(),
                'address'        => '',
                'balance'        => 0,
                'locked_balance' => 0,
            ]);
        }
        return view('wallet.index', compact('wallet'));
    }

    public function withdraw(Request $request)
    {
        $request->validate([
            'address' => 'required|string|min:95|max:106',
            'amount'  => 'required|numeric|min:0.001',
        ]);

        $wallet = Auth::user()->wallet;
        if (!$wallet || $wallet->available_balance < $request->amount) {
            return back()->withErrors(['amount' => 'Insufficient balance.']);
        }

        $wallet->decrement('balance', $request->amount);
        return back()->with('success', 'Withdrawal request submitted.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/MessageController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Trade;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function store(Request $request, Trade $trade)
    {
        $user = Auth::user();
        if ($trade->buyer_id !== $user->id && $trade->seller_id !== $user->id) {
            abort(403);
        }
        $request->validate(['body' => 'required|string|max:2000']);
        \App\Models\Message::create([
            'sender_id'   => $user->id,
            'receiver_id' => $trade->buyer_id === $user->id ? $trade->seller_id : $trade->buyer_id,
            'trade_id'    => $trade->id,
            'body'        => $request->body,
        ]);
        return back()->with('success', 'Message sent.');
    }

    public function show(\App\Models\User $user)
    {
        $authId   = Auth::id();
        $otherUser = $user;
        $messages = \App\Models\Message::where(function ($q) use ($authId, $user) {
                $q->where('sender_id', $authId)->where('receiver_id', $user->id);
            })->orWhere(function ($q) use ($authId, $user) {
                $q->where('sender_id', $user->id)->where('receiver_id', $authId);
            })
            ->with('sender')
            ->latest()
            ->get()
            ->reverse()
            ->values();
        return view('messages.show', compact('otherUser', 'messages'));
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/DisputeController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Dispute;
use App\Models\Trade;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DisputeController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth', 'admin']);
    }

    public function index()
    {
        $disputes = Dispute::with(['trade', 'opener', 'admin'])
            ->where('status', 'open')
            ->latest()
            ->paginate(20);
        return view('disputes.index', compact('disputes'));
    }

    public function resolve(Request $request, Dispute $dispute)
    {
        $request->validate([
            'resolution' => 'required|string|max:2000',
            'winner'     => 'required|in:buyer,seller',
        ]);

        $dispute->update([
            'resolution'  => $request->resolution,
            'status'      => 'resolved',
            'admin_id'    => Auth::id(),
            'resolved_at' => now(),
        ]);

        $trade = $dispute->trade;
        $status = Trade::STATUS_COMPLETED;
        if ($request->winner === 'buyer') {
            $trade->buyer->increment('positive_feedback');
            $trade->seller->increment('negative_feedback');
        } else {
            $trade->seller->increment('positive_feedback');
            $trade->buyer->increment('negative_feedback');
            $status = Trade::STATUS_CANCELLED;
        }
        $trade->update(['status' => $status]);

        return back()->with('success', 'Dispute resolved.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/ReviewController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Trade;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReviewController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function store(Request $request, Trade $trade)
    {
        $user = Auth::user();
        if ($trade->buyer_id !== $user->id && $trade->seller_id !== $user->id) {
            abort(403);
        }
        if ($trade->status !== Trade::STATUS_COMPLETED) {
            return back()->withErrors(['trade' => 'Can only review completed trades.']);
        }
        $existing = Review::where('trade_id', $trade->id)->where('reviewer_id', $user->id)->first();
        if ($existing) {
            return back()->withErrors(['review' => 'You already reviewed this trade.']);
        }
        $request->validate([
            'rating'  => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:500',
        ]);
        $reviewedId = $trade->buyer_id === $user->id ? $trade->seller_id : $trade->buyer_id;
        $review = Review::create([
            'trade_id'    => $trade->id,
            'reviewer_id' => $user->id,
            'reviewed_id' => $reviewedId,
            'rating'      => $request->rating,
            'comment'     => $request->comment,
        ]);
        $reviewed = $review->reviewed;
        if ($request->rating >= 4) {
            $reviewed->increment('positive_feedback');
        } else {
            $reviewed->increment('negative_feedback');
        }
        return back()->with('success', 'Review submitted.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/AdminController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Offer;
use App\Models\Trade;
use App\Models\Dispute;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function __construct()
    {
        $this->middleware(['auth', 'admin']);
    }

    public function dashboard()
    {
        $stats = [
            'users'      => User::count(),
            'offers'     => Offer::count(),
            'trades'     => Trade::count(),
            'disputes'   => Dispute::where('status', 'open')->count(),
            'completed'  => Trade::where('status', 'completed')->count(),
        ];
        $recentUsers  = User::latest()->take(5)->get();
        $recentTrades = Trade::with(['buyer', 'seller'])->latest()->take(5)->get();
        return view('admin.dashboard', compact('stats', 'recentUsers', 'recentTrades'));
    }

    public function users(Request $request)
    {
        $query = User::query();
        if ($request->search) {
            $query->where('username', 'like', '%' . $request->search . '%')
                  ->orWhere('email', 'like', '%' . $request->search . '%');
        }
        $users = $query->latest()->paginate(30);
        return view('admin.users', compact('users'));
    }

    public function banUser(Request $request, User $user)
    {
        $request->validate(['reason' => 'required|string|max:500']);
        $user->update(['is_banned' => true, 'banned_reason' => $request->reason]);
        return back()->with('success', "User {$user->username} has been banned.");
    }

    public function unbanUser(User $user)
    {
        $user->update(['is_banned' => false, 'banned_reason' => null]);
        return back()->with('success', "User {$user->username} has been unbanned.");
    }

    public function offers()
    {
        $offers = Offer::with('user')->latest()->paginate(30);
        return view('admin.offers', compact('offers'));
    }

    public function trades()
    {
        $trades = Trade::with(['buyer', 'seller'])->latest()->paginate(30);
        return view('admin.trades', compact('trades'));
    }

    public function editUser(User $user)
    {
        return view('admin.user-edit', compact('user'));
    }

    public function updateUser(Request $request, User $user)
    {
        $request->validate([
            'name'      => 'required|string|max:255',
            'email'     => 'required|email|unique:users,email,' . $user->id,
            'role'      => 'required|in:user,moderator,admin',
            'is_active' => 'boolean',
        ]);
        $user->update([
            'name'      => $request->name,
            'email'     => $request->email,
            'role'      => $request->role,
            'is_active' => $request->boolean('is_active'),
        ]);
        return redirect()->route('admin.users')->with('success', "User {$user->username} updated.");
    }

    public function settings()
    {
        $settings = \App\Models\Setting::all();
        return view('admin.settings', compact('settings'));
    }

    public function updateSettings(Request $request)
    {
        foreach ($request->input('settings', []) as $key => $value) {
            \App\Models\Setting::set($key, $value);
        }
        return back()->with('success', 'Settings saved.');
    }
}
""")

    write_file(f"{APP_DIR}/app/Console/Commands/ProcessScheduledPayments.php", r"""<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Trade;

class ProcessScheduledPayments extends Command
{
    protected $signature   = 'payments:process';
    protected $description = 'Process scheduled and expired payments';

    public function handle()
    {
        $expired = Trade::where('status', 'pending')
            ->whereRaw('TIMESTAMPDIFF(MINUTE, created_at, NOW()) > payment_window')
            ->get();
        foreach ($expired as $trade) {
            $trade->update(['status' => 'cancelled', 'cancelled_at' => now()]);
            $this->info("Cancelled expired trade #{$trade->id}");
        }
        $this->info('Payment processing complete.');
        return 0;
    }
}
""")


    # ── Migration ─────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/database/migrations/2021_01_01_000000_create_all_tables.php", r"""<?php
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
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->enum('role', ['user', 'admin', 'moderator'])->default('user');
            $table->boolean('is_active')->default(true);
            $table->boolean('two_factor_enabled')->default(false);
            $table->text('two_factor_secret')->nullable();
            $table->decimal('btc_balance', 18, 8)->default(0);
            $table->decimal('xmr_balance', 18, 12)->default(0);
            $table->decimal('ltc_balance', 18, 8)->default(0);
            $table->decimal('eth_balance', 18, 10)->default(0);
            $table->decimal('escrow_btc', 18, 8)->default(0);
            $table->decimal('escrow_xmr', 18, 12)->default(0);
            $table->decimal('escrow_ltc', 18, 8)->default(0);
            $table->decimal('escrow_eth', 18, 10)->default(0);
            $table->string('btc_deposit_address')->nullable();
            $table->string('xmr_deposit_address')->nullable();
            $table->string('ltc_deposit_address')->nullable();
            $table->string('eth_deposit_address')->nullable();
            $table->unsignedInteger('completed_trades')->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->text('bio')->nullable();
            $table->string('avatar')->nullable();
            $table->string('country', 2)->nullable();
            $table->string('preferred_currency', 10)->default('USD');
            $table->unsignedInteger('login_attempts')->default(0);
            $table->timestamp('locked_until')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->rememberToken();
            $table->timestamps();
        });

        Schema::create('password_resets', function (Blueprint $table) {
            $table->string('email')->index();
            $table->string('token');
            $table->timestamp('created_at')->nullable();
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

        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->morphs('tokenable');
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->foreignId('user_id')->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });

        Schema::create('offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['buy', 'sell']);
            $table->enum('crypto', ['BTC', 'XMR', 'LTC', 'ETH'])->default('XMR');
            $table->string('fiat_currency', 10)->default('USD');
            $table->enum('price_type', ['fixed', 'margin'])->default('fixed');
            $table->decimal('price_margin', 6, 2)->nullable();
            $table->decimal('fixed_price', 18, 2)->nullable();
            $table->decimal('min_amount', 18, 8);
            $table->decimal('max_amount', 18, 8);
            $table->string('payment_method');
            $table->unsignedInteger('payment_window')->default(60);
            $table->text('terms')->nullable();
            $table->string('country', 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('trade_count')->default(0);
            $table->timestamps();
        });

        Schema::create('trades', function (Blueprint $table) {
            $table->id();
            $table->string('trade_id')->unique();
            $table->foreignId('offer_id')->constrained()->onDelete('cascade');
            $table->foreignId('buyer_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('seller_id')->constrained('users')->onDelete('cascade');
            $table->enum('crypto', ['BTC', 'XMR', 'LTC', 'ETH'])->default('XMR');
            $table->decimal('crypto_amount', 18, 12);
            $table->decimal('fiat_amount', 18, 2);
            $table->string('fiat_currency', 10)->default('USD');
            $table->string('payment_method');
            $table->enum('status', ['open', 'escrow_funded', 'paid', 'released', 'disputed', 'cancelled', 'completed', 'expired'])->default('open');
            $table->string('escrow_address')->nullable();
            $table->string('escrow_txid')->nullable();
            $table->string('release_txid')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('released_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('crypto', 10);
            $table->string('address')->nullable();
            $table->decimal('balance', 18, 12)->default(0);
            $table->decimal('locked_balance', 18, 12)->default(0);
            $table->timestamps();
            $table->unique(['user_id', 'crypto']);
        });

        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('wallet_id')->constrained()->onDelete('cascade');
            $table->string('txid')->nullable();
            $table->string('crypto', 10);
            $table->enum('type', ['deposit', 'withdrawal', 'escrow_lock', 'escrow_release', 'escrow_refund', 'trade', 'swap']);
            $table->decimal('amount', 18, 12);
            $table->decimal('fee', 18, 12)->default(0);
            $table->string('address')->nullable();
            $table->enum('status', ['pending', 'confirming', 'confirmed', 'failed'])->default('pending');
            $table->unsignedInteger('confirmations')->default(0);
            $table->unsignedInteger('required_confirmations')->default(6);
            $table->timestamps();
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('opened_by')->constrained('users')->onDelete('cascade');
            $table->foreignId('resolved_by')->nullable()->constrained('users')->onDelete('set null');
            $table->foreignId('assigned_to')->nullable()->constrained('users')->onDelete('set null');
            $table->text('reason');
            $table->text('evidence_text')->nullable();
            $table->text('resolution')->nullable();
            $table->text('resolution_notes')->nullable();
            $table->enum('status', ['open', 'under_review', 'resolved', 'closed'])->default('open');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('dispute_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('dispute_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->text('message');
            $table->string('attachment')->nullable();
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->json('data')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sender_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('receiver_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('trade_id')->nullable()->constrained()->onDelete('set null');
            $table->text('body');
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('trade_id')->constrained()->onDelete('cascade');
            $table->foreignId('reviewer_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('reviewed_id')->constrained('users')->onDelete('cascade');
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamps();
            $table->unique(['trade_id', 'reviewer_id']);
        });

        Schema::create('images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('imageable_id');
            $table->string('imageable_type');
            $table->string('path');
            $table->string('original_name');
            $table->string('mime_type');
            $table->unsignedInteger('size');
            $table->timestamps();
        });

        Schema::create('swaps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('from_crypto', 10);
            $table->string('to_crypto', 10);
            $table->decimal('from_amount', 18, 12);
            $table->decimal('to_amount', 18, 12);
            $table->decimal('rate', 18, 12);
            $table->decimal('fee', 18, 12)->default(0);
            $table->enum('status', ['pending', 'completed', 'failed'])->default('pending');
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('login_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');
            $table->string('ip_address', 45);
            $table->text('user_agent')->nullable();
            $table->boolean('success')->default(false);
            $table->timestamps();
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('settings');
        Schema::dropIfExists('login_logs');
        Schema::dropIfExists('swaps');
        Schema::dropIfExists('images');
        Schema::dropIfExists('reviews');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('dispute_messages');
        Schema::dropIfExists('disputes');
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('wallets');
        Schema::dropIfExists('trades');
        Schema::dropIfExists('offers');
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('password_resets');
        Schema::dropIfExists('users');
    }
}
""")

    # ── DatabaseSeeder ────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/database/seeders/DatabaseSeeder.php", r"""<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Setting;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        User::firstOrCreate(
            ['email' => 'admin@capitalmonero.com'],
            [
                'name'      => 'Administrator',
                'username'  => 'admin',
                'password'  => Hash::make('ChangeMe123!'),
                'role'      => 'admin',
                'is_active' => true,
            ]
        );

        $defaults = [
            'site_name'          => 'CapitalMonero',
            'site_description'   => 'P2P Crypto Exchange',
            'trading_fee_pct'    => '1.00',
            'min_trade_usd'      => '10',
            'max_trade_usd'      => '10000',
            'escrow_confirmations' => '10',
            'maintenance_mode'   => '0',
        ];
        foreach ($defaults as $key => $value) {
            Setting::firstOrCreate(['key' => $key], ['value' => $value]);
        }
    }
}
""")


    # ── Routes ────────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/routes/web.php", r"""<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\OfferController;
use App\Http\Controllers\TradeController;
use App\Http\Controllers\WalletController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\DisputeController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\SwapController;
use App\Http\Controllers\ImageController;

Route::get('/', [HomeController::class, 'index'])->name('home');

Route::middleware('guest')->group(function () {
    Route::get('/login',    [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login',   [AuthController::class, 'login'])->middleware('throttle:login');
    Route::get('/register', [AuthController::class, 'showRegister'])->name('register');
    Route::post('/register',[AuthController::class, 'register']);
});

Route::middleware('auth')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    Route::get('/2fa/verify',  [AuthController::class, 'showTwoFactor'])->name('2fa.verify');
    Route::post('/2fa/verify', [AuthController::class, 'verifyTwoFactor'])->name('2fa.verify.post');
    Route::get('/2fa/setup',   [AuthController::class, 'enableTwoFactor'])->name('2fa.setup');
    Route::get('/2fa/enable',  [AuthController::class, 'enableTwoFactor'])->name('2fa.enable');
    Route::post('/2fa/disable',[AuthController::class, 'disableTwoFactor'])->name('2fa.disable');

    Route::middleware('2fa')->group(function () {
        Route::get('/dashboard', [HomeController::class, 'dashboard'])->name('dashboard');

        Route::resource('offers', OfferController::class)->except(['index', 'show']);
        Route::post('/trades',                [TradeController::class, 'store'])->name('trades.store');
        Route::get('/trades',                 [TradeController::class, 'index'])->name('trades.index');
        Route::get('/trades/{trade}',         [TradeController::class, 'show'])->name('trades.show');
        Route::post('/trades/{trade}/paid',   [TradeController::class, 'markPaid'])->name('trades.paid');
        Route::post('/trades/{trade}/complete',[TradeController::class,'complete'])->name('trades.complete');
        Route::post('/trades/{trade}/cancel', [TradeController::class, 'cancel'])->name('trades.cancel');
        Route::post('/trades/{trade}/dispute',[TradeController::class, 'dispute'])->name('trades.dispute');

        Route::post('/trades/{trade}/messages',[MessageController::class,'store'])->name('messages.store');
        Route::get('/messages/{user}',        [MessageController::class,'show'])->name('messages.show');

        Route::post('/trades/{trade}/reviews', [ReviewController::class, 'store'])->name('reviews.store');

        Route::get('/wallet',              [WalletController::class, 'index'])->name('wallet.index');
        Route::post('/wallet/withdraw',    [WalletController::class, 'withdraw'])->name('wallet.withdraw');
        Route::get('/wallet/swap',         [SwapController::class, 'index'])->name('wallet.swap');
        Route::post('/wallet/swap',        [SwapController::class, 'store'])->name('wallet.swap.store');
        Route::get('/wallet/swap/history', [SwapController::class, 'history'])->name('wallet.swap.history');

        Route::post('/images', [ImageController::class, 'store'])->name('images.store');

        Route::get('/disputes/{dispute}',  [DisputeController::class, 'show'])->name('disputes.show');
    });
});

Route::resource('offers', OfferController::class)->only(['index', 'show']);

Route::middleware(['auth', 'admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/',           [AdminController::class, 'dashboard'])->name('dashboard');
    Route::get('/users',      [AdminController::class, 'users'])->name('users');
    Route::get('/users/{user}/edit', [AdminController::class, 'editUser'])->name('users.edit');
    Route::put('/users/{user}',      [AdminController::class, 'updateUser'])->name('users.update');
    Route::post('/users/{user}/ban',  [AdminController::class, 'banUser'])->name('users.ban');
    Route::post('/users/{user}/unban',[AdminController::class, 'unbanUser'])->name('users.unban');
    Route::get('/offers',     [AdminController::class, 'offers'])->name('offers');
    Route::get('/trades',     [AdminController::class, 'trades'])->name('trades');
    Route::get('/disputes',   [DisputeController::class, 'index'])->name('disputes');
    Route::get('/disputes/{dispute}', [DisputeController::class, 'show'])->name('disputes.show');
    Route::post('/disputes/{dispute}/resolve', [DisputeController::class, 'resolve'])->name('disputes.resolve');
    Route::get('/settings',   [AdminController::class, 'settings'])->name('settings');
    Route::post('/settings',  [AdminController::class, 'updateSettings'])->name('settings.update');
});
""")

    write_file(f"{APP_DIR}/routes/api.php", r"""<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});
""")

    write_file(f"{APP_DIR}/routes/console.php", r"""<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');
""")


    # ── Config files ──────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/config/app.php", r"""<?php

return [
    'name'            => env('APP_NAME', 'CapitalMonero'),
    'env'             => env('APP_ENV', 'production'),
    'debug'           => (bool) env('APP_DEBUG', false),
    'url'             => env('APP_URL', 'http://localhost'),
    'asset_url'       => env('ASSET_URL', null),
    'timezone'        => 'UTC',
    'locale'          => 'en',
    'fallback_locale' => 'en',
    'faker_locale'    => 'en_US',
    'key'             => env('APP_KEY'),
    'cipher'          => 'AES-256-CBC',
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
        App\Providers\RouteServiceProvider::class,
        Fruitcake\Cors\CorsServiceProvider::class,
    ],
    'aliases'         => [
        'App'       => Illuminate\Support\Facades\App::class,
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
        'Log'       => Illuminate\Support\Facades\Log::class,
        'Mail'      => Illuminate\Support\Facades\Mail::class,
        'Queue'     => Illuminate\Support\Facades\Queue::class,
        'Redirect'  => Illuminate\Support\Facades\Redirect::class,
        'Request'   => Illuminate\Support\Facades\Request::class,
        'Response'  => Illuminate\Support\Facades\Response::class,
        'Route'     => Illuminate\Support\Facades\Route::class,
        'Schema'    => Illuminate\Support\Facades\Schema::class,
        'Session'   => Illuminate\Support\Facades\Session::class,
        'Storage'   => Illuminate\Support\Facades\Storage::class,
        'URL'       => Illuminate\Support\Facades\URL::class,
        'Validator' => Illuminate\Support\Facades\Validator::class,
        'View'      => Illuminate\Support\Facades\View::class,
    ],
];
""")

    write_file(f"{APP_DIR}/config/auth.php", r"""<?php

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

    write_file(f"{APP_DIR}/config/database.php", r"""<?php

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
        'client' => env('REDIS_CLIENT', 'phpredis'),
        'default' => [
            'host'     => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port'     => env('REDIS_PORT', 6379),
            'database' => env('REDIS_DB', 0),
        ],
    ],
];
""")

    write_file(f"{APP_DIR}/config/session.php", r"""<?php

return [
    'driver'          => env('SESSION_DRIVER', 'file'),
    'lifetime'        => env('SESSION_LIFETIME', 120),
    'expire_on_close' => false,
    'encrypt'         => true,
    'files'           => storage_path('framework/sessions'),
    'connection'      => env('SESSION_CONNECTION', null),
    'table'           => 'sessions',
    'store'           => env('SESSION_STORE', null),
    'lottery'         => [2, 100],
    'cookie'          => env('SESSION_COOKIE', str_slug(env('APP_NAME', 'laravel'), '_').'_session'),
    'path'            => '/',
    'domain'          => env('SESSION_DOMAIN', null),
    'secure'          => env('SESSION_SECURE_COOKIE', true),
    'http_only'       => true,
    'same_site'       => 'lax',
];
""")

    write_file(f"{APP_DIR}/config/cors.php", r"""<?php

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


    # ── CSS ───────────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/public/css/app.css", """\
/* CapitalMonero — Dark Theme */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
  --bg-primary:   #0d0d1a;
  --bg-secondary: #1a1a2e;
  --bg-card:      #16213e;
  --bg-input:     #0f3460;
  --accent:       #e94560;
  --accent-hover: #c73652;
  --success:      #00b894;
  --warning:      #fdcb6e;
  --danger:       #d63031;
  --info:         #0984e3;
  --text-primary: #e0e0e0;
  --text-muted:   #888;
  --border:       #2d2d4e;
  --monero-orange:#f26822;
  --radius:       8px;
  --shadow:       0 4px 20px rgba(0,0,0,0.4);
}

html { scroll-behavior: smooth; }

body {
  background: var(--bg-primary);
  color: var(--text-primary);
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  font-size: 15px;
  line-height: 1.6;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

a { color: var(--accent); text-decoration: none; }
a:hover { color: var(--accent-hover); text-decoration: underline; }

/* ── Navbar ── */
.navbar {
  background: var(--bg-secondary);
  border-bottom: 1px solid var(--border);
  padding: 0 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 60px;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: var(--shadow);
}
.navbar-brand {
  font-size: 1.4rem;
  font-weight: 700;
  color: var(--monero-orange);
  letter-spacing: 1px;
}
.navbar-brand:hover { color: var(--accent); text-decoration: none; }
.navbar-nav { display: flex; align-items: center; gap: 1rem; list-style: none; }
.navbar-nav a { color: var(--text-primary); font-size: 0.9rem; padding: 0.4rem 0.6rem; border-radius: 4px; transition: background 0.2s; }
.navbar-nav a:hover { background: var(--bg-input); text-decoration: none; }
.navbar-toggle { display: none; background: none; border: none; color: var(--text-primary); font-size: 1.5rem; cursor: pointer; }

/* ── Container ── */
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }
.main-content { flex: 1; padding: 2rem 0; }

/* ── Cards ── */
.card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 1.5rem;
  box-shadow: var(--shadow);
  margin-bottom: 1.5rem;
}
.card-header {
  border-bottom: 1px solid var(--border);
  padding-bottom: 1rem;
  margin-bottom: 1rem;
  font-size: 1.1rem;
  font-weight: 600;
  color: var(--monero-orange);
}
.card-title { font-size: 1.2rem; font-weight: 600; margin-bottom: 0.5rem; }

/* ── Forms ── */
.form-group { margin-bottom: 1.2rem; }
.form-label { display: block; margin-bottom: 0.4rem; font-size: 0.9rem; color: var(--text-muted); }
.form-control {
  width: 100%;
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  color: var(--text-primary);
  padding: 0.6rem 0.9rem;
  font-size: 0.95rem;
  transition: border-color 0.2s;
}
.form-control:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px rgba(233,69,96,0.2); }
.form-control::placeholder { color: var(--text-muted); }
select.form-control { cursor: pointer; }
textarea.form-control { resize: vertical; min-height: 100px; }
.form-text { font-size: 0.82rem; color: var(--text-muted); margin-top: 0.3rem; }
.invalid-feedback { color: var(--danger); font-size: 0.85rem; margin-top: 0.3rem; display: block; }

/* ── Buttons ── */
.btn {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 1.2rem;
  border-radius: var(--radius);
  border: none;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  transition: background 0.2s, transform 0.1s;
  text-decoration: none;
}
.btn:active { transform: scale(0.97); }
.btn-primary   { background: var(--accent);   color: #fff; }
.btn-primary:hover { background: var(--accent-hover); text-decoration: none; color: #fff; }
.btn-success   { background: var(--success);  color: #fff; }
.btn-success:hover { background: #00a381; text-decoration: none; color: #fff; }
.btn-danger    { background: var(--danger);   color: #fff; }
.btn-danger:hover  { background: #b71c1c; text-decoration: none; color: #fff; }
.btn-warning   { background: var(--warning);  color: #333; }
.btn-warning:hover { background: #e0b050; text-decoration: none; color: #333; }
.btn-secondary { background: var(--bg-input); color: var(--text-primary); border: 1px solid var(--border); }
.btn-secondary:hover { background: #1a3a5c; text-decoration: none; color: var(--text-primary); }
.btn-sm { padding: 0.3rem 0.8rem; font-size: 0.82rem; }
.btn-lg { padding: 0.8rem 2rem; font-size: 1rem; }
.btn-block { width: 100%; justify-content: center; }

/* ── Alerts ── */
.alert { padding: 0.9rem 1.2rem; border-radius: var(--radius); margin-bottom: 1rem; font-size: 0.92rem; border: 1px solid transparent; }
.alert-success { background: rgba(0,184,148,0.15); border-color: var(--success); color: var(--success); }
.alert-danger  { background: rgba(214,48,49,0.15);  border-color: var(--danger);  color: var(--danger); }
.alert-warning { background: rgba(253,203,110,0.15);border-color: var(--warning); color: var(--warning); }
.alert-info    { background: rgba(9,132,227,0.15);  border-color: var(--info);    color: var(--info); }

/* ── Badges ── */
.badge { display: inline-block; padding: 0.25rem 0.6rem; border-radius: 50px; font-size: 0.78rem; font-weight: 700; }
.badge-success { background: rgba(0,184,148,0.2); color: var(--success); }
.badge-danger  { background: rgba(214,48,49,0.2);  color: var(--danger); }
.badge-warning { background: rgba(253,203,110,0.2);color: var(--warning); }
.badge-info    { background: rgba(9,132,227,0.2);  color: var(--info); }
.badge-secondary{background: var(--bg-input); color: var(--text-muted); }
.badge-buy  { background: rgba(0,184,148,0.2); color: var(--success); }
.badge-sell { background: rgba(233,69,96,0.2); color: var(--accent); }

/* ── Tables ── */
.table-container { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 0.75rem 1rem; text-align: left; border-bottom: 1px solid var(--border); }
th { background: var(--bg-secondary); color: var(--text-muted); font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.5px; }
tr:hover td { background: rgba(255,255,255,0.02); }

/* ── Pagination ── */
.pagination { display: flex; gap: 0.5rem; align-items: center; justify-content: center; margin-top: 1.5rem; flex-wrap: wrap; }
.pagination a, .pagination span {
  padding: 0.4rem 0.8rem; border-radius: var(--radius); border: 1px solid var(--border);
  color: var(--text-primary); background: var(--bg-card); font-size: 0.9rem;
}
.pagination a:hover { background: var(--accent); border-color: var(--accent); color: #fff; text-decoration: none; }
.pagination .active { background: var(--accent); border-color: var(--accent); color: #fff; }

/* ── Grid ── */
.row { display: flex; flex-wrap: wrap; gap: 1.5rem; }
.col { flex: 1; min-width: 200px; }
.col-md-4 { flex: 0 0 calc(33.333% - 1rem); min-width: 200px; }
.col-md-6 { flex: 0 0 calc(50% - 0.75rem); min-width: 200px; }
.col-md-8 { flex: 0 0 calc(66.666% - 0.75rem); min-width: 200px; }

/* ── Stats Cards ── */
.stat-card { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 1.5rem; text-align: center; }
.stat-value { font-size: 2rem; font-weight: 700; color: var(--monero-orange); }
.stat-label { font-size: 0.85rem; color: var(--text-muted); margin-top: 0.3rem; }

/* ── Hero ── */
.hero { background: linear-gradient(135deg, var(--bg-secondary) 0%, #0f3460 100%); padding: 5rem 0; text-align: center; border-bottom: 1px solid var(--border); }
.hero h1 { font-size: 3rem; font-weight: 800; color: var(--monero-orange); margin-bottom: 1rem; }
.hero p  { font-size: 1.2rem; color: var(--text-muted); max-width: 600px; margin: 0 auto 2rem; }
.hero-buttons { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }

/* ── Trade Chat ── */
.chat-box { background: var(--bg-primary); border: 1px solid var(--border); border-radius: var(--radius); height: 400px; overflow-y: auto; padding: 1rem; display: flex; flex-direction: column; gap: 0.75rem; }
.chat-msg { padding: 0.6rem 1rem; border-radius: var(--radius); max-width: 80%; }
.chat-msg.mine { background: var(--accent); color: #fff; align-self: flex-end; }
.chat-msg.theirs { background: var(--bg-input); align-self: flex-start; }
.chat-msg.system { background: rgba(255,255,255,0.05); color: var(--text-muted); align-self: center; font-size: 0.85rem; font-style: italic; text-align: center; max-width: 100%; }
.chat-meta { font-size: 0.75rem; opacity: 0.7; margin-top: 0.25rem; }

/* ── Offer Grid ── */
.offers-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.2rem; }
.offer-card { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 1.2rem; transition: border-color 0.2s, transform 0.2s; }
.offer-card:hover { border-color: var(--accent); transform: translateY(-2px); }
.offer-price { font-size: 1.5rem; font-weight: 700; color: var(--success); }
.offer-method { color: var(--text-muted); font-size: 0.88rem; margin: 0.3rem 0; }
.offer-limits { font-size: 0.9rem; }

/* ── Trade Status ── */
.status-pending   { color: var(--warning); }
.status-funded    { color: var(--info); }
.status-payment_sent { color: var(--monero-orange); }
.status-completed { color: var(--success); }
.status-disputed  { color: var(--danger); }
.status-cancelled { color: var(--text-muted); }

/* ── Modal ── */
.modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); z-index: 200; align-items: center; justify-content: center; }
.modal-overlay.active { display: flex; }
.modal { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 2rem; max-width: 500px; width: 90%; }
.modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
.modal-title { font-size: 1.2rem; font-weight: 700; }
.modal-close { background: none; border: none; color: var(--text-muted); font-size: 1.4rem; cursor: pointer; line-height: 1; }

/* ── Footer ── */
footer { background: var(--bg-secondary); border-top: 1px solid var(--border); padding: 2rem 0; margin-top: auto; text-align: center; color: var(--text-muted); font-size: 0.88rem; }
footer a { color: var(--text-muted); }
footer a:hover { color: var(--accent); }
.footer-links { display: flex; justify-content: center; gap: 1.5rem; margin-bottom: 0.75rem; flex-wrap: wrap; }
.onion-badge { font-size: 0.78rem; background: rgba(242,104,34,0.1); border: 1px solid var(--monero-orange); color: var(--monero-orange); padding: 0.2rem 0.6rem; border-radius: 4px; margin-top: 0.5rem; word-break: break-all; display: inline-block; }

/* ── Utilities ── */
.mt-1 { margin-top: 0.5rem; }  .mt-2 { margin-top: 1rem; }  .mt-3 { margin-top: 1.5rem; }  .mt-4 { margin-top: 2rem; }
.mb-1 { margin-bottom: 0.5rem; }.mb-2 { margin-bottom: 1rem; }.mb-3 { margin-bottom: 1.5rem; }.mb-4 { margin-bottom: 2rem; }
.text-center { text-align: center; }
.text-muted { color: var(--text-muted); }
.text-success { color: var(--success); }
.text-danger  { color: var(--danger); }
.text-warning { color: var(--warning); }
.text-orange  { color: var(--monero-orange); }
.d-flex { display: flex; }
.align-items-center { align-items: center; }
.justify-content-between { justify-content: space-between; }
.gap-1 { gap: 0.5rem; }
.gap-2 { gap: 1rem; }
.flex-wrap { flex-wrap: wrap; }
.w-100 { width: 100%; }
.font-weight-bold { font-weight: 700; }
.section-title { font-size: 1.4rem; font-weight: 700; margin-bottom: 1.5rem; color: var(--text-primary); border-left: 4px solid var(--accent); padding-left: 0.75rem; }
.divider { border: none; border-top: 1px solid var(--border); margin: 1.5rem 0; }

/* ── Responsive ── */
@media (max-width: 768px) {
  .navbar-nav { display: none; flex-direction: column; position: absolute; top: 60px; left: 0; right: 0; background: var(--bg-secondary); border-bottom: 1px solid var(--border); padding: 1rem; }
  .navbar-nav.open { display: flex; }
  .navbar-toggle { display: block; }
  .hero h1 { font-size: 2rem; }
  .col-md-4, .col-md-6, .col-md-8 { flex: 0 0 100%; }
  .offers-grid { grid-template-columns: 1fr; }
  .row { gap: 1rem; }
}
""")

    # ── JavaScript ────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/public/js/app.js", """\
(function () {
  'use strict';

  // CSRF token setup for fetch/XHR
  const csrf = document.querySelector('meta[name="csrf-token"]');
  if (csrf) {
    window._csrf = csrf.getAttribute('content');
  }

  // Navbar toggle for mobile
  const toggle = document.querySelector('.navbar-toggle');
  const navNav = document.querySelector('.navbar-nav');
  if (toggle && navNav) {
    toggle.addEventListener('click', function () {
      navNav.classList.toggle('open');
    });
  }

  // Auto-dismiss alerts after 5 seconds
  document.querySelectorAll('.alert').forEach(function (el) {
    if (!el.classList.contains('alert-danger')) {
      setTimeout(function () {
        el.style.transition = 'opacity 0.5s';
        el.style.opacity = '0';
        setTimeout(function () { el.remove(); }, 500);
      }, 5000);
    }
  });

  // Confirm dangerous actions
  document.querySelectorAll('[data-confirm]').forEach(function (el) {
    el.addEventListener('click', function (e) {
      if (!confirm(el.getAttribute('data-confirm'))) {
        e.preventDefault();
      }
    });
  });

  // Modal open/close
  document.querySelectorAll('[data-modal]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var target = document.getElementById(btn.getAttribute('data-modal'));
      if (target) target.classList.add('active');
    });
  });
  document.querySelectorAll('.modal-close, .modal-overlay').forEach(function (el) {
    el.addEventListener('click', function (e) {
      if (e.target === el) {
        document.querySelectorAll('.modal-overlay').forEach(function (m) {
          m.classList.remove('active');
        });
      }
    });
  });

  // Trade chat auto-scroll
  var chatBox = document.querySelector('.chat-box');
  if (chatBox) {
    chatBox.scrollTop = chatBox.scrollHeight;
  }

  // Copy to clipboard
  document.querySelectorAll('.copy-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var target = document.getElementById(btn.getAttribute('data-copy'));
      if (target) {
        navigator.clipboard.writeText(target.textContent.trim()).then(function () {
          btn.textContent = 'Copied!';
          setTimeout(function () { btn.textContent = 'Copy'; }, 2000);
        });
      }
    });
  });
})();
""")


    # ── Blade Layout ──────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/layouts/app.blade.php", r"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'CapitalMonero') — P2P Monero Exchange</title>
    <link rel="stylesheet" href="{{ asset('css/app.css') }}">
    @stack('styles')
</head>
<body>
<nav class="navbar">
    <a href="{{ url('/') }}" class="navbar-brand">&#9711; CapitalMonero</a>
    <button class="navbar-toggle" aria-label="Menu">&#9776;</button>
    <ul class="navbar-nav">
        <li><a href="{{ route('offers.index') }}">Browse Offers</a></li>
        @auth
        <li><a href="{{ route('trades.index') }}">My Trades</a></li>
        <li><a href="{{ route('wallet.index') }}">Wallet</a></li>
        <li><a href="{{ route('offers.create') }}">Create Offer</a></li>
        <li><a href="{{ route('dashboard') }}">Dashboard</a></li>
        @if(Auth::user()->is_admin)
        <li><a href="{{ route('admin.dashboard') }}" class="text-warning">Admin</a></li>
        @endif
        <li>
            <form method="POST" action="{{ route('logout') }}" style="display:inline">
                @csrf
                <button type="submit" class="btn btn-sm btn-secondary">Logout</button>
            </form>
        </li>
        @else
        <li><a href="{{ route('login') }}">Login</a></li>
        <li><a href="{{ route('register') }}" class="btn btn-sm btn-primary">Register</a></li>
        @endauth
    </ul>
</nav>

<div class="main-content">
    <div class="container">
        @if(session('success'))
        <div class="alert alert-success mt-2">{{ session('success') }}</div>
        @endif
        @if(session('error'))
        <div class="alert alert-danger mt-2">{{ session('error') }}</div>
        @endif
        @if($errors->any())
        <div class="alert alert-danger mt-2">
            <ul style="margin:0;padding-left:1.2rem">
                @foreach($errors->all() as $error)
                <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        @yield('content')
    </div>
</div>

<footer>
    <div class="container">
        <div class="footer-links">
            <a href="{{ url('/') }}">Home</a>
            <a href="{{ route('offers.index') }}">Offers</a>
            @auth
            <a href="{{ route('trades.index') }}">Trades</a>
            <a href="{{ route('wallet.index') }}">Wallet</a>
            @endauth
        </div>
        <div class="text-muted">&copy; {{ date('Y') }} CapitalMonero — Private P2P Monero Exchange</div>
        <div class="onion-badge">&#127760; Tor: fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion</div>
    </div>
</footer>

<script src="{{ asset('js/app.js') }}"></script>
@stack('scripts')
</body>
</html>
""")

    # ── home.blade.php ────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/home.blade.php", r"""@extends('layouts.app')

@section('title', 'Home')

@section('content')
<div class="hero" style="margin: -2rem -1.5rem 2rem;">
    <h1>&#9711; CapitalMonero</h1>
    <p>Buy and sell Monero (XMR) privately and securely with peer-to-peer trading. No KYC. No middlemen.</p>
    <div class="hero-buttons">
        <a href="{{ route('offers.index', ['type' => 'sell']) }}" class="btn btn-primary btn-lg">Buy XMR</a>
        <a href="{{ route('offers.index', ['type' => 'buy']) }}" class="btn btn-secondary btn-lg">Sell XMR</a>
        @guest
        <a href="{{ route('register') }}" class="btn btn-success btn-lg">Get Started</a>
        @endguest
    </div>
</div>

<div class="row mb-4">
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">&#128274;</div>
            <div class="stat-label">Non-Custodial Escrow</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">&#127760;</div>
            <div class="stat-label">Tor Hidden Service</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">0&#37;</div>
            <div class="stat-label">No KYC Required</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">XMR</div>
            <div class="stat-label">Monero Only</div>
        </div>
    </div>
</div>

<div class="section-title">Latest Buy Offers</div>
<div class="offers-grid mb-4">
    @forelse($buyOffers as $offer)
    <div class="offer-card">
        <div class="d-flex justify-content-between align-items-center mb-1">
            <span class="badge badge-buy">BUY</span>
            <a href="{{ route('offers.show', $offer) }}">{{ $offer->user->username }}</a>
        </div>
        <div class="offer-price">
            @if($offer->fixed_price)
            ${{ number_format($offer->fixed_price, 2) }} {{ $offer->currency }}
            @else
            Market {{ $offer->margin > 0 ? '+' : '' }}{{ $offer->margin }}%
            @endif
        </div>
        <div class="offer-method">{{ $offer->payment_method }}</div>
        <div class="offer-limits text-muted">
            Limit: ${{ number_format($offer->min_amount, 0) }} – ${{ number_format($offer->max_amount, 0) }}
        </div>
        <div class="mt-2">
            <a href="{{ route('offers.show', $offer) }}" class="btn btn-success btn-sm btn-block">Sell XMR</a>
        </div>
    </div>
    @empty
    <p class="text-muted">No buy offers yet. <a href="{{ route('offers.create') }}">Create one</a></p>
    @endforelse
</div>

<div class="section-title">Latest Sell Offers</div>
<div class="offers-grid mb-4">
    @forelse($sellOffers as $offer)
    <div class="offer-card">
        <div class="d-flex justify-content-between align-items-center mb-1">
            <span class="badge badge-sell">SELL</span>
            <a href="{{ route('offers.show', $offer) }}">{{ $offer->user->username }}</a>
        </div>
        <div class="offer-price">
            @if($offer->fixed_price)
            ${{ number_format($offer->fixed_price, 2) }} {{ $offer->currency }}
            @else
            Market {{ $offer->margin > 0 ? '+' : '' }}{{ $offer->margin }}%
            @endif
        </div>
        <div class="offer-method">{{ $offer->payment_method }}</div>
        <div class="offer-limits text-muted">
            Limit: ${{ number_format($offer->min_amount, 0) }} – ${{ number_format($offer->max_amount, 0) }}
        </div>
        <div class="mt-2">
            <a href="{{ route('offers.show', $offer) }}" class="btn btn-primary btn-sm btn-block">Buy XMR</a>
        </div>
    </div>
    @empty
    <p class="text-muted">No sell offers yet. <a href="{{ route('offers.create') }}">Create one</a></p>
    @endforelse
</div>

<div class="text-center mt-3">
    <a href="{{ route('offers.index') }}" class="btn btn-secondary">View All Offers</a>
</div>
@endsection
""")

    # ── dashboard.blade.php ───────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/dashboard.blade.php", r"""@extends('layouts.app')

@section('title', 'Dashboard')

@section('content')
<div class="section-title">Welcome, {{ Auth::user()->username }}</div>

<div class="row mb-4">
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ Auth::user()->trade_count }}</div>
            <div class="stat-label">Total Trades</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value text-success">{{ Auth::user()->positive_feedback }}</div>
            <div class="stat-label">Positive Feedback</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value text-danger">{{ Auth::user()->negative_feedback }}</div>
            <div class="stat-label">Negative Feedback</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ $activeOffers }}</div>
            <div class="stat-label">Active Offers</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ $completedTrades }}</div>
            <div class="stat-label">Completed Trades</div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-8">
        <div class="card">
            <div class="card-header">Recent Trades</div>
            @forelse($recentTrades as $trade)
            <div class="d-flex justify-content-between align-items-center" style="padding: 0.75rem 0; border-bottom: 1px solid var(--border);">
                <div>
                    <a href="{{ route('trades.show', $trade) }}">#{{ $trade->id }}</a>
                    <span class="text-muted" style="font-size:0.85rem;">
                        {{ $trade->buyer_id === Auth::id() ? 'Buying from ' . $trade->seller->username : 'Selling to ' . $trade->buyer->username }}
                    </span>
                </div>
                <div>
                    <span class="text-orange font-weight-bold">{{ number_format($trade->amount_xmr, 4) }} XMR</span>
                    <span class="badge badge-{{ $trade->status === 'completed' ? 'success' : ($trade->status === 'cancelled' ? 'secondary' : ($trade->status === 'disputed' ? 'danger' : 'warning')) }} ml-2">
                        {{ ucfirst(str_replace('_', ' ', $trade->status)) }}
                    </span>
                </div>
            </div>
            @empty
            <p class="text-muted mt-2">No trades yet. <a href="{{ route('offers.index') }}">Browse offers</a> to get started.</p>
            @endforelse
            @if($recentTrades->count())
            <div class="mt-2">
                <a href="{{ route('trades.index') }}" class="btn btn-secondary btn-sm">View All Trades</a>
            </div>
            @endif
        </div>
    </div>
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">Quick Actions</div>
            <div style="display:flex;flex-direction:column;gap:0.75rem">
                <a href="{{ route('offers.create') }}" class="btn btn-primary">Create New Offer</a>
                <a href="{{ route('offers.index') }}" class="btn btn-secondary">Browse Offers</a>
                <a href="{{ route('wallet.index') }}" class="btn btn-secondary">View Wallet</a>
            </div>
        </div>
        <div class="card">
            <div class="card-header">Account Security</div>
            @if(Auth::user()->two_factor_enabled)
            <span class="badge badge-success">2FA Enabled</span>
            <form method="POST" action="{{ route('2fa.disable') }}" class="mt-2">
                @csrf
                <input type="password" name="password" class="form-control mb-2" placeholder="Confirm password" required>
                <button type="submit" class="btn btn-danger btn-sm">Disable 2FA</button>
            </form>
            @else
            <p class="text-muted" style="font-size:0.88rem">2FA is not enabled. Enable it for extra security.</p>
            <a href="{{ route('2fa.enable') }}" class="btn btn-warning btn-sm mt-2">Enable 2FA</a>
            @endif
        </div>
    </div>
</div>
@endsection
""")


    # ── Auth views ────────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/auth/login.blade.php", r"""@extends('layouts.app')

@section('title', 'Login')

@section('content')
<div style="max-width:440px;margin:3rem auto">
    <div class="card">
        <div class="card-header">Sign In to CapitalMonero</div>
        <form method="POST" action="{{ route('login') }}">
            @csrf
            <div class="form-group">
                <label class="form-label">Email Address</label>
                <input type="email" name="email" class="form-control" value="{{ old('email') }}" required autofocus>
            </div>
            <div class="form-group">
                <label class="form-label">Password</label>
                <input type="password" name="password" class="form-control" required>
            </div>
            <div class="form-group">
                <label style="display:flex;align-items:center;gap:0.5rem;cursor:pointer">
                    <input type="checkbox" name="remember" value="1"> Remember Me
                </label>
            </div>
            <button type="submit" class="btn btn-primary btn-block">Sign In</button>
        </form>
        <div class="text-center mt-3" style="font-size:0.9rem">
            Don't have an account? <a href="{{ route('register') }}">Register</a>
        </div>
    </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/auth/register.blade.php", r"""@extends('layouts.app')

@section('title', 'Register')

@section('content')
<div style="max-width:480px;margin:3rem auto">
    <div class="card">
        <div class="card-header">Create Your Account</div>
        <form method="POST" action="{{ route('register') }}">
            @csrf
            <div class="form-group">
                <label class="form-label">Display Name</label>
                <input type="text" name="name" class="form-control" value="{{ old('name') }}" required>
            </div>
            <div class="form-group">
                <label class="form-label">Username</label>
                <input type="text" name="username" class="form-control" value="{{ old('username') }}" required>
                <div class="form-text">Letters, numbers, underscores and dashes only.</div>
            </div>
            <div class="form-group">
                <label class="form-label">Email Address</label>
                <input type="email" name="email" class="form-control" value="{{ old('email') }}" required>
            </div>
            <div class="form-group">
                <label class="form-label">Password</label>
                <input type="password" name="password" class="form-control" required>
                <div class="form-text">Minimum 8 characters.</div>
            </div>
            <div class="form-group">
                <label class="form-label">Confirm Password</label>
                <input type="password" name="password_confirmation" class="form-control" required>
            </div>
            <button type="submit" class="btn btn-primary btn-block">Create Account</button>
        </form>
        <div class="text-center mt-3" style="font-size:0.9rem">
            Already have an account? <a href="{{ route('login') }}">Sign In</a>
        </div>
    </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/auth/two-factor.blade.php", r"""@extends('layouts.app')

@section('title', '2FA Verification')

@section('content')
<div style="max-width:400px;margin:3rem auto">
    <div class="card">
        <div class="card-header">Two-Factor Authentication</div>
        <p class="text-muted mb-3">Enter the 6-digit code from your authenticator app.</p>
        <form method="POST" action="{{ route('2fa.verify.post') }}">
            @csrf
            <div class="form-group">
                <label class="form-label">Authentication Code</label>
                <input type="text" name="code" class="form-control" placeholder="000000"
                    maxlength="6" pattern="[0-9]{6}" autofocus required
                    style="font-size:1.5rem;text-align:center;letter-spacing:0.5rem">
            </div>
            <button type="submit" class="btn btn-primary btn-block">Verify</button>
        </form>
        <form method="POST" action="{{ route('logout') }}" class="mt-3">
            @csrf
            <button type="submit" class="btn btn-secondary btn-block btn-sm">Cancel & Logout</button>
        </form>
    </div>
</div>
@endsection
""")

    # ── Offers views ──────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/offers/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Browse Offers')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3">
    <div class="section-title" style="margin-bottom:0">Browse Offers</div>
    @auth
    <a href="{{ route('offers.create') }}" class="btn btn-primary btn-sm">+ Create Offer</a>
    @endauth
</div>

<div class="card mb-3">
    <form method="GET" action="{{ route('offers.index') }}">
        <div class="row">
            <div class="col">
                <label class="form-label">Type</label>
                <select name="type" class="form-control">
                    <option value="">All</option>
                    <option value="sell" {{ request('type') === 'sell' ? 'selected' : '' }}>Buy XMR (Sell offers)</option>
                    <option value="buy"  {{ request('type') === 'buy'  ? 'selected' : '' }}>Sell XMR (Buy offers)</option>
                </select>
            </div>
            <div class="col">
                <label class="form-label">Payment Method</label>
                <input type="text" name="payment_method" class="form-control"
                    value="{{ request('payment_method') }}" placeholder="e.g. Bank transfer">
            </div>
            <div class="col">
                <label class="form-label">Currency</label>
                <select name="currency" class="form-control">
                    <option value="">All</option>
                    <option value="USD" {{ request('currency') === 'USD' ? 'selected' : '' }}>USD</option>
                    <option value="EUR" {{ request('currency') === 'EUR' ? 'selected' : '' }}>EUR</option>
                    <option value="GBP" {{ request('currency') === 'GBP' ? 'selected' : '' }}>GBP</option>
                </select>
            </div>
            <div class="col" style="display:flex;align-items:flex-end">
                <button type="submit" class="btn btn-primary w-100">Filter</button>
            </div>
        </div>
    </form>
</div>

<div class="offers-grid">
    @forelse($offers as $offer)
    <div class="offer-card">
        <div class="d-flex justify-content-between align-items-center mb-1">
            <span class="badge badge-{{ $offer->type }}">{{ strtoupper($offer->type) }}</span>
            <a href="{{ route('offers.show', $offer) }}">{{ $offer->user->username }}</a>
        </div>
        <div class="offer-price">
            @if($offer->price_type === 'fixed')
            ${{ number_format($offer->fixed_price, 2) }} {{ $offer->currency }}
            @else
            Market {{ $offer->margin >= 0 ? '+' : '' }}{{ $offer->margin }}%
            @endif
        </div>
        <div class="offer-method text-muted">{{ $offer->payment_method }}</div>
        <div class="offer-limits text-muted mb-2">
            Limit: ${{ number_format($offer->min_amount, 0) }} – ${{ number_format($offer->max_amount, 0) }} {{ $offer->currency }}
        </div>
        <div class="text-muted" style="font-size:0.8rem">
            &#10003; {{ $offer->trade_count }} trades &nbsp;
            &#9733; {{ $offer->user->feedback_score }}% feedback
        </div>
        <div class="mt-2">
            <a href="{{ route('offers.show', $offer) }}" class="btn btn-{{ $offer->type === 'sell' ? 'primary' : 'success' }} btn-sm btn-block">
                {{ $offer->type === 'sell' ? 'Buy XMR' : 'Sell XMR' }}
            </a>
        </div>
    </div>
    @empty
    <div class="card text-center">
        <p class="text-muted">No offers found matching your criteria.</p>
        @auth
        <a href="{{ route('offers.create') }}" class="btn btn-primary mt-2">Create First Offer</a>
        @endauth
    </div>
    @endforelse
</div>

<div class="pagination">
    @if($offers->isNotEmpty())
    {{ $offers->withQueryString()->links() }}
    @endif
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/offers/create.blade.php", r"""@extends('layouts.app')

@section('title', 'Create Offer')

@section('content')
<div style="max-width:700px;margin:0 auto">
    <div class="section-title">Create New Offer</div>
    <div class="card">
        <form method="POST" action="{{ route('offers.store') }}">
            @csrf
            <div class="row mb-3">
                <div class="col">
                    <label class="form-label">Offer Type</label>
                    <select name="type" class="form-control" required>
                        <option value="sell" {{ old('type') === 'sell' ? 'selected' : '' }}>Sell XMR (I want to sell Monero)</option>
                        <option value="buy"  {{ old('type') === 'buy'  ? 'selected' : '' }}>Buy XMR (I want to buy Monero)</option>
                    </select>
                </div>
                <div class="col">
                    <label class="form-label">Payment Method</label>
                    <input type="text" name="payment_method" class="form-control"
                        value="{{ old('payment_method') }}"
                        placeholder="e.g. Bank Transfer, PayPal, Cash" required>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col">
                    <label class="form-label">Currency</label>
                    <select name="currency" class="form-control" required>
                        <option value="USD" {{ old('currency', 'USD') === 'USD' ? 'selected' : '' }}>USD</option>
                        <option value="EUR" {{ old('currency') === 'EUR' ? 'selected' : '' }}>EUR</option>
                        <option value="GBP" {{ old('currency') === 'GBP' ? 'selected' : '' }}>GBP</option>
                    </select>
                </div>
                <div class="col">
                    <label class="form-label">Price Type</label>
                    <select name="price_type" class="form-control" required>
                        <option value="fixed"  {{ old('price_type', 'fixed') === 'fixed'  ? 'selected' : '' }}>Fixed Price</option>
                        <option value="margin" {{ old('price_type') === 'margin' ? 'selected' : '' }}>Market Margin</option>
                    </select>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col">
                    <label class="form-label">Fixed Price (if fixed)</label>
                    <input type="number" name="fixed_price" class="form-control"
                        value="{{ old('fixed_price') }}" step="0.01" min="0"
                        placeholder="e.g. 185.00">
                </div>
                <div class="col">
                    <label class="form-label">Margin % (if market)</label>
                    <input type="number" name="margin" class="form-control"
                        value="{{ old('margin') }}" step="0.1" min="-50" max="50"
                        placeholder="e.g. 2.5">
                    <div class="form-text">Positive = above market. Negative = below.</div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col">
                    <label class="form-label">Minimum Amount</label>
                    <input type="number" name="min_amount" class="form-control"
                        value="{{ old('min_amount') }}" step="0.01" min="0.01" required
                        placeholder="e.g. 50">
                </div>
                <div class="col">
                    <label class="form-label">Maximum Amount</label>
                    <input type="number" name="max_amount" class="form-control"
                        value="{{ old('max_amount') }}" step="0.01" min="0.01" required
                        placeholder="e.g. 5000">
                </div>
            </div>

            <div class="form-group">
                <label class="form-label">Trade Terms (optional)</label>
                <textarea name="terms" class="form-control" rows="4"
                    placeholder="Describe your payment requirements, verification steps, etc.">{{ old('terms') }}</textarea>
            </div>

            <button type="submit" class="btn btn-primary btn-block">Create Offer</button>
        </form>
    </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/offers/show.blade.php", r"""@extends('layouts.app')

@section('title', 'Offer Details')

@section('content')
<div style="max-width:800px;margin:0 auto">
    <div class="row">
        <div class="col-md-8">
            <div class="card">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <span class="badge badge-{{ $offer->type }}">{{ strtoupper($offer->type) }} OFFER</span>
                        <span class="text-muted ml-2" style="font-size:0.85rem">by {{ $offer->user->username }}</span>
                    </div>
                    @if(!$offer->is_active)
                    <span class="badge badge-secondary">Inactive</span>
                    @endif
                </div>
                <div class="offer-price mb-2">
                    @if($offer->price_type === 'fixed')
                    ${{ number_format($offer->fixed_price, 2) }} {{ $offer->currency }}
                    @else
                    Market {{ $offer->margin >= 0 ? '+' : '' }}{{ $offer->margin }}% {{ $offer->currency }}
                    @endif
                </div>
                <div class="text-muted mb-1">Payment Method: <strong class="text-primary">{{ $offer->payment_method }}</strong></div>
                <div class="text-muted mb-3">
                    Limits: <strong>${{ number_format($offer->min_amount, 0) }} – ${{ number_format($offer->max_amount, 0) }} {{ $offer->currency }}</strong>
                </div>
                @if($offer->terms)
                <div class="card" style="background:var(--bg-primary)">
                    <div style="font-weight:600;margin-bottom:0.5rem">Trade Terms</div>
                    <p style="white-space:pre-line;font-size:0.92rem">{{ $offer->terms }}</p>
                </div>
                @endif
            </div>

            @auth
            @if(Auth::id() !== $offer->user_id && $offer->is_active)
            <div class="card">
                <div class="card-header">Start Trade</div>
                <form method="POST" action="{{ route('trades.store') }}">
                    @csrf
                    <input type="hidden" name="offer_id" value="{{ $offer->id }}">
                    <div class="form-group">
                        <label class="form-label">Amount ({{ $offer->currency }})</label>
                        <input type="number" name="amount_fiat" class="form-control"
                            step="0.01"
                            min="{{ $offer->min_amount }}"
                            max="{{ $offer->max_amount }}"
                            placeholder="Enter amount in {{ $offer->currency }}" required>
                        <div class="form-text">Limits: ${{ number_format($offer->min_amount,0) }} – ${{ number_format($offer->max_amount,0) }}</div>
                    </div>
                    <button type="submit" class="btn btn-{{ $offer->type === 'sell' ? 'primary' : 'success' }} btn-block">
                        {{ $offer->type === 'sell' ? 'Buy XMR' : 'Sell XMR' }} — Start Trade
                    </button>
                </form>
            </div>
            @endif
            @if(Auth::id() === $offer->user_id)
            <div class="d-flex gap-1">
                <a href="{{ route('offers.edit', $offer) }}" class="btn btn-secondary">Edit Offer</a>
                <form method="POST" action="{{ route('offers.destroy', $offer) }}">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="btn btn-danger"
                        data-confirm="Delete this offer?">Delete Offer</button>
                </form>
            </div>
            @endif
            @else
            <div class="card text-center">
                <p class="text-muted">You must be logged in to trade.</p>
                <a href="{{ route('login') }}" class="btn btn-primary mt-2">Sign In to Trade</a>
            </div>
            @endauth
        </div>

        <div class="col-md-4">
            <div class="card">
                <div class="card-header">Seller Info</div>
                <div class="font-weight-bold">{{ $offer->user->username }}</div>
                <div class="text-muted" style="font-size:0.85rem">{{ $offer->user->trade_count }} trades</div>
                <div class="mt-1">
                    <span class="text-success">&#10003; {{ $offer->user->positive_feedback }}</span>
                    &nbsp;
                    <span class="text-danger">&#10007; {{ $offer->user->negative_feedback }}</span>
                </div>
                <div class="mt-1">
                    Feedback: <strong class="text-orange">{{ $offer->user->feedback_score }}%</strong>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
""")


    # ── Trades views ──────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/trades/index.blade.php", r"""@extends('layouts.app')

@section('title', 'My Trades')

@section('content')
<div class="section-title">My Trades</div>

@if($trades->isEmpty())
<div class="card text-center">
    <p class="text-muted">You have no trades yet.</p>
    <a href="{{ route('offers.index') }}" class="btn btn-primary mt-2">Browse Offers</a>
</div>
@else
<div class="card">
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Role</th>
                    <th>Counterparty</th>
                    <th>Amount (XMR)</th>
                    <th>Amount (Fiat)</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                @foreach($trades as $trade)
                <tr>
                    <td>{{ $trade->id }}</td>
                    <td>
                        @if($trade->buyer_id === Auth::id())
                        <span class="badge badge-buy">BUYER</span>
                        @else
                        <span class="badge badge-sell">SELLER</span>
                        @endif
                    </td>
                    <td>
                        @if($trade->buyer_id === Auth::id())
                        {{ $trade->seller->username }}
                        @else
                        {{ $trade->buyer->username }}
                        @endif
                    </td>
                    <td class="text-orange font-weight-bold">{{ number_format($trade->amount_xmr, 6) }} XMR</td>
                    <td>${{ number_format($trade->amount_fiat, 2) }} {{ $trade->currency }}</td>
                    <td>
                        <span class="badge badge-{{ in_array($trade->status, ['completed']) ? 'success' : (in_array($trade->status, ['disputed']) ? 'danger' : (in_array($trade->status, ['cancelled']) ? 'secondary' : 'warning')) }}">
                            {{ ucfirst(str_replace('_', ' ', $trade->status)) }}
                        </span>
                    </td>
                    <td class="text-muted" style="font-size:0.85rem">{{ $trade->created_at->format('M d, Y') }}</td>
                    <td><a href="{{ route('trades.show', $trade) }}" class="btn btn-secondary btn-sm">View</a></td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
<div class="pagination">{{ $trades->links() }}</div>
@endif
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/trades/show.blade.php", r"""@extends('layouts.app')

@section('title', 'Trade #{{ $trade->id }}')

@section('content')
<div class="section-title">Trade #{{ $trade->id }}</div>

<div class="row">
    <div class="col-md-8">
        <div class="card mb-3">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <div>
                    <span class="badge badge-{{ in_array($trade->status, ['completed']) ? 'success' : (in_array($trade->status, ['disputed']) ? 'danger' : (in_array($trade->status, ['cancelled']) ? 'secondary' : 'warning')) }}">
                        {{ ucfirst(str_replace('_', ' ', $trade->status)) }}
                    </span>
                </div>
                <div class="text-muted" style="font-size:0.85rem">{{ $trade->created_at->format('M d, Y H:i') }} UTC</div>
            </div>
            <div class="row">
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Amount XMR</div>
                    <div class="text-orange font-weight-bold">{{ number_format($trade->amount_xmr, 8) }} XMR</div>
                </div>
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Amount Fiat</div>
                    <div class="font-weight-bold">${{ number_format($trade->amount_fiat, 2) }} {{ $trade->currency }}</div>
                </div>
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Price</div>
                    <div>${{ number_format($trade->price, 2) }}</div>
                </div>
            </div>
            <hr class="divider">
            <div class="row">
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Buyer</div>
                    <div>{{ $trade->buyer->username }}</div>
                </div>
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Seller</div>
                    <div>{{ $trade->seller->username }}</div>
                </div>
                <div class="col">
                    <div class="text-muted" style="font-size:0.85rem">Payment Method</div>
                    <div>{{ $trade->offer->payment_method ?? 'N/A' }}</div>
                </div>
            </div>
        </div>

        <div class="card mb-3">
            <div class="card-header">Trade Actions</div>
            <div class="d-flex flex-wrap gap-1">
                @if($trade->status === 'funded' && Auth::id() === $trade->buyer_id)
                <form method="POST" action="{{ route('trades.paid', $trade) }}">
                    @csrf
                    <button type="submit" class="btn btn-success"
                        data-confirm="Confirm you have sent the payment?">
                        Mark Payment Sent
                    </button>
                </form>
                @endif

                @if($trade->status === 'payment_sent' && Auth::id() === $trade->seller_id)
                <form method="POST" action="{{ route('trades.complete', $trade) }}">
                    @csrf
                    <button type="submit" class="btn btn-primary"
                        data-confirm="Confirm payment received and release XMR?">
                        Release XMR &amp; Complete
                    </button>
                </form>
                @endif

                @if(in_array($trade->status, ['pending', 'funded']))
                <form method="POST" action="{{ route('trades.cancel', $trade) }}">
                    @csrf
                    <button type="submit" class="btn btn-secondary"
                        data-confirm="Cancel this trade?">Cancel Trade</button>
                </form>
                @endif

                @if(in_array($trade->status, ['funded', 'payment_sent']) && !$trade->dispute)
                <button type="button" class="btn btn-danger" data-modal="dispute-modal">Open Dispute</button>
                @endif
            </div>
        </div>

        <div class="card mb-3">
            <div class="card-header">Trade Chat</div>
            <div class="chat-box" id="chat-box">
                @foreach($trade->messages as $msg)
                @if($msg->is_system)
                <div class="chat-msg system">{{ $msg->content }}</div>
                @elseif($msg->user_id === Auth::id())
                <div class="chat-msg mine">
                    <div>{{ $msg->content }}</div>
                    <div class="chat-meta">{{ $msg->created_at->format('H:i') }}</div>
                </div>
                @else
                <div class="chat-msg theirs">
                    <div style="font-size:0.8rem;font-weight:700;margin-bottom:0.2rem">{{ $msg->user->username }}</div>
                    <div>{{ $msg->content }}</div>
                    <div class="chat-meta">{{ $msg->created_at->format('H:i') }}</div>
                </div>
                @endif
                @endforeach
            </div>
            @if(in_array($trade->status, ['pending', 'funded', 'payment_sent']))
            <form method="POST" action="{{ route('messages.store', $trade) }}" class="mt-2" style="display:flex;gap:0.5rem">
                @csrf
                <input type="text" name="content" class="form-control" placeholder="Type a message..." required>
                <button type="submit" class="btn btn-primary">Send</button>
            </form>
            @endif
        </div>

        @if($trade->status === 'completed')
        @php $reviewed = $trade->reviews->where('reviewer_id', Auth::id())->first(); @endphp
        @if(!$reviewed)
        <div class="card">
            <div class="card-header">Leave a Review</div>
            <form method="POST" action="{{ route('reviews.store', $trade) }}">
                @csrf
                <div class="form-group">
                    <label class="form-label">Rating</label>
                    <select name="rating" class="form-control" required>
                        <option value="">Select rating</option>
                        <option value="5">&#9733;&#9733;&#9733;&#9733;&#9733; Excellent</option>
                        <option value="4">&#9733;&#9733;&#9733;&#9733; Good</option>
                        <option value="3">&#9733;&#9733;&#9733; Neutral</option>
                        <option value="2">&#9733;&#9733; Poor</option>
                        <option value="1">&#9733; Bad</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">Comment (optional)</label>
                    <textarea name="comment" class="form-control" rows="3" placeholder="Describe your experience..."></textarea>
                </div>
                <button type="submit" class="btn btn-primary">Submit Review</button>
            </form>
        </div>
        @else
        <div class="card">
            <div class="card-header">Your Review</div>
            <div>Rating: {{ $reviewed->rating }}/5</div>
            @if($reviewed->comment)
            <div class="text-muted mt-1">{{ $reviewed->comment }}</div>
            @endif
        </div>
        @endif
        @endif
    </div>

    <div class="col-md-4">
        @if($trade->dispute)
        <div class="card" style="border-color:var(--danger)">
            <div class="card-header text-danger">Active Dispute</div>
            <div class="text-muted" style="font-size:0.88rem">Reason: {{ $trade->dispute->reason }}</div>
            <div class="badge badge-{{ $trade->dispute->status === 'open' ? 'danger' : 'success' }} mt-1">
                {{ ucfirst($trade->dispute->status) }}
            </div>
        </div>
        @endif
    </div>
</div>

<div class="modal-overlay" id="dispute-modal">
    <div class="modal">
        <div class="modal-header">
            <div class="modal-title">Open Dispute</div>
            <button class="modal-close">&times;</button>
        </div>
        <form method="POST" action="{{ route('trades.dispute', $trade) }}">
            @csrf
            <div class="form-group">
                <label class="form-label">Reason</label>
                <input type="text" name="reason" class="form-control" placeholder="Brief reason" required>
            </div>
            <div class="form-group">
                <label class="form-label">Details</label>
                <textarea name="details" class="form-control" rows="4" placeholder="Describe the issue in detail..."></textarea>
            </div>
            <button type="submit" class="btn btn-danger btn-block">Submit Dispute</button>
        </form>
    </div>
</div>
@endsection
""")


    # ── Wallet, Messages, Disputes, Admin, Errors views ───────────────────────
    write_file(f"{APP_DIR}/resources/views/wallet/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Wallet')

@section('content')
<div class="section-title">My Wallet</div>

<div class="row">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">Monero Balance</div>
            <div class="stat-value">{{ number_format($wallet->balance, 8) }}</div>
            <div class="text-muted">XMR Total Balance</div>
            <hr class="divider">
            <div class="d-flex justify-content-between">
                <div>
                    <div class="text-muted" style="font-size:0.85rem">Available</div>
                    <div class="text-success">{{ number_format($wallet->available_balance, 8) }} XMR</div>
                </div>
                <div>
                    <div class="text-muted" style="font-size:0.85rem">Locked in Escrow</div>
                    <div class="text-warning">{{ number_format($wallet->locked_balance, 8) }} XMR</div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">Deposit Address</div>
            @if($wallet->address)
            <div style="font-size:0.8rem;word-break:break-all;background:var(--bg-primary);padding:0.75rem;border-radius:var(--radius);font-family:monospace" id="deposit-address">
                {{ $wallet->address }}
            </div>
            <button class="btn btn-secondary btn-sm mt-2 copy-btn" data-copy="deposit-address">Copy</button>
            @else
            <p class="text-muted">No deposit address assigned yet. Contact support.</p>
            @endif
        </div>
    </div>
</div>

<div class="card mt-3" style="max-width:500px">
    <div class="card-header">Withdraw XMR</div>
    <form method="POST" action="{{ route('wallet.withdraw') }}">
        @csrf
        <div class="form-group">
            <label class="form-label">Recipient XMR Address</label>
            <input type="text" name="address" class="form-control" required
                maxlength="106"
                placeholder="4... (standard Monero address, 95 chars)">
        </div>
        <div class="form-group">
            <label class="form-label">Amount (XMR)</label>
            <input type="number" name="amount" class="form-control"
                step="0.000001" min="0.001" required
                placeholder="e.g. 0.5"
                max="{{ $wallet->available_balance }}">
            <div class="form-text">Available: {{ number_format($wallet->available_balance, 8) }} XMR</div>
        </div>
        <button type="submit" class="btn btn-danger"
            data-confirm="Confirm withdrawal? This action cannot be undone.">
            Withdraw XMR
        </button>
    </form>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/disputes/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Admin — Disputes')

@section('content')
<div class="section-title">Open Disputes</div>

@if($disputes->isEmpty())
<div class="card text-center">
    <p class="text-muted">No open disputes.</p>
</div>
@else
@foreach($disputes as $dispute)
<div class="card mb-3">
    <div class="d-flex justify-content-between align-items-center mb-2">
        <div>
            <strong>Dispute #{{ $dispute->id }}</strong> — Trade #{{ $dispute->trade_id }}
            <span class="badge badge-danger ml-2">{{ ucfirst($dispute->status) }}</span>
        </div>
        <div class="text-muted" style="font-size:0.85rem">{{ $dispute->created_at->format('M d, Y') }}</div>
    </div>
    <div class="text-muted mb-1">Opened by: <strong>{{ $dispute->opener->username }}</strong></div>
    <div class="mb-2"><strong>Reason:</strong> {{ $dispute->reason }}</div>
    @if($dispute->details)
    <div class="mb-2 text-muted">{{ $dispute->details }}</div>
    @endif
    <div class="row mb-2">
        <div class="col">Buyer: <strong>{{ $dispute->trade->buyer->username }}</strong></div>
        <div class="col">Seller: <strong>{{ $dispute->trade->seller->username }}</strong></div>
        <div class="col">Amount: <strong class="text-orange">{{ number_format($dispute->trade->amount_xmr, 6) }} XMR</strong></div>
    </div>
    <form method="POST" action="{{ route('admin.disputes.resolve', $dispute) }}">
        @csrf
        <div class="row">
            <div class="col">
                <label class="form-label">Winner</label>
                <select name="winner" class="form-control" required>
                    <option value="buyer">Buyer ({{ $dispute->trade->buyer->username }})</option>
                    <option value="seller">Seller ({{ $dispute->trade->seller->username }})</option>
                </select>
            </div>
            <div class="col">
                <label class="form-label">Resolution Notes</label>
                <input type="text" name="resolution" class="form-control" required placeholder="Brief resolution...">
            </div>
            <div class="col" style="display:flex;align-items:flex-end">
                <button type="submit" class="btn btn-primary w-100">Resolve</button>
            </div>
        </div>
    </form>
</div>
@endforeach
<div class="pagination">{{ $disputes->links() }}</div>
@endif
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/dashboard.blade.php", r"""@extends('layouts.app')

@section('title', 'Admin Dashboard')

@section('content')
<div class="section-title">&#9881; Admin Dashboard</div>

<div class="row mb-4">
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ $stats['users'] }}</div>
            <div class="stat-label">Total Users</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ $stats['offers'] }}</div>
            <div class="stat-label">Total Offers</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value">{{ $stats['trades'] }}</div>
            <div class="stat-label">Total Trades</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value text-success">{{ $stats['completed'] }}</div>
            <div class="stat-label">Completed Trades</div>
        </div>
    </div>
    <div class="col">
        <div class="stat-card">
            <div class="stat-value text-danger">{{ $stats['disputes'] }}</div>
            <div class="stat-label">Open Disputes</div>
        </div>
    </div>
</div>

<div class="row mb-4">
    <div class="col">
        <a href="{{ route('admin.users') }}"    class="btn btn-secondary btn-block">Manage Users</a>
    </div>
    <div class="col">
        <a href="{{ route('admin.offers') }}"   class="btn btn-secondary btn-block">View Offers</a>
    </div>
    <div class="col">
        <a href="{{ route('admin.trades') }}"   class="btn btn-secondary btn-block">View Trades</a>
    </div>
    <div class="col">
        <a href="{{ route('admin.disputes') }}" class="btn btn-danger btn-block">
            Disputes
            @if($stats['disputes'] > 0)
            <span class="badge badge-danger">{{ $stats['disputes'] }}</span>
            @endif
        </a>
    </div>
</div>

<div class="row">
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">Recent Users</div>
            @foreach($recentUsers as $user)
            <div class="d-flex justify-content-between align-items-center" style="padding:0.5rem 0;border-bottom:1px solid var(--border)">
                <div>
                    <strong>{{ $user->username }}</strong>
                    @if($user->is_admin) <span class="badge badge-warning">Admin</span> @endif
                    @if($user->is_banned) <span class="badge badge-danger">Banned</span> @endif
                </div>
                <div class="text-muted" style="font-size:0.82rem">{{ $user->created_at->format('M d') }}</div>
            </div>
            @endforeach
        </div>
    </div>
    <div class="col-md-6">
        <div class="card">
            <div class="card-header">Recent Trades</div>
            @foreach($recentTrades as $trade)
            <div class="d-flex justify-content-between align-items-center" style="padding:0.5rem 0;border-bottom:1px solid var(--border)">
                <div>
                    <a href="{{ route('trades.show', $trade) }}">#{{ $trade->id }}</a>
                    <span class="text-muted" style="font-size:0.85rem">{{ $trade->buyer->username }} → {{ $trade->seller->username }}</span>
                </div>
                <span class="badge badge-{{ $trade->status === 'completed' ? 'success' : ($trade->status === 'disputed' ? 'danger' : 'warning') }}">
                    {{ ucfirst($trade->status) }}
                </span>
            </div>
            @endforeach
        </div>
    </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/errors/404.blade.php", r"""@extends('layouts.app')

@section('title', '404 Not Found')

@section('content')
<div class="text-center mt-4">
    <div style="font-size:6rem;color:var(--accent)">404</div>
    <h2 class="mt-2">Page Not Found</h2>
    <p class="text-muted mt-2">The page you are looking for does not exist or has been moved.</p>
    <a href="{{ url('/') }}" class="btn btn-primary mt-3">Go Home</a>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/errors/500.blade.php", r"""@extends('layouts.app')

@section('title', '500 Server Error')

@section('content')
<div class="text-center mt-4">
    <div style="font-size:6rem;color:var(--danger)">500</div>
    <h2 class="mt-2">Server Error</h2>
    <p class="text-muted mt-2">Something went wrong on our end. Please try again later.</p>
    <a href="{{ url('/') }}" class="btn btn-primary mt-3">Go Home</a>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/messages/index.blade.php", r"""@extends('layouts.app')

@section('title', 'Messages')

@section('content')
<div class="section-title">Trade Messages</div>
<div class="card text-center">
    <p class="text-muted">Messages are available within each trade. <a href="{{ route('trades.index') }}">View your trades</a>.</p>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/reviews/partials/stars.blade.php", r"""@for($i = 1; $i <= 5; $i++)
    @if($i <= $rating)
    <span style="color:var(--warning)">&#9733;</span>
    @else
    <span style="color:var(--border)">&#9734;</span>
    @endif
@endfor
""")

    write_file(f"{APP_DIR}/resources/views/admin/users.blade.php", r"""@extends('layouts.app')

@section('title', 'Admin — Users')

@section('content')
<div class="section-title">User Management</div>

<div class="card mb-3">
    <form method="GET" action="{{ route('admin.users') }}" style="display:flex;gap:0.75rem">
        <input type="text" name="search" class="form-control" value="{{ request('search') }}" placeholder="Search by username or email">
        <button type="submit" class="btn btn-primary">Search</button>
    </form>
</div>

<div class="card">
    <div class="table-container">
        <table>
            <thead>
                <tr>
                    <th>ID</th><th>Username</th><th>Email</th>
                    <th>Trades</th><th>Status</th><th>Joined</th><th>Actions</th>
                </tr>
            </thead>
            <tbody>
                @foreach($users as $user)
                <tr>
                    <td>{{ $user->id }}</td>
                    <td><strong>{{ $user->username }}</strong> @if($user->is_admin)<span class="badge badge-warning">Admin</span>@endif</td>
                    <td class="text-muted">{{ $user->email }}</td>
                    <td>{{ $user->trade_count }}</td>
                    <td>
                        @if($user->is_banned)
                        <span class="badge badge-danger">Banned</span>
                        @else
                        <span class="badge badge-success">Active</span>
                        @endif
                    </td>
                    <td class="text-muted" style="font-size:0.82rem">{{ $user->created_at->format('M d, Y') }}</td>
                    <td>
                        @if(!$user->is_admin)
                        @if($user->is_banned)
                        <form method="POST" action="{{ route('admin.users.unban', $user) }}" style="display:inline">
                            @csrf
                            <button type="submit" class="btn btn-success btn-sm">Unban</button>
                        </form>
                        @else
                        <button type="button" class="btn btn-danger btn-sm" data-modal="ban-{{ $user->id }}">Ban</button>
                        <div class="modal-overlay" id="ban-{{ $user->id }}">
                            <div class="modal">
                                <div class="modal-header">
                                    <div class="modal-title">Ban {{ $user->username }}</div>
                                    <button class="modal-close">&times;</button>
                                </div>
                                <form method="POST" action="{{ route('admin.users.ban', $user) }}">
                                    @csrf
                                    <div class="form-group">
                                        <label class="form-label">Reason</label>
                                        <textarea name="reason" class="form-control" rows="3" required placeholder="Reason for ban..."></textarea>
                                    </div>
                                    <button type="submit" class="btn btn-danger btn-block">Confirm Ban</button>
                                </form>
                            </div>
                        </div>
                        @endif
                        @endif
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
<div class="pagination">{{ $users->links() }}</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/offers.blade.php", r"""@extends('layouts.app')

@section('title', 'Admin — Offers')

@section('content')
<div class="section-title">All Offers</div>
<div class="card">
    <div class="table-container">
        <table>
            <thead>
                <tr><th>ID</th><th>User</th><th>Type</th><th>Method</th><th>Price</th><th>Status</th><th>Date</th></tr>
            </thead>
            <tbody>
                @foreach($offers as $offer)
                <tr>
                    <td>{{ $offer->id }}</td>
                    <td>{{ $offer->user->username }}</td>
                    <td><span class="badge badge-{{ $offer->type }}">{{ strtoupper($offer->type) }}</span></td>
                    <td>{{ $offer->payment_method }}</td>
                    <td>
                        @if($offer->price_type === 'fixed')
                        ${{ number_format($offer->fixed_price, 2) }}
                        @else
                        Market {{ $offer->margin >= 0 ? '+' : '' }}{{ $offer->margin }}%
                        @endif
                    </td>
                    <td><span class="badge badge-{{ $offer->is_active ? 'success' : 'secondary' }}">{{ $offer->is_active ? 'Active' : 'Inactive' }}</span></td>
                    <td class="text-muted" style="font-size:0.82rem">{{ $offer->created_at->format('M d, Y') }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
<div class="pagination">{{ $offers->links() }}</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/trades.blade.php", r"""@extends('layouts.app')

@section('title', 'Admin — Trades')

@section('content')
<div class="section-title">All Trades</div>
<div class="card">
    <div class="table-container">
        <table>
            <thead>
                <tr><th>ID</th><th>Buyer</th><th>Seller</th><th>Amount XMR</th><th>Amount Fiat</th><th>Status</th><th>Date</th><th></th></tr>
            </thead>
            <tbody>
                @foreach($trades as $trade)
                <tr>
                    <td>{{ $trade->id }}</td>
                    <td>{{ $trade->buyer->username }}</td>
                    <td>{{ $trade->seller->username }}</td>
                    <td class="text-orange">{{ number_format($trade->amount_xmr, 6) }}</td>
                    <td>${{ number_format($trade->amount_fiat, 2) }} {{ $trade->currency }}</td>
                    <td>
                        <span class="badge badge-{{ $trade->status === 'completed' ? 'success' : ($trade->status === 'disputed' ? 'danger' : ($trade->status === 'cancelled' ? 'secondary' : 'warning')) }}">
                            {{ ucfirst(str_replace('_', ' ', $trade->status)) }}
                        </span>
                    </td>
                    <td class="text-muted" style="font-size:0.82rem">{{ $trade->created_at->format('M d, Y') }}</td>
                    <td><a href="{{ route('trades.show', $trade) }}" class="btn btn-secondary btn-sm">View</a></td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
<div class="pagination">{{ $trades->links() }}</div>
@endsection
""")

    print("[OK] Phase 6 complete")



def phase6b_additional_files():
    print("\n=== Phase 6b: Additional Files ===")

    # ── Console Commands ──────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Console/Commands/CheckDeposits.php", r"""<?php

namespace App\Console\Commands;

use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Console\Command;

class CheckDeposits extends Command
{
    protected $signature   = 'app:check-deposits';
    protected $description = 'Check for new crypto deposits';

    public function handle()
    {
        $this->info('Checking for new deposits...');
        // Query blockchain nodes for pending deposit transactions
        Transaction::where('type', 'deposit')
            ->where('status', 'pending')
            ->chunk(100, function ($txs) {
                foreach ($txs as $tx) {
                    // Confirmation check logic would go here
                    $this->line("  Checking txid: {$tx->txid}");
                }
            });
        return 0;
    }
}
""")

    write_file(f"{APP_DIR}/app/Console/Commands/ExpireTrades.php", r"""<?php

namespace App\Console\Commands;

use App\Models\Trade;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class ExpireTrades extends Command
{
    protected $signature   = 'app:expire-trades';
    protected $description = 'Expire trades past their payment window';

    public function handle()
    {
        $expired = Trade::where('status', 'open')
            ->where('expires_at', '<', Carbon::now())
            ->get();

        foreach ($expired as $trade) {
            $trade->update(['status' => 'expired', 'cancelled_at' => Carbon::now()]);
            $this->line("  Expired trade: {$trade->trade_id}");
        }

        $this->info("Expired {$expired->count()} trades.");
        return 0;
    }
}
""")

    write_file(f"{APP_DIR}/app/Console/Commands/ProcessEscrow.php", r"""<?php

namespace App\Console\Commands;

use App\Models\Trade;
use App\Models\Transaction;
use Illuminate\Console\Command;

class ProcessEscrow extends Command
{
    protected $signature   = 'app:process-escrow';
    protected $description = 'Process pending escrow funding confirmations';

    public function handle()
    {
        $this->info('Processing escrow transactions...');
        Transaction::where('type', 'escrow_lock')
            ->where('status', 'confirming')
            ->chunk(50, function ($txs) {
                foreach ($txs as $tx) {
                    $this->line("  Processing escrow tx: {$tx->txid}");
                }
            });
        return 0;
    }
}
""")

    # ── Missing Models ────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Models/Transaction.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $fillable = [
        'user_id', 'wallet_id', 'txid', 'crypto', 'type',
        'amount', 'fee', 'address', 'status',
        'confirmations', 'required_confirmations',
    ];

    public function user()   { return $this->belongsTo(User::class); }
    public function wallet() { return $this->belongsTo(Wallet::class); }
}
""")

    write_file(f"{APP_DIR}/app/Models/DisputeMessage.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DisputeMessage extends Model
{
    protected $fillable = ['dispute_id', 'user_id', 'message', 'attachment'];

    public function dispute() { return $this->belongsTo(Dispute::class); }
    public function user()    { return $this->belongsTo(User::class); }
}
""")

    write_file(f"{APP_DIR}/app/Models/AppNotification.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $table    = 'notifications';
    protected $fillable = ['user_id', 'type', 'title', 'message', 'data', 'is_read', 'read_at'];
    protected $casts    = ['data' => 'array', 'is_read' => 'boolean'];

    public function user() { return $this->belongsTo(User::class); }

    public function markRead()
    {
        $this->update(['is_read' => true, 'read_at' => now()]);
    }
}
""")

    write_file(f"{APP_DIR}/app/Models/Image.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Image extends Model
{
    protected $fillable = [
        'user_id', 'imageable_id', 'imageable_type',
        'path', 'original_name', 'mime_type', 'size',
    ];

    public function imageable() { return $this->morphTo(); }
    public function user()      { return $this->belongsTo(User::class); }
}
""")

    write_file(f"{APP_DIR}/app/Models/Swap.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Swap extends Model
{
    protected $fillable = [
        'user_id', 'from_crypto', 'to_crypto',
        'from_amount', 'to_amount', 'rate', 'fee',
        'status', 'completed_at',
    ];

    protected $casts = ['completed_at' => 'datetime'];

    public function user() { return $this->belongsTo(User::class); }
}
""")

    write_file(f"{APP_DIR}/app/Models/LoginLog.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LoginLog extends Model
{
    protected $fillable = ['user_id', 'ip_address', 'user_agent', 'success'];
    protected $casts    = ['success' => 'boolean'];

    public function user() { return $this->belongsTo(User::class); }
}
""")

    write_file(f"{APP_DIR}/app/Models/Setting.php", r"""<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $fillable = ['key', 'value'];

    public static function get(string $key, $default = null)
    {
        $setting = static::where('key', $key)->first();
        return $setting ? $setting->value : $default;
    }

    public static function set(string $key, $value): void
    {
        static::updateOrCreate(['key' => $key], ['value' => $value]);
    }
}
""")

    # ── Missing Controllers ───────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Http/Controllers/SwapController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Swap;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class SwapController extends Controller
{
    public function index()
    {
        return view('wallet.swap');
    }

    public function store(Request $request)
    {
        $request->validate([
            'from_crypto' => 'required|in:BTC,XMR,LTC,ETH',
            'to_crypto'   => 'required|in:BTC,XMR,LTC,ETH|different:from_crypto',
            'from_amount' => 'required|numeric|min:0.00000001',
        ]);

        $user = Auth::user();

        // Placeholder rate — real implementation calls exchange API
        $rate     = 1.0;
        $toAmount = $request->from_amount * $rate;
        $fee      = $toAmount * 0.005;

        $swap = Swap::create([
            'user_id'     => $user->id,
            'from_crypto' => $request->from_crypto,
            'to_crypto'   => $request->to_crypto,
            'from_amount' => $request->from_amount,
            'to_amount'   => $toAmount - $fee,
            'rate'        => $rate,
            'fee'         => $fee,
            'status'      => 'pending',
        ]);

        return redirect()->route('wallet.swap.history')
            ->with('success', 'Swap initiated successfully.');
    }

    public function history()
    {
        $swaps = Swap::where('user_id', Auth::id())
            ->latest()
            ->paginate(20);
        return view('wallet.swap', compact('swaps'));
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/ImageController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Image;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class ImageController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'image'          => 'required|image|max:5120',
            'imageable_type' => 'required|string',
            'imageable_id'   => 'required|integer',
        ]);

        $file = $request->file('image');
        $path = $file->store('images', 'public');

        $image = Image::create([
            'user_id'        => Auth::id(),
            'imageable_id'   => $request->imageable_id,
            'imageable_type' => $request->imageable_type,
            'path'           => $path,
            'original_name'  => $file->getClientOriginalName(),
            'mime_type'      => $file->getMimeType(),
            'size'           => $file->getSize(),
        ]);

        return response()->json(['image' => $image], 201);
    }
}
""")

    write_file(f"{APP_DIR}/app/Http/Controllers/DashboardController.php", r"""<?php

namespace App\Http\Controllers;

use App\Models\Trade;
use App\Models\Offer;
use App\Models\AppNotification;
use Illuminate\Support\Facades\Auth;

class DashboardController extends Controller
{
    public function index()
    {
        $user          = Auth::user();
        $activeTrades  = Trade::where('buyer_id', $user->id)
            ->orWhere('seller_id', $user->id)
            ->whereIn('status', ['open', 'escrow_funded', 'paid'])
            ->with(['buyer', 'seller', 'offer'])
            ->latest()
            ->take(5)
            ->get();
        $activeOffers  = Offer::where('user_id', $user->id)
            ->where('is_active', true)
            ->latest()
            ->take(5)
            ->get();
        $notifications = AppNotification::where('user_id', $user->id)
            ->where('is_read', false)
            ->latest()
            ->take(10)
            ->get();
        return view('dashboard', compact('user', 'activeTrades', 'activeOffers', 'notifications'));
    }
}
""")

    # ── Config Files ──────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/config/broadcasting.php", r"""<?php

return [
    'default' => env('BROADCAST_DRIVER', 'null'),
    'connections' => [
        'pusher' => [
            'driver' => 'pusher',
            'key'    => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER', 'mt1'),
                'useTLS'  => true,
            ],
        ],
        'log'  => ['driver' => 'log'],
        'null' => ['driver' => 'null'],
    ],
];
""")

    write_file(f"{APP_DIR}/config/cache.php", r"""<?php

return [
    'default' => env('CACHE_DRIVER', 'file'),
    'stores'  => [
        'apc'       => ['driver' => 'apc'],
        'array'     => ['driver' => 'array', 'serialize' => false],
        'database'  => ['driver' => 'database', 'table' => 'cache', 'connection' => null, 'lock_connection' => null],
        'file'      => ['driver' => 'file', 'path' => storage_path('framework/cache/data')],
        'memcached' => [
            'driver'        => 'memcached',
            'persistent_id' => env('MEMCACHED_PERSISTENT_ID'),
            'sasl'          => [env('MEMCACHED_USERNAME'), env('MEMCACHED_PASSWORD')],
            'options'       => [],
            'servers'       => [['host' => env('MEMCACHED_HOST', '127.0.0.1'), 'port' => env('MEMCACHED_PORT', 11211), 'weight' => 100]],
        ],
        'redis' => [
            'driver'     => 'redis',
            'connection' => 'cache',
            'lock_connection' => 'default',
        ],
        'dynamodb' => [
            'driver'   => 'dynamodb',
            'key'      => env('AWS_ACCESS_KEY_ID'),
            'secret'   => env('AWS_SECRET_ACCESS_KEY'),
            'region'   => env('AWS_DEFAULT_REGION', 'us-east-1'),
            'table'    => env('DYNAMODB_CACHE_TABLE', 'cache'),
            'endpoint' => env('DYNAMODB_ENDPOINT'),
        ],
        'octane' => ['driver' => 'octane'],
    ],
    'prefix' => env('CACHE_PREFIX', 'capitalmonero_cache'),
];
""")

    write_file(f"{APP_DIR}/config/filesystems.php", r"""<?php

return [
    'default' => env('FILESYSTEM_DISK', 'local'),
    'disks'   => [
        'local' => [
            'driver' => 'local',
            'root'   => storage_path('app'),
            'throw'  => false,
        ],
        'public' => [
            'driver'     => 'local',
            'root'       => storage_path('app/public'),
            'url'        => env('APP_URL').'/storage',
            'visibility' => 'public',
            'throw'      => false,
        ],
        's3' => [
            'driver'   => 's3',
            'key'      => env('AWS_ACCESS_KEY_ID'),
            'secret'   => env('AWS_SECRET_ACCESS_KEY'),
            'region'   => env('AWS_DEFAULT_REGION'),
            'bucket'   => env('AWS_BUCKET'),
            'url'      => env('AWS_URL'),
            'endpoint' => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
            'throw'    => false,
        ],
    ],
    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],
];
""")

    write_file(f"{APP_DIR}/config/hashing.php", r"""<?php

return [
    'driver' => 'bcrypt',
    'bcrypt' => ['rounds' => env('BCRYPT_ROUNDS', 12)],
    'argon'  => [
        'memory'  => 65536,
        'threads' => 1,
        'time'    => 4,
    ],
];
""")

    write_file(f"{APP_DIR}/config/logging.php", r"""<?php

use Monolog\Handler\NullHandler;
use Monolog\Handler\StreamHandler;
use Monolog\Handler\SyslogUdpHandler;

return [
    'default'  => env('LOG_CHANNEL', 'stack'),
    'deprecations' => [
        'channel' => env('LOG_DEPRECATIONS_CHANNEL', 'null'),
        'trace'   => false,
    ],
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
        'daily' => [
            'driver' => 'daily',
            'path'   => storage_path('logs/laravel.log'),
            'level'  => env('LOG_LEVEL', 'debug'),
            'days'   => 14,
        ],
        'slack' => [
            'driver'   => 'slack',
            'url'      => env('LOG_SLACK_WEBHOOK_URL'),
            'username' => 'Laravel Log',
            'emoji'    => ':boom:',
            'level'    => env('LOG_LEVEL', 'critical'),
        ],
        'papertrail' => [
            'driver'       => 'monolog',
            'level'        => env('LOG_LEVEL', 'debug'),
            'handler'      => SyslogUdpHandler::class,
            'handler_with' => [
                'host' => env('PAPERTRAIL_URL'),
                'port' => env('PAPERTRAIL_PORT'),
            ],
        ],
        'stderr' => [
            'driver'    => 'monolog',
            'level'     => env('LOG_LEVEL', 'debug'),
            'handler'   => StreamHandler::class,
            'formatter' => env('LOG_STDERR_FORMATTER'),
            'with'      => ['stream' => 'php://stderr'],
        ],
        'syslog' => [
            'driver' => 'syslog',
            'level'  => env('LOG_LEVEL', 'debug'),
        ],
        'errorlog' => [
            'driver' => 'errorlog',
            'level'  => env('LOG_LEVEL', 'debug'),
        ],
        'null' => [
            'driver'  => 'monolog',
            'handler' => NullHandler::class,
        ],
        'emergency' => [
            'path' => storage_path('logs/laravel.log'),
        ],
    ],
];
""")

    write_file(f"{APP_DIR}/config/mail.php", r"""<?php

return [
    'default'  => env('MAIL_MAILER', 'smtp'),
    'mailers'  => [
        'smtp' => [
            'transport'  => 'smtp',
            'host'       => env('MAIL_HOST', 'smtp.mailgun.org'),
            'port'       => env('MAIL_PORT', 587),
            'encryption' => env('MAIL_ENCRYPTION', 'tls'),
            'username'   => env('MAIL_USERNAME'),
            'password'   => env('MAIL_PASSWORD'),
            'timeout'    => null,
            'auth_mode'  => null,
        ],
        'ses'      => ['transport' => 'ses'],
        'mailgun'  => ['transport' => 'mailgun'],
        'postmark' => ['transport' => 'postmark'],
        'sendmail' => ['transport' => 'sendmail', 'path' => env('MAIL_SENDMAIL_PATH', '/usr/sbin/sendmail -t -i')],
        'log'      => ['transport' => 'log', 'channel' => env('MAIL_LOG_CHANNEL')],
        'array'    => ['transport' => 'array'],
        'failover' => ['transport' => 'failover', 'mailers' => ['smtp', 'log']],
    ],
    'from' => [
        'address' => env('MAIL_FROM_ADDRESS', 'noreply@capitalmonero.com'),
        'name'    => env('MAIL_FROM_NAME', 'CapitalMonero'),
    ],
    'markdown' => [
        'theme' => 'default',
        'paths' => [resource_path('views/vendor/mail')],
    ],
];
""")

    write_file(f"{APP_DIR}/config/queue.php", r"""<?php

return [
    'default'     => env('QUEUE_CONNECTION', 'database'),
    'connections' => [
        'sync'     => ['driver' => 'sync'],
        'database' => [
            'driver'      => 'database',
            'table'       => 'jobs',
            'queue'       => 'default',
            'retry_after' => 90,
            'after_commit' => false,
        ],
        'beanstalkd' => [
            'driver'      => 'beanstalkd',
            'host'        => 'localhost',
            'queue'       => 'default',
            'retry_after' => 90,
            'block_for'   => 0,
            'after_commit' => false,
        ],
        'sqs' => [
            'driver'      => 'sqs',
            'key'         => env('AWS_ACCESS_KEY_ID'),
            'secret'      => env('AWS_SECRET_ACCESS_KEY'),
            'prefix'      => env('SQS_PREFIX', 'https://sqs.us-east-1.amazonaws.com/your-account-id'),
            'queue'       => env('SQS_QUEUE', 'default'),
            'suffix'      => env('SQS_SUFFIX'),
            'region'      => env('AWS_DEFAULT_REGION', 'us-east-1'),
            'after_commit' => false,
        ],
        'redis' => [
            'driver'      => 'redis',
            'connection'  => 'default',
            'queue'       => env('REDIS_QUEUE', 'default'),
            'retry_after' => 90,
            'block_for'   => null,
            'after_commit' => false,
        ],
    ],
    'failed' => [
        'driver'   => env('QUEUE_FAILED_DRIVER', 'database-uuids'),
        'database' => env('DB_CONNECTION', 'mysql'),
        'table'    => 'failed_jobs',
    ],
];
""")

    write_file(f"{APP_DIR}/config/sanctum.php", r"""<?php

use Laravel\Sanctum\Sanctum;

return [
    'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
        '%s%s',
        'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
        Sanctum::currentApplicationUrlWithPort()
    ))),
    'guard'      => ['web'],
    'expiration' => null,
    'middleware' => [
        'verify_csrf_token' => App\Http\Middleware\VerifyCsrfToken::class,
        'encrypt_cookies'   => App\Http\Middleware\EncryptCookies::class,
    ],
];
""")

    write_file(f"{APP_DIR}/config/services.php", r"""<?php

return [
    'mailgun'  => ['domain' => env('MAILGUN_DOMAIN'), 'secret' => env('MAILGUN_SECRET'), 'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net')],
    'postmark' => ['token' => env('POSTMARK_TOKEN')],
    'ses'      => ['key' => env('AWS_ACCESS_KEY_ID'), 'secret' => env('AWS_SECRET_ACCESS_KEY'), 'region' => env('AWS_DEFAULT_REGION', 'us-east-1')],
];
""")

    write_file(f"{APP_DIR}/config/view.php", r"""<?php

return [
    'paths'    => [resource_path('views')],
    'compiled' => env('VIEW_COMPILED_PATH', realpath(storage_path('framework/views'))),
];
""")

    # ── Missing Views ─────────────────────────────────────────────────────────
    write_file(f"{APP_DIR}/resources/views/auth/two-factor-setup.blade.php", r"""@extends('layouts.app')
@section('title', '2FA Setup')
@section('content')
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-md-6">
      <div class="card">
        <div class="card-header">Two-Factor Authentication Setup</div>
        <div class="card-body text-center">
          <p>Scan this QR code with your authenticator app:</p>
          <div class="mb-3"><img src="{{ $qrUrl }}" alt="QR Code" class="img-fluid" style="max-width:200px;"></div>
          <p class="text-muted small">Manual key: <code>{{ $secret }}</code></p>
          <form method="POST" action="{{ route('2fa.verify.post') }}">
            @csrf
            <div class="mb-3">
              <label class="form-label">Verification Code</label>
              <input type="text" name="code" class="form-control text-center" maxlength="6" required autofocus>
            </div>
            <button type="submit" class="btn btn-primary w-100">Verify &amp; Enable</button>
          </form>
        </div>
      </div>
    </div>
  </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/offers/edit.blade.php", r"""@extends('layouts.app')
@section('title', 'Edit Offer')
@section('content')
<div class="container py-4">
  <h2>Edit Offer</h2>
  <form method="POST" action="{{ route('offers.update', $offer) }}">
    @csrf @method('PUT')
    <div class="mb-3">
      <label class="form-label">Type</label>
      <select name="type" class="form-select" required>
        <option value="buy"  @selected($offer->type==='buy') >Buy</option>
        <option value="sell" @selected($offer->type==='sell')>Sell</option>
      </select>
    </div>
    <div class="row">
      <div class="col-md-6 mb-3">
        <label class="form-label">Min Amount</label>
        <input type="number" name="min_amount" class="form-control" step="0.00000001" value="{{ $offer->min_amount }}" required>
      </div>
      <div class="col-md-6 mb-3">
        <label class="form-label">Max Amount</label>
        <input type="number" name="max_amount" class="form-control" step="0.00000001" value="{{ $offer->max_amount }}" required>
      </div>
    </div>
    <div class="mb-3">
      <label class="form-label">Payment Method</label>
      <input type="text" name="payment_method" class="form-control" value="{{ $offer->payment_method }}" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Terms</label>
      <textarea name="terms" class="form-control" rows="4">{{ $offer->terms }}</textarea>
    </div>
    <div class="form-check mb-3">
      <input class="form-check-input" type="checkbox" name="is_active" value="1" @checked($offer->is_active)>
      <label class="form-check-label">Active</label>
    </div>
    <button type="submit" class="btn btn-primary">Update Offer</button>
    <a href="{{ route('offers.index') }}" class="btn btn-secondary">Cancel</a>
  </form>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/wallet/swap.blade.php", r"""@extends('layouts.app')
@section('title', 'Swap Crypto')
@section('content')
<div class="container py-4">
  <h2>Swap Cryptocurrency</h2>
  @if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
  @endif
  <div class="row">
    <div class="col-md-6">
      <div class="card mb-4">
        <div class="card-header">New Swap</div>
        <div class="card-body">
          <form method="POST" action="{{ route('wallet.swap.store') }}">
            @csrf
            <div class="mb-3">
              <label class="form-label">From</label>
              <select name="from_crypto" class="form-select" required>
                @foreach(['BTC','XMR','LTC','ETH'] as $c)
                  <option value="{{ $c }}">{{ $c }}</option>
                @endforeach
              </select>
            </div>
            <div class="mb-3">
              <label class="form-label">To</label>
              <select name="to_crypto" class="form-select" required>
                @foreach(['BTC','XMR','LTC','ETH'] as $c)
                  <option value="{{ $c }}">{{ $c }}</option>
                @endforeach
              </select>
            </div>
            <div class="mb-3">
              <label class="form-label">Amount</label>
              <input type="number" name="from_amount" class="form-control" step="0.00000001" min="0.00000001" required>
            </div>
            <button type="submit" class="btn btn-primary w-100">Swap</button>
          </form>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <h5>Swap History</h5>
      @isset($swaps)
        <div class="table-responsive">
          <table class="table table-sm">
            <thead><tr><th>From</th><th>To</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
            <tbody>
              @forelse($swaps as $swap)
                <tr>
                  <td>{{ $swap->from_amount }} {{ $swap->from_crypto }}</td>
                  <td>{{ $swap->to_amount }} {{ $swap->to_crypto }}</td>
                  <td>{{ $swap->from_amount }}</td>
                  <td><span class="badge bg-{{ $swap->status==='completed'?'success':($swap->status==='failed'?'danger':'warning') }}">{{ $swap->status }}</span></td>
                  <td>{{ $swap->created_at->diffForHumans() }}</td>
                </tr>
              @empty
                <tr><td colspan="5" class="text-center text-muted">No swaps yet</td></tr>
              @endforelse
            </tbody>
          </table>
        </div>
        {{ $swaps->links() }}
      @endisset
    </div>
  </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/messages/show.blade.php", r"""@extends('layouts.app')
@section('title', 'Messages')
@section('content')
<div class="container py-4">
  <div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <span>Conversation with {{ $otherUser->username }}</span>
      <a href="{{ url()->previous() }}" class="btn btn-sm btn-outline-secondary">Back</a>
    </div>
    <div class="card-body" style="max-height:400px;overflow-y:auto;" id="messages-box">
      @forelse($messages as $msg)
        <div class="mb-2 {{ $msg->sender_id === auth()->id() ? 'text-end' : '' }}">
          <span class="badge bg-{{ $msg->sender_id === auth()->id() ? 'primary' : 'secondary' }}">
            {{ $msg->sender->username }}
          </span>
          <p class="mb-0">{{ $msg->body }}</p>
          <small class="text-muted">{{ $msg->created_at->diffForHumans() }}</small>
        </div>
      @empty
        <p class="text-muted text-center">No messages yet. Start the conversation!</p>
      @endforelse
    </div>
    <div class="card-footer">
      <form method="POST" action="{{ route('messages.store', $trade ?? $otherUser) }}">
        @csrf
        <div class="input-group">
          <input type="text" name="body" class="form-control" placeholder="Type a message..." required>
          <button type="submit" class="btn btn-primary">Send</button>
        </div>
      </form>
    </div>
  </div>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/disputes/show.blade.php", r"""@extends('layouts.app')
@section('title', 'Dispute #{{ $dispute->id }}')
@section('content')
<div class="container py-4">
  <h2>Dispute #{{ $dispute->id }}</h2>
  <div class="card mb-4">
    <div class="card-body">
      <dl class="row mb-0">
        <dt class="col-sm-3">Trade</dt>
        <dd class="col-sm-9"><a href="{{ route('trades.show', $dispute->trade) }}">#{{ $dispute->trade->trade_id }}</a></dd>
        <dt class="col-sm-3">Opened by</dt>
        <dd class="col-sm-9">{{ $dispute->opener->username }}</dd>
        <dt class="col-sm-3">Status</dt>
        <dd class="col-sm-9"><span class="badge bg-warning text-dark">{{ $dispute->status }}</span></dd>
        <dt class="col-sm-3">Reason</dt>
        <dd class="col-sm-9">{{ $dispute->reason }}</dd>
        @if($dispute->resolution)
          <dt class="col-sm-3">Resolution</dt>
          <dd class="col-sm-9">{{ $dispute->resolution }}</dd>
        @endif
      </dl>
    </div>
  </div>
  <h5>Messages</h5>
  @forelse($dispute->messages as $msg)
    <div class="card mb-2">
      <div class="card-body py-2">
        <strong>{{ $msg->user->username }}</strong>
        <small class="text-muted float-end">{{ $msg->created_at->diffForHumans() }}</small>
        <p class="mb-0 mt-1">{{ $msg->message }}</p>
      </div>
    </div>
  @empty
    <p class="text-muted">No messages in this dispute.</p>
  @endforelse
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/user-edit.blade.php", r"""@extends('layouts.app')
@section('title', 'Edit User')
@section('content')
<div class="container py-4">
  <h2>Edit User: {{ $user->username }}</h2>
  <form method="POST" action="{{ route('admin.users.update', $user) }}">
    @csrf @method('PUT')
    <div class="mb-3">
      <label class="form-label">Name</label>
      <input type="text" name="name" class="form-control" value="{{ $user->name }}" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Email</label>
      <input type="email" name="email" class="form-control" value="{{ $user->email }}" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Role</label>
      <select name="role" class="form-select">
        @foreach(['user','moderator','admin'] as $role)
          <option value="{{ $role }}" @selected($user->role===$role)>{{ ucfirst($role) }}</option>
        @endforeach
      </select>
    </div>
    <div class="form-check mb-3">
      <input class="form-check-input" type="checkbox" name="is_active" value="1" @checked($user->is_active)>
      <label class="form-check-label">Active</label>
    </div>
    <button type="submit" class="btn btn-primary">Save Changes</button>
    <a href="{{ route('admin.users') }}" class="btn btn-secondary">Cancel</a>
  </form>
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/disputes.blade.php", r"""@extends('layouts.app')
@section('title', 'Admin — Disputes')
@section('content')
<div class="container py-4">
  <h2>Disputes</h2>
  <div class="table-responsive">
    <table class="table table-hover">
      <thead>
        <tr><th>#</th><th>Trade</th><th>Opened By</th><th>Status</th><th>Created</th><th>Actions</th></tr>
      </thead>
      <tbody>
        @forelse($disputes as $dispute)
          <tr>
            <td>{{ $dispute->id }}</td>
            <td><a href="{{ route('trades.show', $dispute->trade) }}">{{ $dispute->trade->trade_id }}</a></td>
            <td>{{ $dispute->opener->username }}</td>
            <td><span class="badge bg-warning text-dark">{{ $dispute->status }}</span></td>
            <td>{{ $dispute->created_at->diffForHumans() }}</td>
            <td>
              <a href="{{ route('admin.disputes.show', $dispute) }}" class="btn btn-sm btn-info">View</a>
              @if($dispute->status !== 'resolved')
                <form method="POST" action="{{ route('admin.disputes.resolve', $dispute) }}" class="d-inline">
                  @csrf
                  <button type="submit" class="btn btn-sm btn-success" onclick="return confirm('Resolve this dispute?')">Resolve</button>
                </form>
              @endif
            </td>
          </tr>
        @empty
          <tr><td colspan="6" class="text-center text-muted">No disputes found.</td></tr>
        @endforelse
      </tbody>
    </table>
  </div>
  {{ $disputes->links() }}
</div>
@endsection
""")

    write_file(f"{APP_DIR}/resources/views/admin/settings.blade.php", r"""@extends('layouts.app')
@section('title', 'Admin — Settings')
@section('content')
<div class="container py-4">
  <h2>Site Settings</h2>
  @if(session('success'))
    <div class="alert alert-success">{{ session('success') }}</div>
  @endif
  <form method="POST" action="{{ route('admin.settings.update') }}">
    @csrf
    @foreach($settings as $setting)
      <div class="mb-3">
        <label class="form-label text-capitalize">{{ str_replace('_', ' ', $setting->key) }}</label>
        <input type="text" name="settings[{{ $setting->key }}]" class="form-control" value="{{ $setting->value }}">
      </div>
    @endforeach
    <button type="submit" class="btn btn-primary">Save Settings</button>
  </form>
</div>
@endsection
""")

    # ── Static / Bootstrap Files ──────────────────────────────────────────────
    write_file(f"{APP_DIR}/webpack.mix.js", r"""const mix = require('laravel-mix');

mix.js('resources/js/app.js', 'public/js')
   .sass('resources/sass/app.scss', 'public/css')
   .version();
""")

    write_file(f"{APP_DIR}/routes/channels.php", r"""<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
""")

    for path in [
        "bootstrap/cache/.gitignore",
        "storage/app/.gitignore",
        "storage/app/public/.gitignore",
        "storage/framework/.gitignore",
        "storage/framework/cache/.gitignore",
        "storage/framework/cache/data/.gitignore",
        "storage/framework/sessions/.gitignore",
        "storage/framework/testing/.gitignore",
        "storage/framework/views/.gitignore",
        "storage/logs/.gitignore",
    ]:
        write_file(f"{APP_DIR}/{path}", "*\n!.gitignore\n")

    # ── Additional Providers ──────────────────────────────────────────────────
    write_file(f"{APP_DIR}/app/Providers/EventServiceProvider.php", r"""<?php

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
        //
    }
}
""")

    write_file(f"{APP_DIR}/app/Providers/BroadcastServiceProvider.php", r"""<?php

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

    # ── Missing Middleware (skip if already written by phase6_application) ────
    import os as _os
    if not _os.path.exists(f"{APP_DIR}/app/Http/Middleware/RedirectIfAuthenticated.php"):
        write_file(f"{APP_DIR}/app/Http/Middleware/RedirectIfAuthenticated.php", r"""<?php

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

    print("[OK] Phase 6b complete")


def phase7_finalize():
    print("\n=== Phase 7: Finalize ===")
    commands = [
        f"cd {APP_DIR} && php artisan key:generate --force",
        f"cd {APP_DIR} && php artisan migrate --force",
        f"cd {APP_DIR} && php artisan db:seed --force",
        f"cd {APP_DIR} && php artisan config:cache",
        f"cd {APP_DIR} && php artisan route:cache",
        f"cd {APP_DIR} && php artisan view:cache",
        f"cd {APP_DIR} && php artisan storage:link",
        f"chown -R www-data:www-data {APP_DIR}",
        f"find {APP_DIR} -type f -exec chmod 644 {{}} \\;",
        f"find {APP_DIR} -type d -exec chmod 755 {{}} \\;",
        f"chmod -R 775 {APP_DIR}/storage {APP_DIR}/bootstrap/cache",
        f"chmod 755 {APP_DIR}/artisan",
        "systemctl restart nginx || systemctl restart apache2 || true",
    ]
    for cmd in commands:
        run(cmd)
    print("[OK] Phase 7 complete")


def phase8_verify():
    print("\n=== Phase 8: Verify ===")
    checks = {
        "nginx":   "systemctl is-active nginx",
        "mysql":   "systemctl is-active mariadb || systemctl is-active mysql",
        "monerod": "systemctl is-active monerod",
        "queue":   "systemctl is-active capitalmonero-queue",
        "port_80":  "ss -tlnp | grep ':80 '",
        "port_443": "ss -tlnp | grep ':443 '",
    }
    results = {}
    for name, cmd in checks.items():
        r = run(cmd)
        results[name] = "OK" if r.returncode == 0 else "FAIL"

    db_check = run(
        f"mysql -u {DB_USER} -e 'SELECT COUNT(*) FROM users;' {DB_NAME} 2>&1"
    )
    results["database"] = "OK" if db_check.returncode == 0 else "FAIL"

    php_check = run(f"cd {APP_DIR} && php artisan --version 2>&1")
    results["laravel"] = "OK" if php_check.returncode == 0 else "FAIL"

    print("\n" + "=" * 50)
    print("  CAPITALMONERO SETUP SUMMARY")
    print("=" * 50)
    print(f"  Site URL:   https://{DOMAIN}")
    print(f"  Tor Onion:  {TOR_ONION}")
    print(f"  App Dir:    {APP_DIR}")
    print(f"  Database:   {DB_NAME}")
    print()
    print("  Service Status:")
    for name, status in results.items():
        icon = "✓" if status == "OK" else "✗"
        print(f"    {icon} {name:<15} {status}")
    print()
    print("  Admin credentials stored in:")
    print(f"    {APP_DIR}/credentials.json")
    print()
    print("  Default admin account:")
    print("    Email:    admin@capitalmonero.com")
    print("    Password: ChangeMe123!  ← CHANGE IMMEDIATELY")
    print("=" * 50)
    print("[OK] Phase 8 complete")


def main():
    print("=" * 60)
    print(f"  CapitalMonero Setup — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    phase1_database()
    phase2_composer()
    phase3_npm()
    phase4_monerod()
    phase5_webserver()
    phase6_application()
    phase6b_additional_files()
    phase7_finalize()
    phase8_verify()
    print(f"\n[DONE] All phases complete — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    main()
