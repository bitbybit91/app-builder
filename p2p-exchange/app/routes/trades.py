from datetime import datetime, timezone
from flask import Blueprint, request, jsonify, current_app
from app import db
from app.models.offer import Offer
from app.models.trade import Trade, TradeStatus
from app.models.user import User
from app.routes.auth import get_current_user
from app.services.escrow import EscrowService
from app.services.xmr import MoneroRPCClient
from app.services.reputation import ReputationService
import bleach

trades_bp = Blueprint('trades', __name__)

def get_xmr_client():
    endpoint = current_app.config.get('MONERO_RPC_URL', 'http://127.0.0.1:18083/json_rpc')
    user = current_app.config.get('MONERO_RPC_USER', '')
    password = current_app.config.get('MONERO_RPC_PASS', '')
    return MoneroRPCClient(endpoint, user, password)

@trades_bp.route('', methods=['GET'])
def list_trades():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trades = Trade.query.filter(
        (Trade.buyer_id == user.id) | (Trade.seller_id == user.id)
    ).order_by(Trade.created_at.desc()).all()
    return jsonify({'trades': [t.to_dict() for t in trades]})

@trades_bp.route('/<int:trade_id>', methods=['GET'])
def get_trade(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id and trade.seller_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    return jsonify(trade.to_dict())

@trades_bp.route('', methods=['POST'])
def initiate_trade():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    data = request.get_json() or {}
    offer_id = data.get('offer_id')
    amount_xmr = data.get('amount_xmr')
    amount_fiat = data.get('amount_fiat')
    if not offer_id or not amount_xmr or not amount_fiat:
        return jsonify({'error': 'offer_id, amount_xmr, amount_fiat required'}), 400
    offer = Offer.query.get_or_404(offer_id)
    if not offer.is_active:
        return jsonify({'error': 'Offer is not active'}), 400
    if offer.user_id == user.id:
        return jsonify({'error': 'Cannot trade with yourself'}), 400
    amount_xmr = float(amount_xmr)
    min_xmr = current_app.config.get('MIN_TRADE_XMR', 0.01)
    max_xmr = current_app.config.get('MAX_TRADE_XMR', 100.0)
    if amount_xmr < min_xmr or amount_xmr > max_xmr:
        return jsonify({'error': f'Amount must be between {min_xmr} and {max_xmr} XMR'}), 400
    if offer.type == 'sell':
        buyer_id = user.id
        seller_id = offer.user_id
    else:
        buyer_id = offer.user_id
        seller_id = user.id
    trade = Trade(
        offer_id=offer_id,
        buyer_id=buyer_id,
        seller_id=seller_id,
        amount_xmr=amount_xmr,
        amount_fiat=float(amount_fiat),
        fiat_currency=offer.fiat_currency,
        status=TradeStatus.INITIATED,
    )
    db.session.add(trade)
    db.session.flush()
    try:
        xmr = get_xmr_client()
        escrow_svc = EscrowService(xmr)
        escrow = escrow_svc.create_escrow(trade.id, amount_xmr)
        trade.escrow_address = escrow['address']
    except Exception as e:
        current_app.logger.error(f"Failed to create escrow: {e}")
        trade.escrow_address = None
    db.session.commit()
    return jsonify(trade.to_dict()), 201

@trades_bp.route('/<int:trade_id>/confirm_escrow', methods=['POST'])
def confirm_escrow(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.seller_id != user.id:
        return jsonify({'error': 'Only seller can confirm escrow'}), 403
    if not trade.can_transition_to(TradeStatus.ESCROW_FUNDED):
        return jsonify({'error': f'Cannot transition from {trade.status} to escrow_funded'}), 400
    data = request.get_json() or {}
    txid = data.get('txid', '')
    trade.escrow_txid = txid
    trade.status = TradeStatus.ESCROW_FUNDED
    trade.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(trade.to_dict())

@trades_bp.route('/<int:trade_id>/fiat_sent', methods=['POST'])
def fiat_sent(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id:
        return jsonify({'error': 'Only buyer can mark fiat as sent'}), 403
    if not trade.can_transition_to(TradeStatus.FIAT_SENT):
        return jsonify({'error': f'Cannot transition from {trade.status}'}), 400
    trade.status = TradeStatus.FIAT_SENT
    trade.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(trade.to_dict())

@trades_bp.route('/<int:trade_id>/fiat_received', methods=['POST'])
def fiat_received(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.seller_id != user.id:
        return jsonify({'error': 'Only seller can confirm fiat received'}), 403
    if not trade.can_transition_to(TradeStatus.FIAT_RECEIVED):
        return jsonify({'error': f'Cannot transition from {trade.status}'}), 400
    trade.status = TradeStatus.FIAT_RECEIVED
    trade.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(trade.to_dict())

@trades_bp.route('/<int:trade_id>/complete', methods=['POST'])
def complete_trade(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.seller_id != user.id:
        return jsonify({'error': 'Only seller can complete the trade (release escrow)'}), 403
    if not trade.can_transition_to(TradeStatus.COMPLETED):
        return jsonify({'error': f'Cannot transition from {trade.status}'}), 400
    buyer = db.session.get(User, trade.buyer_id)
    seller = db.session.get(User, trade.seller_id)
    if buyer:
        ReputationService.update_reputation(buyer, True)
    if seller:
        ReputationService.update_reputation(seller, True)
    trade.status = TradeStatus.COMPLETED
    trade.completed_at = datetime.now(timezone.utc)
    trade.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(trade.to_dict())

@trades_bp.route('/<int:trade_id>/cancel', methods=['POST'])
def cancel_trade(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id and trade.seller_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    if not trade.can_transition_to(TradeStatus.CANCELLED):
        return jsonify({'error': f'Cannot cancel trade in status {trade.status}'}), 400
    trade.status = TradeStatus.CANCELLED
    trade.updated_at = datetime.now(timezone.utc)
    db.session.commit()
    return jsonify(trade.to_dict())

@trades_bp.route('/<int:trade_id>/dispute', methods=['POST'])
def open_dispute(trade_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    trade = Trade.query.get_or_404(trade_id)
    if trade.buyer_id != user.id and trade.seller_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    if not trade.can_transition_to(TradeStatus.DISPUTED):
        return jsonify({'error': f'Cannot dispute trade in status {trade.status}'}), 400
    data = request.get_json() or {}
    reason = bleach.clean(data.get('reason', ''), strip=True)[:1000]
    trade.status = TradeStatus.DISPUTED
    trade.dispute_reason = reason
    trade.updated_at = datetime.now(timezone.utc)
    buyer = db.session.get(User, trade.buyer_id)
    seller = db.session.get(User, trade.seller_id)
    if buyer:
        ReputationService.update_reputation(buyer, False, was_disputed=True)
    if seller:
        ReputationService.update_reputation(seller, False, was_disputed=True)
    db.session.commit()
    return jsonify(trade.to_dict())
