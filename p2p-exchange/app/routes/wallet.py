"""
Wallet Routes
==============
XMR wallet operations: balance, deposit, withdraw, transactions.
"""

import logging

from flask import Blueprint, request, jsonify, current_app
from app import limiter
from app.routes.auth import get_current_user
from app.services.xmr import XMRService

logger = logging.getLogger(__name__)

wallet_bp = Blueprint('wallet', __name__)


def _get_xmr_service():
    """Create an XMRService from app config."""
    config = current_app.config
    return XMRService(
        rpc_endpoints=config['XMR_RPC_ENDPOINTS'],
        wallet_rpc_url=config['XMR_WALLET_RPC_URL'],
        rpc_user=config['XMR_RPC_USER'],
        rpc_password=config['XMR_RPC_PASSWORD'],
        wallet_rpc_user=config['XMR_WALLET_RPC_USER'],
        wallet_rpc_password=config['XMR_WALLET_RPC_PASSWORD'],
    )


@wallet_bp.route('/balance', methods=['GET'])
@limiter.limit('60/hour')
def get_balance():
    """
    Get XMR wallet balance.

    Returns:
        200: {"balance": float, "unlocked_balance": float}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    try:
        xmr = _get_xmr_service()
        balance = xmr.get_balance()
        return jsonify(balance), 200
    except ConnectionError as exc:
        logger.error('Wallet balance check failed: %s', exc)
        return jsonify({'error': 'Wallet service unavailable'}), 503


@wallet_bp.route('/deposit', methods=['POST'])
@limiter.limit('20/hour')
def generate_deposit_address():
    """
    Generate a new deposit address.

    Returns:
        201: {"address": str, "address_index": int}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    try:
        xmr = _get_xmr_service()
        result = xmr.create_address(label=f'deposit-{user.id}')
        return jsonify(result), 201
    except ConnectionError as exc:
        logger.error('Deposit address generation failed: %s', exc)
        return jsonify({'error': 'Wallet service unavailable'}), 503


@wallet_bp.route('/withdraw', methods=['POST'])
@limiter.limit('10/hour')
def withdraw():
    """
    Withdraw XMR to an external address.

    Request body:
        {
            "address": "4...",
            "amount": 0.5
        }

    Returns:
        200: {"tx_hash": str, "fee": float}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    data = request.get_json(silent=True) or {}
    address = data.get('address', '')
    amount = data.get('amount')

    if not address or not amount:
        return jsonify({'error': 'address and amount required'}), 400

    amount = float(amount)
    if amount <= 0:
        return jsonify({'error': 'Amount must be positive'}), 400

    # Basic XMR address validation (starts with 4 or 8, length 95 or 106)
    if not (address.startswith(('4', '8')) and len(address) in (95, 106)):
        return jsonify({'error': 'Invalid XMR address format'}), 400

    try:
        xmr = _get_xmr_service()
        result = xmr.transfer(destinations=[{'address': address, 'amount': amount}])
        logger.info('Withdrawal: %s XMR to %s...', amount, address[:12])
        return jsonify(result), 200
    except ConnectionError as exc:
        logger.error('Withdrawal failed: %s', exc)
        return jsonify({'error': 'Wallet service unavailable'}), 503
    except Exception as exc:
        logger.error('Withdrawal error: %s', exc)
        return jsonify({'error': 'Withdrawal failed'}), 500


@wallet_bp.route('/transactions', methods=['GET'])
@limiter.limit('60/hour')
def get_transactions():
    """
    Get transaction history.

    Returns:
        200: {"transactions": [...]}
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    try:
        xmr = _get_xmr_service()
        transactions = xmr.get_transactions()
        return jsonify({'transactions': transactions}), 200
    except ConnectionError as exc:
        logger.error('Transaction history failed: %s', exc)
        return jsonify({'error': 'Wallet service unavailable'}), 503


@wallet_bp.route('/network', methods=['GET'])
@limiter.limit('30/hour')
def network_status():
    """
    Get XMR network status (block height, etc.).

    Returns:
        200: {"block_height": int, "status": "ok"}
    """
    try:
        xmr = _get_xmr_service()
        height = xmr.get_block_height()
        return jsonify({'block_height': height, 'status': 'ok'}), 200
    except ConnectionError as exc:
        logger.error('Network status check failed: %s', exc)
        return jsonify({'error': 'Network unavailable', 'status': 'error'}), 503
