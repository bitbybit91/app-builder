<?php

declare(strict_types=1);

define('BASE_PATH', dirname(__DIR__));

spl_autoload_register(function (string $class) {
    $prefix = 'App\\';
    $baseDir = BASE_PATH . '/src/';

    if (strncmp($prefix, $class, strlen($prefix)) !== 0) {
        return;
    }

    $relativeClass = substr($class, strlen($prefix));
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

// Initialize database on first run
$dbPath = require BASE_PATH . '/config/app.php';
$dbFile = $dbPath['db']['path'];
if (!file_exists($dbFile)) {
    require BASE_PATH . '/database/migrate.php';
}

$app = new \App\Core\App();
$app->run();
