import bleach
from flask import Blueprint, request, jsonify
from app import db
from app.models.message import Message
from app.models.trade import Trade
from app.routes.auth import get_current_user

chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/trade/<int:trade_id>', methods=['GET'])
def get_messages(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id and trade.seller_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    since_id = request.args.get('since_id', 0, type=int)
    messages = Message.query.filter(
        Message.trade_id == trade_id,
        Message.id > since_id
    ).order_by(Message.created_at.asc()).limit(100).all()
    return jsonify({'messages': [m.to_dict() for m in messages]})

@chat_bp.route('/trade/<int:trade_id>', methods=['POST'])
def send_message(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id and trade.seller_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    data = request.get_json() or {}
    encrypted_content = data.get('encrypted_content', '')
    nonce = data.get('nonce', '')
    ephemeral_public_key = data.get('ephemeral_public_key', '')
    if not encrypted_content or not nonce or not ephemeral_public_key:
        return jsonify({'error': 'encrypted_content, nonce, ephemeral_public_key required'}), 400
    msg = Message(
        trade_id=trade_id,
        sender_id=user.id,
        encrypted_content=bleach.clean(encrypted_content, strip=True)[:65536],
        nonce=bleach.clean(nonce, strip=True)[:256],
        ephemeral_public_key=bleach.clean(ephemeral_public_key, strip=True)[:256],
    )
    db.session.add(msg)
    db.session.commit()
    return jsonify(msg.to_dict()), 201
