"""
Reputation Service
===================
Calculates and manages trader reputation scores.
"""

import logging
from app import db
from app.models.user import User

logger = logging.getLogger(__name__)


class ReputationService:
    """Manages trader reputation and trust scores."""

    # Trust level thresholds
    TRUST_LEVELS = [
        (90, 'Excellent'),
        (70, 'Good'),
        (50, 'Average'),
        (30, 'Low'),
        (0, 'Very Low'),
    ]

    @staticmethod
    def get_trust_level(score):
        """
        Get human-readable trust level from numeric score.

        Args:
            score: Trust score (0-100).

        Returns:
            str: Trust level label.
        """
        for threshold, label in ReputationService.TRUST_LEVELS:
            if score >= threshold:
                return label
        return 'Unknown'

    @staticmethod
    def calculate_trust_score(user):
        """
        Calculate trust score for a user.

        Args:
            user: User model instance.

        Returns:
            float: Trust score (0-100).
        """
        if user.trade_count == 0:
            return 0.0

        success_rate = user.successful_trades / user.trade_count
        volume_factor = min(user.trade_count / 100, 1.0)
        dispute_penalty = user.disputes_lost / user.trade_count

        score = (
            success_rate * 50
            + volume_factor * 30
            - dispute_penalty * 20
        )
        return round(max(0, min(100, score)), 1)

    @staticmethod
    def update_after_trade(buyer_id, seller_id, success=True):
        """
        Update reputation for both parties after a trade.

        Args:
            buyer_id: Buyer's user ID.
            seller_id: Seller's user ID.
            success: Whether the trade completed successfully.
        """
        buyer = User.query.get(buyer_id)
        seller = User.query.get(seller_id)

        for user in [buyer, seller]:
            if user:
                user.trade_count += 1
                if success:
                    user.successful_trades += 1
                user.trust_score = ReputationService.calculate_trust_score(user)

        db.session.commit()
        logger.info('Reputation updated for trade between %s and %s (success=%s)',
                     buyer_id[:8], seller_id[:8], success)

    @staticmethod
    def update_after_dispute(loser_id):
        """
        Penalize the dispute loser's reputation.

        Args:
            loser_id: User ID of the dispute loser.
        """
        loser = User.query.get(loser_id)
        if loser:
            loser.disputes_lost += 1
            loser.trust_score = ReputationService.calculate_trust_score(loser)
            db.session.commit()
            logger.info('Dispute penalty applied to user %s', loser_id[:8])

    @staticmethod
    def get_leaderboard(limit=50):
        """
        Get top traders by trust score.

        Args:
            limit: Number of results.

        Returns:
            list: List of user dicts sorted by trust score.
        """
        users = (
            User.query
            .filter(User.trade_count > 0)
            .order_by(User.trust_score.desc())
            .limit(limit)
            .all()
        )
        return [u.to_dict() for u in users]
