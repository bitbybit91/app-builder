<?php

namespace App\Models;

use App\Core\Database;

class TradeResponse
{
    public static function create(int $tradeId, int $responderId, float $amount, string $message = ''): int
    {
        Database::query(
            'INSERT INTO trade_responses (trade_id, responder_id, amount, message) VALUES (?, ?, ?, ?)',
            [$tradeId, $responderId, $amount, $message]
        );
        return (int)Database::lastInsertId();
    }

    public static function findById(int $id): ?array
    {
        $stmt = Database::query(
            'SELECT tr.*, u.username FROM trade_responses tr JOIN users u ON tr.responder_id = u.id WHERE tr.id = ?',
            [$id]
        );
        return $stmt->fetch() ?: null;
    }

    public static function listByTrade(int $tradeId): array
    {
        $stmt = Database::query(
            'SELECT tr.*, u.username FROM trade_responses tr JOIN users u ON tr.responder_id = u.id
             WHERE tr.trade_id = ? ORDER BY tr.created_at DESC',
            [$tradeId]
        );
        return $stmt->fetchAll();
    }

    public static function listByUser(int $userId): array
    {
        $stmt = Database::query(
            'SELECT tr.*, t.title as trade_title, t.type as trade_type
             FROM trade_responses tr JOIN trades t ON tr.trade_id = t.id
             WHERE tr.responder_id = ? ORDER BY tr.created_at DESC',
            [$userId]
        );
        return $stmt->fetchAll();
    }

    public static function updateStatus(int $id, string $status): void
    {
        Database::query(
            'UPDATE trade_responses SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
            [$status, $id]
        );
    }
}
