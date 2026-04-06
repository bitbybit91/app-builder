import random
import logging
import requests
from requests.auth import HTTPDigestAuth

logger = logging.getLogger(__name__)

class MoneroRPCError(Exception):
    pass

class MoneroRPCClient:
    def __init__(self, endpoints, username='', password=''):
        if isinstance(endpoints, str):
            self.endpoints = [endpoints]
        else:
            self.endpoints = list(endpoints)
        self.username = username
        self.password = password
        self.timeout = 30

    def _get_endpoint(self):
        return random.choice(self.endpoints)

    def _rpc_call(self, method, params=None):
        payload = {
            'jsonrpc': '2.0',
            'id': '0',
            'method': method,
            'params': params or {},
        }
        last_error = None
        endpoints = self.endpoints.copy()
        random.shuffle(endpoints)
        for endpoint in endpoints:
            try:
                auth = HTTPDigestAuth(self.username, self.password) if self.username else None
                response = requests.post(
                    endpoint,
                    json=payload,
                    auth=auth,
                    timeout=self.timeout
                )
                response.raise_for_status()
                result = response.json()
                if 'error' in result:
                    raise MoneroRPCError(f"RPC error: {result['error']}")
                return result.get('result', {})
            except requests.RequestException as e:
                last_error = e
                logger.warning(f"RPC endpoint {endpoint} failed: {e}")
                continue
        raise MoneroRPCError(f"All endpoints failed. Last error: {last_error}")

    def get_balance(self, account_index=0):
        result = self._rpc_call('get_balance', {'account_index': account_index})
        return {
            'balance': result.get('balance', 0) / 1e12,
            'unlocked_balance': result.get('unlocked_balance', 0) / 1e12,
        }

    def create_subaddress(self, account_index=0, label=''):
        result = self._rpc_call('create_address', {
            'account_index': account_index,
            'label': label,
        })
        return {
            'address': result.get('address', ''),
            'address_index': result.get('address_index', 0),
        }

    def transfer(self, destinations, account_index=0, priority=1):
        params = {
            'destinations': destinations,
            'account_index': account_index,
            'priority': priority,
            'get_tx_key': True,
        }
        result = self._rpc_call('transfer', params)
        return {
            'tx_hash': result.get('tx_hash', ''),
            'tx_key': result.get('tx_key', ''),
            'amount': result.get('amount', 0) / 1e12,
            'fee': result.get('fee', 0) / 1e12,
        }

    def get_transfers(self, account_index=0, in_=True, out=True, pending=True, pool=True):
        result = self._rpc_call('get_transfers', {
            'account_index': account_index,
            'in': in_,
            'out': out,
            'pending': pending,
            'pool': pool,
        })
        return result

    def get_block_count(self):
        result = self._rpc_call('get_height')
        return result.get('height', 0)

    def check_tx(self, txid, tx_key, address):
        result = self._rpc_call('check_tx_key', {
            'txid': txid,
            'tx_key': tx_key,
            'address': address,
        })
        return {
            'received': result.get('received', 0) / 1e12,
            'in_pool': result.get('in_pool', False),
            'confirmations': result.get('confirmations', 0),
        }

    def get_address(self, account_index=0):
        result = self._rpc_call('get_address', {'account_index': account_index})
        return result.get('address', '')
