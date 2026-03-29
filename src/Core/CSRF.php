<?php

namespace App\Core;

class CSRF
{
    public static function token(): string
    {
        return $_SESSION['csrf_token'] ?? '';
    }

    public static function field(): string
    {
        $token = htmlspecialchars(self::token(), ENT_QUOTES, 'UTF-8');
        return '<input type="hidden" name="csrf_token" value="' . $token . '">';
    }

    public static function verify(): bool
    {
        $token = $_POST['csrf_token'] ?? '';
        if (empty($token) || !hash_equals($_SESSION['csrf_token'], $token)) {
            http_response_code(403);
            echo 'Invalid CSRF token.';
            exit;
        }
        return true;
    }
}
