"""
Chat Routes
=============
E2E encrypted trade chat.
Server stores only ciphertext — decryption happens client-side.
"""

import logging

import bleach
from flask import Blueprint, request, jsonify
from app import db, limiter
from app.models.message import Message
from app.models.trade import Trade
from app.routes.auth import get_current_user
from app.services.encryption import validate_message_structure

logger = logging.getLogger(__name__)

chat_bp = Blueprint('chat', __name__)


@chat_bp.route('/<trade_id>/messages', methods=['GET'])
@limiter.limit('200/hour')
def get_messages(trade_id):
    """
    Get encrypted messages for a trade (participants only).

    Query params:
        after: ISO timestamp — return messages after this time
        limit: Max messages to return (default 50, max 200)
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({'error': 'Not authorized'}), 403

    query = Message.query.filter_by(trade_id=trade_id)

    after = request.args.get('after')
    if after:
        from datetime import datetime
        try:
            after_dt = datetime.fromisoformat(after)
            query = query.filter(Message.created_at > after_dt)
        except ValueError:
            pass

    limit = min(200, max(1, request.args.get('limit', 50, type=int)))
    messages = query.order_by(Message.created_at.asc()).limit(limit).all()

    return jsonify({
        'messages': [m.to_dict() for m in messages],
        'count': len(messages),
    }), 200


@chat_bp.route('/<trade_id>/messages', methods=['POST'])
@limiter.limit('120/hour')
def send_message(trade_id):
    """
    Send an encrypted message in a trade chat.

    Request body:
        {
            "ciphertext": "base64-encoded-nacl-box-ciphertext",
            "nonce": "base64-encoded-24-byte-nonce",
            "sender_ephemeral_pubkey": "base64-encoded-32-byte-pubkey"
        }

    The server NEVER decrypts messages. It stores only:
    - Ciphertext (encrypted by sender using recipient's public key)
    - Nonce (unique per message)
    - Sender's ephemeral public key (so recipient can decrypt)
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({'error': 'Not authorized'}), 403

    # Only allow chat on active trades
    if trade.status in (Trade.STATUS_COMPLETED, Trade.STATUS_CANCELLED):
        return jsonify({'error': 'Trade is closed'}), 400

    data = request.get_json(silent=True) or {}
    ciphertext = data.get('ciphertext', '')
    nonce = data.get('nonce', '')
    sender_pubkey = data.get('sender_ephemeral_pubkey', '')

    if not all([ciphertext, nonce, sender_pubkey]):
        return jsonify({'error': 'ciphertext, nonce, and sender_ephemeral_pubkey required'}), 400

    # Validate message structure (NOT decrypt — server can't)
    try:
        validate_message_structure(ciphertext, nonce, sender_pubkey)
    except ValueError as exc:
        return jsonify({'error': str(exc)}), 400

    # Size limit: 64KB per message
    if len(ciphertext) > 65536:
        return jsonify({'error': 'Message too large (max 64KB)'}), 400

    message = Message(
        trade_id=trade_id,
        sender_id=user.id,
        ciphertext=ciphertext,
        nonce=nonce,
        sender_ephemeral_pubkey=sender_pubkey,
    )
    db.session.add(message)
    db.session.commit()

    logger.debug('Encrypted message sent in trade %s by %s', trade_id[:8], user.nickname)

    return jsonify({'message': message.to_dict()}), 201
