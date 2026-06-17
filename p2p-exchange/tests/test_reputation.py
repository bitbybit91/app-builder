import pytest
from app.services.reputation import ReputationService, TRUST_LEVELS
from unittest.mock import MagicMock

def make_user(total=0, successful=0, disputed=0, score=0.0):
    user = MagicMock()
    user.total_trades = total
    user.successful_trades = successful
    user.disputed_trades = disputed
    user.reputation_score = score
    return user

def test_score_new_user():
    user = make_user()
    assert ReputationService.calculate_score(user) == 0.0

def test_score_all_successful():
    user = make_user(total=10, successful=10, disputed=0)
    score = ReputationService.calculate_score(user)
    assert score > 90.0

def test_score_with_disputes():
    user = make_user(total=10, successful=8, disputed=2)
    score = ReputationService.calculate_score(user)
    assert score < 80.0

def test_trust_level_new():
    user = make_user(successful=0)
    assert ReputationService.get_trust_level(user) == 'new'

def test_trust_level_bronze():
    user = make_user(successful=5)
    assert ReputationService.get_trust_level(user) == 'bronze'

def test_trust_level_silver():
    user = make_user(successful=20)
    assert ReputationService.get_trust_level(user) == 'silver'

def test_trust_level_gold():
    user = make_user(successful=50)
    assert ReputationService.get_trust_level(user) == 'gold'

def test_trust_level_platinum():
    user = make_user(successful=100)
    assert ReputationService.get_trust_level(user) == 'platinum'

def test_trust_level_info():
    info = ReputationService.get_trust_level_info('gold')
    assert info['min_trades'] == 50
    assert 'label' in info
    assert 'color' in info

def test_update_reputation_successful():
    user = make_user(total=5, successful=4, disputed=0, score=80.0)
    updated = ReputationService.update_reputation(user, True, False)
    assert updated.successful_trades == 5
    assert updated.total_trades == 6

def test_update_reputation_disputed():
    user = make_user(total=5, successful=4, disputed=0, score=80.0)
    updated = ReputationService.update_reputation(user, False, True)
    assert updated.disputed_trades == 1
    assert updated.total_trades == 6
