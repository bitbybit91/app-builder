import logging

logger = logging.getLogger(__name__)

TRUST_LEVELS = {
    'new': {'min_trades': 0, 'label': 'New', 'color': '#888'},
    'bronze': {'min_trades': 5, 'label': 'Bronze', 'color': '#cd7f32'},
    'silver': {'min_trades': 20, 'label': 'Silver', 'color': '#c0c0c0'},
    'gold': {'min_trades': 50, 'label': 'Gold', 'color': '#ffd700'},
    'platinum': {'min_trades': 100, 'label': 'Platinum', 'color': '#e5e4e2'},
}

class ReputationService:
    @staticmethod
    def calculate_score(user):
        if user.total_trades == 0:
            return 0.0
        success_rate = user.successful_trades / user.total_trades
        dispute_penalty = (user.disputed_trades / user.total_trades) * 0.5 if user.total_trades > 0 else 0
        volume_bonus = min(user.successful_trades / 100, 0.2)
        score = (success_rate - dispute_penalty + volume_bonus) * 100
        return max(0.0, min(100.0, round(score, 2)))

    @staticmethod
    def get_trust_level(user):
        trades = user.successful_trades
        if trades >= TRUST_LEVELS['platinum']['min_trades']:
            return 'platinum'
        elif trades >= TRUST_LEVELS['gold']['min_trades']:
            return 'gold'
        elif trades >= TRUST_LEVELS['silver']['min_trades']:
            return 'silver'
        elif trades >= TRUST_LEVELS['bronze']['min_trades']:
            return 'bronze'
        return 'new'

    @staticmethod
    def get_trust_level_info(level):
        return TRUST_LEVELS.get(level, TRUST_LEVELS['new'])

    @staticmethod
    def update_reputation(user, trade_successful, was_disputed=False):
        if trade_successful:
            user.successful_trades += 1
        if was_disputed:
            user.disputed_trades += 1
        user.total_trades += 1
        user.reputation_score = ReputationService.calculate_score(user)
        return user
