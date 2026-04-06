import requests
import logging

logger = logging.getLogger(__name__)


class MoneroRPCError(Exception):
    pass


class MoneroWalletRPC:
    def __init__(self, url='http://127.0.0.1:18082/json_rpc', username='', password=''):
        self.url = url
        self.username = username
        self.password = password
        self._id = 0

    def _call(self, method, params=None):
        self._id += 1
        payload = {
            'jsonrpc': '2.0',
            'id': str(self._id),
            'method': method,
            'params': params or {},
        }
        try:
            auth = None
            if self.username:
                auth = (self.username, self.password)
            resp = requests.post(self.url, json=payload, auth=auth, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            if 'error' in data:
                raise MoneroRPCError(f"RPC error: {data['error']}")
            return data.get('result', {})
        except requests.RequestException as e:
            logger.error(f"Monero RPC connection error: {e}")
            raise MoneroRPCError(f"Connection error: {e}")

    def create_account(self, label=''):
        result = self._call('create_account', {'label': label})
        return {
            'account_index': result.get('account_index', 0),
            'address': result.get('address', ''),
        }

    def get_balance(self, account_index=0):
        result = self._call('get_balance', {'account_index': account_index})
        return {
            'balance': result.get('balance', 0),
            'unlocked_balance': result.get('unlocked_balance', 0),
        }

    def get_address(self, account_index=0):
        result = self._call('get_address', {'account_index': account_index})
        addresses = result.get('addresses', [])
        if addresses:
            return addresses[0].get('address', '')
        return result.get('address', '')

    def transfer(self, amount_xmr, address, account_index=0, priority=1):
        amount_atomic = int(amount_xmr * 1e12)
        params = {
            'destinations': [{'amount': amount_atomic, 'address': address}],
            'account_index': account_index,
            'priority': priority,
            'get_tx_key': True,
        }
        result = self._call('transfer', params)
        return {
            'tx_hash': result.get('tx_hash', ''),
            'tx_key': result.get('tx_key', ''),
            'fee': result.get('fee', 0),
            'amount': result.get('amount', 0),
        }
