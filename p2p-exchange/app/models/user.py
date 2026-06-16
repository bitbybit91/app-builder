"""
User Model
==========
Pseudonymous user identity — no email, no phone, no KYC.
Identity can be ephemeral (session-based) or persistent (mnemonic-derived keypair).
"""

import uuid
from datetime import datetime, timezone

from app import db


class User(db.Model):
    """Pseudonymous user account."""

    __tablename__ = 'users'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nickname = db.Column(db.String(64), unique=True, nullable=False, index=True)

    # Persistent identity (optional) — derived from BIP39 mnemonic
    public_key = db.Column(db.String(64), unique=True, nullable=True, index=True)

    # Session token hash (HMAC-SHA256)
    session_token_hash = db.Column(db.String(128), nullable=True)

    # Reputation
    trade_count = db.Column(db.Integer, default=0, nullable=False)
    successful_trades = db.Column(db.Integer, default=0, nullable=False)
    disputes_opened = db.Column(db.Integer, default=0, nullable=False)
    disputes_lost = db.Column(db.Integer, default=0, nullable=False)
    avg_response_time_seconds = db.Column(db.Float, default=0.0, nullable=False)
    trust_score = db.Column(db.Float, default=0.0, nullable=False)

    # Profile
    bio = db.Column(db.Text, nullable=True)
    location = db.Column(db.String(128), nullable=True)
    preferred_currency = db.Column(db.String(16), nullable=True)

    # Timestamps
    created_at = db.Column(
        db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False,
    )
    last_seen_at = db.Column(
        db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False,
    )

    # Relationships
    offers = db.relationship('Offer', backref='user', lazy='dynamic')

    def __repr__(self):
        return f'<User {self.nickname}>'

    @property
    def success_rate(self):
        """Percentage of successful trades."""
        if self.trade_count == 0:
            return 0.0
        return round((self.successful_trades / self.trade_count) * 100, 1)

    @property
    def trust_level(self):
        """Human-readable trust level based on trust_score."""
        if self.trade_count == 0:
            return 'New'
        if self.trust_score >= 90:
            return 'Excellent'
        if self.trust_score >= 70:
            return 'Good'
        if self.trust_score >= 50:
            return 'Average'
        if self.trust_score >= 30:
            return 'Low'
        return 'Very Low'

    def to_dict(self):
        """Serialize to dictionary (public profile)."""
        return {
            'id': self.id,
            'nickname': self.nickname,
            'trade_count': self.trade_count,
            'successful_trades': self.successful_trades,
            'success_rate': self.success_rate,
            'trust_score': self.trust_score,
            'trust_level': self.trust_level,
            'avg_response_time_seconds': self.avg_response_time_seconds,
            'bio': self.bio,
            'location': self.location,
            'created_at': self.created_at.isoformat(),
            'last_seen_at': self.last_seen_at.isoformat(),
        }
