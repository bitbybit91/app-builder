"""
Tests for Reputation Service
==============================
"""

import pytest
from app.services.reputation import ReputationService
from app.models.user import User
from app import db as _db


class TestTrustScore:
    """Test trust score calculation."""

    def test_new_user_score_zero(self):
        user = User(nickname='newuser', trade_count=0, successful_trades=0,
                     disputes_opened=0, disputes_lost=0)
        score = ReputationService.calculate_trust_score(user)
        assert score == 0.0

    def test_perfect_trader(self):
        user = User(nickname='perfect', trade_count=100, successful_trades=100,
                     disputes_opened=0, disputes_lost=0)
        score = ReputationService.calculate_trust_score(user)
        assert score == 80.0  # 50 (100% success) + 30 (100 trades)

    def test_dispute_penalty(self):
        user = User(nickname='disputed', trade_count=10, successful_trades=8,
                     disputes_opened=2, disputes_lost=2)
        score = ReputationService.calculate_trust_score(user)
        # 40 (80% success) + 3 (10/100 volume) - 4 (20% disputes)
        assert score == 39.0

    def test_score_capped_at_100(self):
        user = User(nickname='cap', trade_count=200, successful_trades=200,
                     disputes_opened=0, disputes_lost=0)
        score = ReputationService.calculate_trust_score(user)
        assert score <= 100

    def test_score_minimum_zero(self):
        user = User(nickname='bad', trade_count=10, successful_trades=0,
                     disputes_opened=10, disputes_lost=10)
        score = ReputationService.calculate_trust_score(user)
        assert score >= 0


class TestTrustLevels:
    """Test trust level labels."""

    def test_trust_levels(self):
        assert ReputationService.get_trust_level(95) == 'Excellent'
        assert ReputationService.get_trust_level(75) == 'Good'
        assert ReputationService.get_trust_level(55) == 'Average'
        assert ReputationService.get_trust_level(35) == 'Low'
        assert ReputationService.get_trust_level(10) == 'Very Low'


class TestUserModel:
    """Test User model properties."""

    def test_success_rate_no_trades(self):
        user = User(nickname='new', trade_count=0)
        assert user.success_rate == 0.0

    def test_success_rate_with_trades(self):
        user = User(nickname='active', trade_count=10, successful_trades=8)
        assert user.success_rate == 80.0

    def test_trust_level_property(self):
        user = User(nickname='trusted', trade_count=50, trust_score=85)
        assert user.trust_level == 'Good'

    def test_to_dict(self):
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        user = User(
            nickname='testdict', trade_count=5, successful_trades=4,
            trust_score=70, created_at=now, last_seen_at=now,
        )
        d = user.to_dict()
        assert d['nickname'] == 'testdict'
        assert d['trade_count'] == 5
        assert d['trust_level'] == 'Good'
        assert 'id' in d
