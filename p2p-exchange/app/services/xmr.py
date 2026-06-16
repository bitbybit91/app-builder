"""
XMR (Monero) Integration Service
==================================
Connects to Monero daemon and wallet RPC endpoints.
Supports configurable supernode architecture with multiple RPC endpoints.

This service handles:
  - Address generation
  - Balance checking
  - Transaction construction and broadcasting
  - Confirmation monitoring
"""

import logging
import random
from typing import Optional

import requests
from requests.auth import HTTPDigestAuth

logger = logging.getLogger(__name__)


class XMRService:
    """Monero RPC client with multi-endpoint redundancy."""

    def __init__(self, rpc_endpoints, wallet_rpc_url, rpc_user='', rpc_password='',
                 wallet_rpc_user='', wallet_rpc_password=''):
        """
        Initialize XMR service.

        Args:
            rpc_endpoints: List of daemon RPC URLs for redundancy.
            wallet_rpc_url: Monero wallet RPC URL (monero-wallet-rpc).
            rpc_user: Daemon RPC username (optional).
            rpc_password: Daemon RPC password (optional).
            wallet_rpc_user: Wallet RPC username (optional).
            wallet_rpc_password: Wallet RPC password (optional).
        """
        self.rpc_endpoints = rpc_endpoints
        self.wallet_rpc_url = wallet_rpc_url
        self.rpc_auth = HTTPDigestAuth(rpc_user, rpc_password) if rpc_user else None
        self.wallet_auth = HTTPDigestAuth(wallet_rpc_user, wallet_rpc_password) if wallet_rpc_user else None
        self.timeout = 30

    def _daemon_rpc(self, method, params=None):
        """
        Call a Monero daemon JSON-RPC method with automatic failover.

        Args:
            method: RPC method name.
            params: RPC parameters dict.

        Returns:
            dict: RPC result.

        Raises:
            ConnectionError: If all endpoints fail.
        """
        endpoints = self.rpc_endpoints.copy()
        random.shuffle(endpoints)  # Load balance across endpoints

        payload = {
            'jsonrpc': '2.0',
            'id': '0',
            'method': method,
            'params': params or {},
        }

        last_error = None
        for endpoint in endpoints:
            url = endpoint.rstrip('/') + '/json_rpc'
            try:
                response = requests.post(
                    url,
                    json=payload,
                    auth=self.rpc_auth,
                    timeout=self.timeout,
                )
                response.raise_for_status()
                data = response.json()
                if 'error' in data:
                    logger.warning('RPC error from %s: %s', endpoint, data['error'])
                    last_error = data['error']
                    continue
                return data.get('result', {})
            except requests.RequestException as exc:
                logger.warning('RPC connection failed for %s: %s', endpoint, exc)
                last_error = exc
                continue

        raise ConnectionError(f'All XMR RPC endpoints failed. Last error: {last_error}')

    def _wallet_rpc(self, method, params=None):
        """
        Call a Monero wallet JSON-RPC method.

        Args:
            method: RPC method name.
            params: RPC parameters dict.

        Returns:
            dict: RPC result.

        Raises:
            ConnectionError: If wallet RPC is unreachable.
        """
        payload = {
            'jsonrpc': '2.0',
            'id': '0',
            'method': method,
            'params': params or {},
        }

        try:
            response = requests.post(
                self.wallet_rpc_url,
                json=payload,
                auth=self.wallet_auth,
                timeout=self.timeout,
            )
            response.raise_for_status()
            data = response.json()
            if 'error' in data:
                raise ConnectionError(f'Wallet RPC error: {data["error"]}')
            return data.get('result', {})
        except requests.RequestException as exc:
            raise ConnectionError(f'Wallet RPC unreachable: {exc}') from exc

    def get_block_height(self):
        """
        Get the current blockchain height.

        Returns:
            int: Current block height.
        """
        result = self._daemon_rpc('get_block_count')
        return result.get('count', 0)

    def get_info(self):
        """
        Get daemon info (version, height, difficulty, etc.).

        Returns:
            dict: Daemon info.
        """
        return self._daemon_rpc('get_info')

    def create_address(self, account_index=0, label=''):
        """
        Generate a new XMR subaddress.

        Args:
            account_index: Wallet account index.
            label: Optional label for the address.

        Returns:
            dict: {'address': str, 'address_index': int}
        """
        params = {'account_index': account_index}
        if label:
            params['label'] = label
        result = self._wallet_rpc('create_address', params)
        return {
            'address': result.get('address', ''),
            'address_index': result.get('address_index', 0),
        }

    def get_balance(self, account_index=0):
        """
        Check XMR balance.

        Args:
            account_index: Wallet account index.

        Returns:
            dict: {'balance': float, 'unlocked_balance': float} in XMR (not piconero).
        """
        result = self._wallet_rpc('get_balance', {'account_index': account_index})
        # Convert from piconero to XMR
        piconero_to_xmr = 1e-12
        return {
            'balance': result.get('balance', 0) * piconero_to_xmr,
            'unlocked_balance': result.get('unlocked_balance', 0) * piconero_to_xmr,
        }

    def transfer(self, destinations, account_index=0, priority=1):
        """
        Send XMR to one or more destinations.

        Args:
            destinations: List of {'address': str, 'amount': float (XMR)}.
            account_index: Wallet account index.
            priority: Transaction priority (0-3).

        Returns:
            dict: {'tx_hash': str, 'fee': float}
        """
        # Convert XMR to piconero
        dests = [
            {
                'address': d['address'],
                'amount': int(d['amount'] * 1e12),
            }
            for d in destinations
        ]

        params = {
            'destinations': dests,
            'account_index': account_index,
            'priority': priority,
            'ring_size': 16,
            'get_tx_key': True,
        }

        result = self._wallet_rpc('transfer', params)
        return {
            'tx_hash': result.get('tx_hash', ''),
            'tx_key': result.get('tx_key', ''),
            'fee': result.get('fee', 0) * 1e-12,
        }

    def get_transfer_by_txid(self, tx_id):
        """
        Get details of a specific transaction.

        Args:
            tx_id: Transaction hash.

        Returns:
            dict: Transaction details including confirmations.
        """
        result = self._wallet_rpc('get_transfer_by_txid', {'txid': tx_id})
        transfer = result.get('transfer', {})
        return {
            'tx_hash': transfer.get('txid', ''),
            'amount': transfer.get('amount', 0) * 1e-12,
            'fee': transfer.get('fee', 0) * 1e-12,
            'confirmations': transfer.get('confirmations', 0),
            'height': transfer.get('height', 0),
            'timestamp': transfer.get('timestamp', 0),
            'type': transfer.get('type', ''),
        }

    def verify_payment(self, address, tx_id, expected_amount_xmr,
                       min_confirmations=10):
        """
        Verify that a payment was received at an address.

        Args:
            address: Destination XMR address.
            tx_id: Transaction hash.
            expected_amount_xmr: Expected amount in XMR.
            min_confirmations: Minimum confirmations required.

        Returns:
            dict: {'verified': bool, 'confirmations': int, 'amount': float}
        """
        try:
            transfer = self.get_transfer_by_txid(tx_id)
            confirmations = transfer.get('confirmations', 0)
            amount = transfer.get('amount', 0)

            verified = (
                confirmations >= min_confirmations
                and amount >= expected_amount_xmr * 0.999  # Allow tiny rounding
            )

            return {
                'verified': verified,
                'confirmations': confirmations,
                'amount': amount,
            }
        except Exception as exc:
            logger.error('Payment verification failed: %s', exc)
            return {'verified': False, 'confirmations': 0, 'amount': 0}

    def get_transactions(self, account_index=0, pending=True,
                         pool=True, in_transfers=True,
                         out_transfers=True):
        """
        Get transaction history.

        Args:
            account_index: Wallet account index.
            pending: Include pending transactions.
            pool: Include pool transactions.
            in_transfers: Include incoming transfers.
            out_transfers: Include outgoing transfers.

        Returns:
            list: List of transaction dicts.
        """
        result = self._wallet_rpc('get_transfers', {
            'account_index': account_index,
            'in': in_transfers,
            'out': out_transfers,
            'pending': pending,
            'pool': pool,
        })

        transactions = []
        for tx_type in ['in', 'out', 'pending', 'pool']:
            for tx in result.get(tx_type, []):
                transactions.append({
                    'tx_hash': tx.get('txid', ''),
                    'amount': tx.get('amount', 0) * 1e-12,
                    'fee': tx.get('fee', 0) * 1e-12,
                    'confirmations': tx.get('confirmations', 0),
                    'height': tx.get('height', 0),
                    'timestamp': tx.get('timestamp', 0),
                    'type': tx_type,
                    'address': tx.get('address', ''),
                })

        return sorted(transactions, key=lambda x: x['timestamp'], reverse=True)
