"""
Trades Routes
==============
Initiate, manage, and complete P2P trades.
"""

import logging
from datetime import datetime, timezone

from flask import Blueprint, request, jsonify, current_app
from app import db, limiter
from app.models.trade import Trade
from app.models.offer import Offer
from app.routes.auth import get_current_user
from app.services.xmr import XMRService
from app.services.escrow import EscrowService

logger = logging.getLogger(__name__)

trades_bp = Blueprint('trades', __name__)


def _get_escrow_service():
    """Create an EscrowService from app config."""
    config = current_app.config
    xmr = XMRService(
        rpc_endpoints=config['XMR_RPC_ENDPOINTS'],
        wallet_rpc_url=config['XMR_WALLET_RPC_URL'],
        rpc_user=config['XMR_RPC_USER'],
        rpc_password=config['XMR_RPC_PASSWORD'],
        wallet_rpc_user=config['XMR_WALLET_RPC_USER'],
        wallet_rpc_password=config['XMR_WALLET_RPC_PASSWORD'],
    )
    return EscrowService(
        xmr_service=xmr,
        confirmations_required=config['ESCROW_CONFIRMATIONS_REQUIRED'],
        timeout_hours=config['ESCROW_TIMEOUT_HOURS'],
        bond_percent=config['ARBITRATION_BOND_PERCENT'],
    )


