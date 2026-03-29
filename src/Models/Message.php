<?php

namespace App\Models;

use App\Core\Database;

class Message
{
    public static function create(int $tradeResponseId, int $senderId, string $body): int
    {
        Database::query(
            'INSERT INTO messages (trade_response_id, sender_id, body) VALUES (?, ?, ?)',
            [$tradeResponseId, $senderId, $body]
        );
        return (int)Database::lastInsertId();
    }

    public static function listByTradeResponse(int $tradeResponseId): array
    {
        $stmt = Database::query(
            'SELECT m.*, u.username FROM messages m JOIN users u ON m.sender_id = u.id
             WHERE m.trade_response_id = ? ORDER BY m.created_at ASC',
            [$tradeResponseId]
        );
        return $stmt->fetchAll();
    }
}
