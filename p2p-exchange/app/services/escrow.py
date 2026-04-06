import logging
from datetime import datetime, timezone, timedelta
from flask import current_app

logger = logging.getLogger(__name__)

class EscrowService:
    def __init__(self, xmr_client):
        self.xmr = xmr_client

    def create_escrow(self, trade_id, amount_xmr):
        try:
            result = self.xmr.create_subaddress(label=f'trade_{trade_id}')
            return {
                'address': result['address'],
                'address_index': result['address_index'],
                'required_amount': amount_xmr,
            }
        except Exception as e:
            logger.error(f"Failed to create escrow for trade {trade_id}: {e}")
            raise

    def verify_funding(self, escrow_address, required_amount_xmr, min_confirmations=10):
        try:
            transfers = self.xmr.get_transfers(in_=True, out=False, pending=True, pool=True)
            incoming = transfers.get('in', []) + transfers.get('pool', [])
            for tx in incoming:
                if tx.get('address') == escrow_address:
                    amount = tx.get('amount', 0) / 1e12
                    confirmations = tx.get('confirmations', 0)
                    if amount >= required_amount_xmr:
                        return {
                            'funded': True,
                            'txid': tx.get('txid', ''),
                            'amount': amount,
                            'confirmations': confirmations,
                            'confirmed': confirmations >= min_confirmations,
                        }
            return {'funded': False}
        except Exception as e:
            logger.error(f"Failed to verify escrow funding for {escrow_address}: {e}")
            return {'funded': False, 'error': str(e)}

    def release_funds(self, recipient_address, amount_xmr, fee_percent=0.5):
        try:
            fee_amount = amount_xmr * (fee_percent / 100)
            release_amount = amount_xmr - fee_amount
            amount_atomic = int(release_amount * 1e12)
            destinations = [{'amount': amount_atomic, 'address': recipient_address}]
            result = self.xmr.transfer(destinations)
            return {
                'success': True,
                'txid': result['tx_hash'],
                'amount_released': release_amount,
                'fee': result['fee'],
            }
        except Exception as e:
            logger.error(f"Failed to release funds to {recipient_address}: {e}")
            return {'success': False, 'error': str(e)}

    def refund(self, refund_address, amount_xmr):
        return self.release_funds(refund_address, amount_xmr, fee_percent=0.0)

    def is_timed_out(self, created_at, timeout_hours=24):
        if not created_at:
            return False
        now = datetime.now(timezone.utc)
        if created_at.tzinfo is None:
            created_at = created_at.replace(tzinfo=timezone.utc)
        elapsed = now - created_at
        return elapsed > timedelta(hours=timeout_hours)
