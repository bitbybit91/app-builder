<?php

namespace App\Core;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $pdo = null;

    public static function connection(): PDO
    {
        if (self::$pdo === null) {
            $config = App::config('db');
            $path = $config['path'];

            $dir = dirname($path);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }

            try {
                self::$pdo = new PDO('sqlite:' . $path);
                self::$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                self::$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
                self::$pdo->exec('PRAGMA journal_mode=WAL');
                self::$pdo->exec('PRAGMA foreign_keys=ON');
            } catch (PDOException $e) {
                throw new \RuntimeException('Database connection failed: ' . $e->getMessage());
            }
        }

        return self::$pdo;
    }

    public static function query(string $sql, array $params = []): \PDOStatement
    {
        $stmt = self::connection()->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public static function lastInsertId(): string
    {
        return self::connection()->lastInsertId();
    }
}
