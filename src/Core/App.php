<?php

namespace App\Core;

class App
{
    private static array $config = [];
    private Router $router;

    public function __construct()
    {
        self::$config = require __DIR__ . '/../../config/app.php';
        date_default_timezone_set(self::$config['timezone']);
        $this->initSession();
        $this->router = new Router();
        $this->registerRoutes();
    }

    private function initSession(): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_name(self::$config['session']['name']);
            session_set_cookie_params([
                'lifetime' => self::$config['session']['lifetime'],
                'path' => '/',
                'httponly' => true,
                'samesite' => 'Lax',
            ]);
            session_start();
        }

        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
    }

    private function registerRoutes(): void
    {
        $this->router->get('/', ['App\\Controllers\\HomeController', 'index']);
        $this->router->get('/about', ['App\\Controllers\\PageController', 'about']);
        $this->router->get('/faq', ['App\\Controllers\\PageController', 'faq']);
        $this->router->get('/terms', ['App\\Controllers\\PageController', 'terms']);
        $this->router->get('/contact', ['App\\Controllers\\PageController', 'contact']);
        $this->router->post('/contact', ['App\\Controllers\\PageController', 'contactSubmit']);

        $this->router->get('/register', ['App\\Controllers\\AuthController', 'registerForm']);
        $this->router->post('/register', ['App\\Controllers\\AuthController', 'register']);
        $this->router->get('/login', ['App\\Controllers\\AuthController', 'loginForm']);
        $this->router->post('/login', ['App\\Controllers\\AuthController', 'login']);
        $this->router->get('/logout', ['App\\Controllers\\AuthController', 'logout']);

        $this->router->get('/trades', ['App\\Controllers\\TradeController', 'index']);
        $this->router->get('/trades/buy', ['App\\Controllers\\TradeController', 'buyListings']);
        $this->router->get('/trades/sell', ['App\\Controllers\\TradeController', 'sellListings']);
        $this->router->get('/trades/create', ['App\\Controllers\\TradeController', 'createForm']);
        $this->router->post('/trades/create', ['App\\Controllers\\TradeController', 'create']);
        $this->router->get('/trades/view', ['App\\Controllers\\TradeController', 'view']);
        $this->router->post('/trades/respond', ['App\\Controllers\\TradeController', 'respond']);
        $this->router->post('/trades/message', ['App\\Controllers\\TradeController', 'sendMessage']);

        $this->router->get('/dashboard', ['App\\Controllers\\DashboardController', 'index']);
        $this->router->get('/dashboard/trades', ['App\\Controllers\\DashboardController', 'myTrades']);
        $this->router->get('/dashboard/settings', ['App\\Controllers\\DashboardController', 'settings']);
        $this->router->post('/dashboard/settings', ['App\\Controllers\\DashboardController', 'updateSettings']);
    }

    public function run(): void
    {
        $method = $_SERVER['REQUEST_METHOD'];
        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $this->router->dispatch($method, $uri);
    }

    public static function config(string $key = null)
    {
        if ($key === null) {
            return self::$config;
        }
        $keys = explode('.', $key);
        $value = self::$config;
        foreach ($keys as $k) {
            if (!isset($value[$k])) {
                return null;
            }
            $value = $value[$k];
        }
        return $value;
    }
}
