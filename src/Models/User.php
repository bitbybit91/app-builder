<?php

namespace App\Models;

use App\Core\Database;

class User
{
    public static function create(string $username, string $email, string $passwordHash): int
    {
        Database::query(
            'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
            [$username, $email, $passwordHash]
        );
        return (int)Database::lastInsertId();
    }

    public static function findByUsername(string $username): ?array
    {
        $stmt = Database::query('SELECT * FROM users WHERE username = ?', [$username]);
        return $stmt->fetch() ?: null;
    }

    public static function findByEmail(string $email): ?array
    {
        $stmt = Database::query('SELECT * FROM users WHERE email = ?', [$email]);
        return $stmt->fetch() ?: null;
    }

    public static function findById(int $id): ?array
    {
        $stmt = Database::query('SELECT * FROM users WHERE id = ?', [$id]);
        return $stmt->fetch() ?: null;
    }

    public static function updateProfile(int $id, string $bio): void
    {
        Database::query(
            'UPDATE users SET bio = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [$bio, $id]
        );
    }

    public static function incrementTradesCompleted(int $id): void
    {
        Database::query(
            'UPDATE users SET trades_completed = trades_completed + 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [$id]
        );
    }
}
