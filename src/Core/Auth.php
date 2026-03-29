<?php

namespace App\Core;

class Auth
{
    public static function user(): ?array
    {
        if (!isset($_SESSION['user_id'])) {
            return null;
        }

        $stmt = Database::query('SELECT * FROM users WHERE id = ?', [$_SESSION['user_id']]);
        return $stmt->fetch() ?: null;
    }

    public static function check(): bool
    {
        return isset($_SESSION['user_id']);
    }

    public static function id(): ?int
    {
        return $_SESSION['user_id'] ?? null;
    }

    public static function login(int $userId): void
    {
        session_regenerate_id(true);
        $_SESSION['user_id'] = $userId;
    }

    public static function logout(): void
    {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(
                session_name(),
                '',
                time() - 42000,
                $params['path'],
                $params['domain'],
                $params['secure'],
                $params['httponly']
            );
        }
        session_destroy();
    }

    public static function requireLogin(): void
    {
        if (!self::check()) {
            $_SESSION['flash_error'] = 'Please log in to continue.';
            header('Location: /login');
            exit;
        }
    }
}
