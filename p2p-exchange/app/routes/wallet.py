from flask import Blueprint, request, jsonify, current_app
from app.routes.auth import get_current_user
from app.services.xmr import MoneroRPCClient, MoneroRPCError

wallet_bp = Blueprint('wallet', __name__)

def get_xmr_client():
    endpoint = current_app.config.get('MONERO_RPC_URL', 'http://127.0.0.1:18083/json_rpc')
    user = current_app.config.get('MONERO_RPC_USER', '')
    password = current_app.config.get('MONERO_RPC_PASS', '')
    return MoneroRPCClient(endpoint, user, password)

@wallet_bp.route('/balance', methods=['GET'])
def get_balance():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    try:
        xmr = get_xmr_client()
        balance = xmr.get_balance()
        return jsonify(balance)
    except MoneroRPCError:
        current_app.logger.warning('XMR RPC error in get_balance', exc_info=True)
        return jsonify({'error': 'XMR RPC unavailable', 'balance': 0, 'unlocked_balance': 0}), 503

@wallet_bp.route('/deposit', methods=['POST'])
def get_deposit_address():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    try:
        xmr = get_xmr_client()
        result = xmr.create_subaddress(label=f'user_{user.id}_deposit')
        return jsonify({'address': result['address'], 'address_index': result['address_index']})
    except MoneroRPCError:
        current_app.logger.warning('XMR RPC error in get_deposit_address', exc_info=True)
        return jsonify({'error': 'XMR RPC unavailable'}), 503

@wallet_bp.route('/withdraw', methods=['POST'])
def withdraw():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    data = request.get_json() or {}
    address = data.get('address', '')
    amount_xmr = data.get('amount_xmr', 0)
    if not address or not amount_xmr:
        return jsonify({'error': 'address and amount_xmr required'}), 400
    try:
        xmr = get_xmr_client()
        amount_atomic = int(float(amount_xmr) * 1e12)
        result = xmr.transfer([{'amount': amount_atomic, 'address': address}])
        return jsonify({'success': True, 'txid': result['tx_hash'], 'fee': result['fee']})
    except MoneroRPCError:
        current_app.logger.warning('XMR RPC error in withdraw', exc_info=True)
        return jsonify({'error': 'XMR RPC unavailable'}), 503

@wallet_bp.route('/transactions', methods=['GET'])
def get_transactions():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    try:
        xmr = get_xmr_client()
        transfers = xmr.get_transfers()
        return jsonify({'transactions': transfers})
    except MoneroRPCError:
        current_app.logger.warning('XMR RPC error in get_transactions', exc_info=True)
        return jsonify({'error': 'XMR RPC unavailable', 'transactions': {}}), 503

@wallet_bp.route('/status', methods=['GET'])
def network_status():
    try:
        xmr = get_xmr_client()
        height = xmr.get_block_count()
        return jsonify({'status': 'connected', 'height': height})
    except MoneroRPCError:
        current_app.logger.warning('XMR RPC error in network_status', exc_info=True)
        return jsonify({'status': 'disconnected', 'error': 'XMR RPC unavailable'}), 503

