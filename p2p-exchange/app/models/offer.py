from datetime import datetime, timezone
from app import db

class Offer(db.Model):
    __tablename__ = 'offers'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    type = db.Column(db.String(4), nullable=False)  # 'buy' or 'sell'
    crypto_currency = db.Column(db.String(10), nullable=False, default='XMR')
    fiat_currency = db.Column(db.String(10), nullable=False)
    payment_method = db.Column(db.String(100), nullable=False)
    price_type = db.Column(db.String(10), nullable=False, default='market')  # 'fixed' or 'market'
    price = db.Column(db.Float, nullable=True)
    margin_percent = db.Column(db.Float, nullable=True, default=0.0)
    min_amount = db.Column(db.Float, nullable=False)
    max_amount = db.Column(db.Float, nullable=False)
    terms = db.Column(db.Text, nullable=True)
    country = db.Column(db.String(100), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    trades = db.relationship('Trade', backref='offer', lazy='dynamic')

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'type': self.type,
            'crypto_currency': self.crypto_currency,
            'fiat_currency': self.fiat_currency,
            'payment_method': self.payment_method,
            'price_type': self.price_type,
            'price': self.price,
            'margin_percent': self.margin_percent,
            'min_amount': self.min_amount,
            'max_amount': self.max_amount,
            'terms': self.terms,
            'country': self.country,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'owner': self.owner.to_dict() if self.owner else None,
        }

    def __repr__(self):
        return f'<Offer {self.type} {self.crypto_currency}/{self.fiat_currency}>'
