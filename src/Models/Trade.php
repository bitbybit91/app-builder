<?php

namespace App\Models;

use App\Core\Database;

class Trade
{
    public static function create(array $data): int
    {
        Database::query(
            'INSERT INTO trades (user_id, type, title, description, amount_min, amount_max, price_per_xmr, currency, payment_method, location)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                $data['user_id'],
                $data['type'],
                $data['title'],
                $data['description'] ?? '',
                $data['amount_min'],
                $data['amount_max'],
                $data['price_per_xmr'] ?? null,
                $data['currency'] ?? 'USD',
                $data['payment_method'],
                $data['location'] ?? '',
            ]
        );
        return (int)Database::lastInsertId();
    }

    public static function findById(int $id): ?array
    {
        $stmt = Database::query(
            'SELECT t.*, u.username, u.reputation, u.trades_completed
             FROM trades t JOIN users u ON t.user_id = u.id
             WHERE t.id = ?',
            [$id]
        );
        return $stmt->fetch() ?: null;
    }

    public static function listByType(string $type, int $limit = 20, int $offset = 0): array
    {
        $stmt = Database::query(
            'SELECT t.*, u.username, u.reputation, u.trades_completed
             FROM trades t JOIN users u ON t.user_id = u.id
             WHERE t.type = ? AND t.status = ?
             ORDER BY t.created_at DESC LIMIT ? OFFSET ?',
            [$type, 'open', $limit, $offset]
        );
        return $stmt->fetchAll();
    }

    public static function listAll(int $limit = 20, int $offset = 0): array
    {
        $stmt = Database::query(
            'SELECT t.*, u.username, u.reputation, u.trades_completed
             FROM trades t JOIN users u ON t.user_id = u.id
             WHERE t.status = ?
             ORDER BY t.created_at DESC LIMIT ? OFFSET ?',
            ['open', $limit, $offset]
        );
        return $stmt->fetchAll();
    }

    public static function listByUser(int $userId): array
    {
        $stmt = Database::query(
            'SELECT * FROM trades WHERE user_id = ? ORDER BY created_at DESC',
            [$userId]
        );
        return $stmt->fetchAll();
    }

    public static function updateStatus(int $id, string $status): void
    {
        Database::query(
            'UPDATE trades SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [$status, $id]
        );
    }

    public static function countByType(string $type): int
    {
        $stmt = Database::query(
            'SELECT COUNT(*) as cnt FROM trades WHERE type = ? AND status = ?',
            [$type, 'open']
        );
        $row = $stmt->fetch();
        return $row ? (int)$row['cnt'] : 0;
    }

    public static function countAll(): int
    {
        $stmt = Database::query("SELECT COUNT(*) as cnt FROM trades WHERE status = 'open'");
        $row = $stmt->fetch();
        return $row ? (int)$row['cnt'] : 0;
    }

    public static function search(string $query, int $limit = 20): array
    {
        $like = '%' . $query . '%';
        $stmt = Database::query(
            'SELECT t.*, u.username, u.reputation, u.trades_completed
             FROM trades t JOIN users u ON t.user_id = u.id
             WHERE t.status = ? AND (t.title LIKE ? OR t.description LIKE ? OR t.payment_method LIKE ?)
             ORDER BY t.created_at DESC LIMIT ?',
            ['open', $like, $like, $like, $limit]
        );
        return $stmt->fetchAll();
    }
}
