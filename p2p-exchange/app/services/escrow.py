"""
Escrow Service
===============
Non-custodial escrow logic for P2P trades.

The platform never holds private keys. Escrow works via:
1. Seller sends XMR to a dedicated subaddress (escrow address).
2. The platform monitors the escrow address for confirmations.
3. Upon trade completion, the platform transfers from escrow to buyer's address.
4. On dispute, an arbitrator decides fund release.
"""

import logging
from datetime import datetime, timezone

from app import db
from app.models.trade import Trade
from app.models.user import User

logger = logging.getLogger(__name__)


class EscrowService:
    """Manages the escrow lifecycle for trades."""

    def __init__(self, xmr_service, confirmations_required=10,
                 timeout_hours=24, bond_percent=5.0):
        """
        Initialize escrow service.

        Args:
            xmr_service: XMRService instance for blockchain operations.
            confirmations_required: Minimum confirmations before trade proceeds.
            timeout_hours: Auto-cancel timeout in hours.
            bond_percent: Arbitration bond as percentage of trade amount.
        """
        self.xmr = xmr_service
        self.confirmations_required = confirmations_required
        self.timeout_hours = timeout_hours
        self.bond_percent = bond_percent

    def create_escrow_address(self, trade):
        """
        Generate a unique escrow subaddress for a trade.

        Args:
            trade: Trade model instance.

        Returns:
            str: Escrow XMR address.
        """
        result = self.xmr.create_address(label=f'escrow-{trade.id}')
        address = result['address']

        trade.escrow_address = address
        db.session.commit()

        logger.info('Created escrow address for trade %s: %s...', trade.id[:8], address[:12])
        return address

    def check_escrow_funding(self, trade):
        """
        Check if the escrow address has been funded with the correct amount.

        Args:
            trade: Trade model instance.

        Returns:
            dict: {'funded': bool, 'confirmations': int, 'amount': float}
        """
        if not trade.escrow_tx_id:
            return {'funded': False, 'confirmations': 0, 'amount': 0}

        result = self.xmr.verify_payment(
            address=trade.escrow_address,
            tx_id=trade.escrow_tx_id,
            expected_amount_xmr=trade.crypto_amount,
            min_confirmations=self.confirmations_required,
        )

        if result['verified'] and trade.status == Trade.STATUS_INITIATED:
            trade.status = Trade.STATUS_ESCROW_FUNDED
            trade.escrow_funded_at = datetime.now(timezone.utc)
            trade.escrow_confirmations = result['confirmations']
            db.session.commit()
            logger.info('Escrow funded for trade %s', trade.id[:8])

        return {
            'funded': result['verified'],
            'confirmations': result['confirmations'],
            'amount': result['amount'],
        }

    def release_escrow(self, trade):
        """
        Release escrowed XMR to the buyer's wallet address.
        Called when seller confirms fiat receipt.

        Args:
            trade: Trade model instance.

        Returns:
            dict: {'success': bool, 'tx_hash': str}

        Raises:
            ValueError: If trade is not in correct state.
        """
        if trade.status not in (Trade.STATUS_FIAT_RECEIVED, Trade.STATUS_RESOLVED):
            raise ValueError(f'Cannot release escrow: trade is {trade.status}')

        if not trade.buyer_wallet_address:
            raise ValueError('Buyer wallet address not set')

        try:
            result = self.xmr.transfer(
                destinations=[{
                    'address': trade.buyer_wallet_address,
                    'amount': trade.crypto_amount,
                }],
            )

            trade.status = Trade.STATUS_COMPLETED
            trade.completed_at = datetime.now(timezone.utc)
            db.session.commit()

            # Update reputation
            self._update_reputation(trade, success=True)

            logger.info('Escrow released for trade %s, tx: %s',
                        trade.id[:8], result['tx_hash'][:16])
            return {'success': True, 'tx_hash': result['tx_hash']}

        except Exception as exc:
            logger.error('Escrow release failed for trade %s: %s', trade.id[:8], exc)
            return {'success': False, 'tx_hash': '', 'error': 'Transfer failed'}

    def refund_escrow(self, trade, refund_address):
        """
        Refund escrowed XMR back to the seller.
        Called on cancellation or dispute resolved in seller's favor.

        Args:
            trade: Trade model instance.
            refund_address: Seller's XMR address for refund.

        Returns:
            dict: {'success': bool, 'tx_hash': str}
        """
        try:
            result = self.xmr.transfer(
                destinations=[{
                    'address': refund_address,
                    'amount': trade.crypto_amount,
                }],
            )

            trade.status = Trade.STATUS_CANCELLED
            trade.cancelled_at = datetime.now(timezone.utc)
            db.session.commit()

            logger.info('Escrow refunded for trade %s, tx: %s',
                        trade.id[:8], result['tx_hash'][:16])
            return {'success': True, 'tx_hash': result['tx_hash']}

        except Exception as exc:
            logger.error('Escrow refund failed for trade %s: %s', trade.id[:8], exc)
            return {'success': False, 'tx_hash': '', 'error': 'Refund failed'}

    def open_dispute(self, trade, opened_by_user_id, reason):
        """
        Open a dispute on a trade.

        Args:
            trade: Trade model instance.
            opened_by_user_id: ID of the user opening the dispute.
            reason: Reason for the dispute.

        Returns:
            bool: True if dispute was opened.
        """
        if trade.status in (Trade.STATUS_COMPLETED, Trade.STATUS_CANCELLED, Trade.STATUS_RESOLVED):
            raise ValueError(f'Cannot dispute: trade is {trade.status}')

        trade.status = Trade.STATUS_DISPUTED
        trade.dispute_reason = reason
        trade.dispute_opened_by = opened_by_user_id
        trade.disputed_at = datetime.now(timezone.utc)
        db.session.commit()

        logger.info('Dispute opened for trade %s by user %s',
                     trade.id[:8], opened_by_user_id[:8])
        return True

    def resolve_dispute(self, trade, in_favor_of_user_id, resolution,
                        release_to_address):
        """
        Resolve a dispute — release funds to the winning party.

        Args:
            trade: Trade model instance.
            in_favor_of_user_id: User ID the dispute is resolved in favor of.
            resolution: Resolution description.
            release_to_address: XMR address to send funds to.

        Returns:
            dict: {'success': bool, 'tx_hash': str}
        """
        if trade.status != Trade.STATUS_DISPUTED:
            raise ValueError(f'Cannot resolve: trade is {trade.status}')

        trade.dispute_resolution = resolution
        trade.dispute_resolved_in_favor_of = in_favor_of_user_id
        trade.status = Trade.STATUS_RESOLVED

        # Release funds to winning party
        try:
            result = self.xmr.transfer(
                destinations=[{
                    'address': release_to_address,
                    'amount': trade.crypto_amount,
                }],
            )

            trade.completed_at = datetime.now(timezone.utc)
            db.session.commit()

            # Update reputation — loser gets penalized
            self._update_reputation(trade, success=False,
                                    dispute_loser_id=self._get_dispute_loser(trade))

            logger.info('Dispute resolved for trade %s in favor of %s',
                        trade.id[:8], in_favor_of_user_id[:8])
            return {'success': True, 'tx_hash': result['tx_hash']}

        except Exception as exc:
            logger.error('Dispute resolution transfer failed: %s', exc)
            return {'success': False, 'tx_hash': '', 'error': 'Resolution transfer failed'}

    def _get_dispute_loser(self, trade):
        """Get the user ID of the dispute loser."""
        winner = trade.dispute_resolved_in_favor_of
        if winner == trade.buyer_id:
            return trade.seller_id
        return trade.buyer_id

    def _update_reputation(self, trade, success=True, dispute_loser_id=None):
        """Update trader reputation after trade completion/dispute."""
        buyer = User.query.get(trade.buyer_id)
        seller = User.query.get(trade.seller_id)

        if buyer:
            buyer.trade_count += 1
            if success:
                buyer.successful_trades += 1
            buyer.trust_score = self._calculate_trust_score(buyer)

        if seller:
            seller.trade_count += 1
            if success:
                seller.successful_trades += 1
            seller.trust_score = self._calculate_trust_score(seller)

        if dispute_loser_id:
            loser = User.query.get(dispute_loser_id)
            if loser:
                loser.disputes_lost += 1
                loser.trust_score = self._calculate_trust_score(loser)

        db.session.commit()

    @staticmethod
    def _calculate_trust_score(user):
        """
        Calculate trust score (0-100) based on trade history.

        Factors:
          - Success rate (50% weight)
          - Trade volume (30% weight) — more trades = more trust
          - Dispute rate (20% weight, negative)
        """
        if user.trade_count == 0:
            return 0.0

        success_rate = user.successful_trades / user.trade_count
        # Cap trade volume factor at 100 trades
        volume_factor = min(user.trade_count / 100, 1.0)
        dispute_rate = user.disputes_lost / user.trade_count if user.trade_count > 0 else 0

        score = (
            success_rate * 50
            + volume_factor * 30
            - dispute_rate * 20
        )
        return round(max(0, min(100, score)), 1)