@trades_bp.route('', methods=['POST'])
@limiter.limit('20/hour')
def initiate_trade():
    """
    Initiate a trade from an offer.

    Request body:
        {
            "offer_id": "uuid",
            "crypto_amount": 1.5,
            "fiat_amount": 250.00,
            "buyer_wallet_address": "4..."
        }

    Returns:
        201: {"trade": {...}, "escrow_address": "..."}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    data = request.get_json(silent=True) or {}
    offer_id = data.get('offer_id')
    crypto_amount = data.get('crypto_amount')
    fiat_amount = data.get('fiat_amount')
    buyer_wallet = data.get('buyer_wallet_address', '')

    if not all([offer_id, crypto_amount, fiat_amount]):
        return jsonify({'error': 'offer_id, crypto_amount, and fiat_amount required'}), 400

    offer = Offer.query.get(offer_id)
    if not offer or not offer.is_active:
        return jsonify({'error': 'Offer not found or inactive'}), 404

    # Cannot trade with yourself
    if offer.user_id == user.id:
        return jsonify({'error': 'Cannot trade with yourself'}), 400

    # Determine buyer/seller based on offer type
    if offer.offer_type == 'sell':
        buyer_id = user.id
        seller_id = offer.user_id
    else:
        buyer_id = offer.user_id
        seller_id = user.id

    # Validate fiat amount is within offer range
    if float(fiat_amount) < offer.min_amount or float(fiat_amount) > offer.max_amount:
        return jsonify({'error': f'Amount must be between {offer.min_amount} and {offer.max_amount}'}), 400

    trade = Trade(
        offer_id=offer.id,
        buyer_id=buyer_id,
        seller_id=seller_id,
        crypto_amount=float(crypto_amount),
        fiat_amount=float(fiat_amount),
        fiat_currency=offer.fiat_currency,
        payment_method=offer.payment_method,
        buyer_wallet_address=buyer_wallet,
        status=Trade.STATUS_INITIATED,
    )
    db.session.add(trade)
    db.session.commit()

    # Generate escrow address
    escrow_address = None
    try:
        escrow_svc = _get_escrow_service()
        escrow_address = escrow_svc.create_escrow_address(trade)
    except Exception as exc:
        logger.error('Failed to create escrow address: %s', exc)
        # Trade still created; escrow address can be assigned later

    logger.info('Trade initiated: %s (buyer=%s, seller=%s)',
                trade.id[:8], buyer_id[:8], seller_id[:8])

    return jsonify({
        'trade': trade.to_dict(include_escrow=True),
        'escrow_address': escrow_address,
    }), 201


@trades_bp.route('', methods=['GET'])
@limiter.limit('100/hour')
def list_trades():
    """
    List trades for the current user.

    Query params:
        status: Filter by status
        role: 'buyer', 'seller', or 'all' (default 'all')
        page: Page number
        per_page: Results per page
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    role = request.args.get('role', 'all')
    if role == 'buyer':
        query = Trade.query.filter_by(buyer_id=user.id)
    elif role == 'seller':
        query = Trade.query.filter_by(seller_id=user.id)
    else:
        query = Trade.query.filter(
            (Trade.buyer_id == user.id) | (Trade.seller_id == user.id)
        )

    status = request.args.get('status')
    if status and status in Trade.VALID_STATUSES:
        query = query.filter_by(status=status)

    query = query.order_by(Trade.created_at.desc())

    page = max(1, request.args.get('page', 1, type=int))
    per_page = min(100, max(1, request.args.get('per_page', 20, type=int)))
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)

    return jsonify({
        'trades': [t.to_dict() for t in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages,
    }), 200


@trades_bp.route('/<trade_id>', methods=['GET'])
@limiter.limit('200/hour')
def get_trade(trade_id):
    """Get trade details (participants only)."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({'error': 'Not authorized'}), 403

    return jsonify({'trade': trade.to_dict(include_escrow=True)}), 200


@trades_bp.route('/<trade_id>/escrow-funded', methods=['POST'])
@limiter.limit('50/hour')
def mark_escrow_funded(trade_id):
    """
    Seller provides the escrow transaction ID after sending XMR.

    Request body:
        {"tx_id": "hash"}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id != trade.seller_id:
        return jsonify({'error': 'Only seller can mark escrow funded'}), 403

    if trade.status != Trade.STATUS_INITIATED:
        return jsonify({'error': f'Trade is already {trade.status}'}), 400

    data = request.get_json(silent=True) or {}
    tx_id = data.get('tx_id', '')
    if not tx_id:
        return jsonify({'error': 'tx_id required'}), 400

    trade.escrow_tx_id = tx_id
    trade.status = Trade.STATUS_ESCROW_FUNDED
    trade.escrow_funded_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({'trade': trade.to_dict(include_escrow=True)}), 200


@trades_bp.route('/<trade_id>/fiat-sent', methods=['POST'])
@limiter.limit('50/hour')
def mark_fiat_sent(trade_id):
    """Buyer marks fiat payment as sent."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id != trade.buyer_id:
        return jsonify({'error': 'Only buyer can mark fiat sent'}), 403

    if trade.status != Trade.STATUS_ESCROW_FUNDED:
        return jsonify({'error': 'Escrow must be funded first'}), 400

    trade.status = Trade.STATUS_FIAT_SENT
    trade.fiat_sent_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({'trade': trade.to_dict()}), 200


@trades_bp.route('/<trade_id>/fiat-received', methods=['POST'])
@limiter.limit('50/hour')
def mark_fiat_received(trade_id):
    """Seller confirms fiat payment received → triggers escrow release."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id != trade.seller_id:
        return jsonify({'error': 'Only seller can confirm fiat received'}), 403

    if trade.status != Trade.STATUS_FIAT_SENT:
        return jsonify({'error': 'Buyer must mark fiat sent first'}), 400

    trade.status = Trade.STATUS_FIAT_RECEIVED
    db.session.commit()

    # Release escrow
    try:
        escrow_svc = _get_escrow_service()
        result = escrow_svc.release_escrow(trade)
        return jsonify({'trade': trade.to_dict(), 'release': result}), 200
    except Exception as exc:
        logger.error('Escrow release failed: %s', exc)
        return jsonify({'trade': trade.to_dict(), 'error': 'Escrow release failed'}), 500


@trades_bp.route('/<trade_id>/cancel', methods=['POST'])
@limiter.limit('20/hour')
def cancel_trade(trade_id):
    """Cancel a trade (only before fiat is sent)."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({'error': 'Not authorized'}), 403

    if trade.status not in (Trade.STATUS_INITIATED, Trade.STATUS_ESCROW_FUNDED):
        return jsonify({'error': 'Cannot cancel at this stage'}), 400

    trade.status = Trade.STATUS_CANCELLED
    trade.cancelled_at = datetime.now(timezone.utc)
    db.session.commit()

    return jsonify({'trade': trade.to_dict()}), 200


@trades_bp.route('/<trade_id>/dispute', methods=['POST'])
@limiter.limit('10/hour')
def open_dispute(trade_id):
    """
    Open a dispute on a trade.

    Request body:
        {"reason": "Seller did not release funds after payment"}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    trade = Trade.query.get(trade_id)
    if not trade:
        return jsonify({'error': 'Trade not found'}), 404

    if user.id not in (trade.buyer_id, trade.seller_id):
        return jsonify({'error': 'Not authorized'}), 403

    data = request.get_json(silent=True) or {}
    reason = data.get('reason', '')
    if not reason:
        return jsonify({'error': 'Dispute reason required'}), 400

    try:
        escrow_svc = _get_escrow_service()
        escrow_svc.open_dispute(trade, user.id, reason)
        return jsonify({'trade': trade.to_dict()}), 200
    except ValueError:
        return jsonify({'error': 'Cannot open dispute on this trade'}), 400
