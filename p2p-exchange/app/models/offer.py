"""
Offer Model
============
Buy/sell offers for XMR trading.
"""

import uuid
from datetime import datetime, timezone

from app import db


class Offer(db.Model):
    """A buy or sell offer posted by a trader."""

    __tablename__ = 'offers'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False, index=True)

    # Offer type: 'buy' or 'sell'
    offer_type = db.Column(db.String(4), nullable=False, index=True)

    # Cryptocurrency (always XMR for now)
    crypto_currency = db.Column(db.String(8), default='XMR', nullable=False)

    # Fiat currency code (USD, EUR, GBP, etc.)
    fiat_currency = db.Column(db.String(8), nullable=False, index=True)

    # Price: percentage above/below market rate, or fixed price
    price_type = db.Column(db.String(16), default='market', nullable=False)  # 'market' or 'fixed'
    price_margin = db.Column(db.Float, default=0.0, nullable=False)  # % above/below market
    fixed_price = db.Column(db.Float, nullable=True)  # fixed fiat price per XMR

    # Amount range (in fiat)
    min_amount = db.Column(db.Float, nullable=False)
    max_amount = db.Column(db.Float, nullable=False)

    # Payment method
    payment_method = db.Column(db.String(64), nullable=False, index=True)
    payment_details = db.Column(db.Text, nullable=True)

    # Terms and conditions
    terms = db.Column(db.Text, nullable=True)

    # Trade window (minutes)
    trade_time_limit = db.Column(db.Integer, default=60, nullable=False)

    # Location (optional — for local trades)
    country = db.Column(db.String(4), nullable=True, index=True)
    location = db.Column(db.String(128), nullable=True)
    trade_type = db.Column(db.String(8), default='online', nullable=False)  # 'online' or 'local'

    # Status
    is_active = db.Column(db.Boolean, default=True, nullable=False, index=True)

    # Timestamps
    created_at = db.Column(
        db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False,
    )
    updated_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    trades = db.relationship('Trade', backref='offer', lazy='dynamic')

    def __repr__(self):
        return f'<Offer {self.offer_type} {self.crypto_currency}/{self.fiat_currency}>'

    def to_dict(self):
        """Serialize to dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_nickname': self.user.nickname if self.user else None,
            'user_trust_score': self.user.trust_score if self.user else None,
            'user_trade_count': self.user.trade_count if self.user else 0,
            'offer_type': self.offer_type,
            'crypto_currency': self.crypto_currency,
            'fiat_currency': self.fiat_currency,
            'price_type': self.price_type,
            'price_margin': self.price_margin,
            'fixed_price': self.fixed_price,
            'min_amount': self.min_amount,
            'max_amount': self.max_amount,
            'payment_method': self.payment_method,
            'payment_details': self.payment_details,
            'terms': self.terms,
            'trade_time_limit': self.trade_time_limit,
            'country': self.country,
            'location': self.location,
            'trade_type': self.trade_type,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
        }
