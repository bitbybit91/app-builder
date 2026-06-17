from datetime import datetime, timezone
from app import db

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    session_token_hash = db.Column(db.String(256), unique=True, nullable=False, index=True)
    public_key = db.Column(db.String(64), unique=True, nullable=False)
    mnemonic_hash = db.Column(db.String(256), unique=True, nullable=True)
    display_name = db.Column(db.String(50), nullable=False, default='Anonymous')
    reputation_score = db.Column(db.Float, default=0.0)
    total_trades = db.Column(db.Integer, default=0)
    successful_trades = db.Column(db.Integer, default=0)
    disputed_trades = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    last_seen = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    is_active = db.Column(db.Boolean, default=True)

    # Relationships
    offers = db.relationship('Offer', foreign_keys='Offer.user_id', backref='owner', lazy='dynamic')
    sent_messages = db.relationship('Message', foreign_keys='Message.sender_id', backref='sender', lazy='dynamic')

    def to_dict(self):
        return {
            'id': self.id,
            'public_key': self.public_key,
            'display_name': self.display_name,
            'reputation_score': self.reputation_score,
            'total_trades': self.total_trades,
            'successful_trades': self.successful_trades,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_seen': self.last_seen.isoformat() if self.last_seen else None,
        }

    def trust_level(self):
        if self.successful_trades >= 100:
            return 'platinum'
        elif self.successful_trades >= 50:
            return 'gold'
        elif self.successful_trades >= 20:
            return 'silver'
        elif self.successful_trades >= 5:
            return 'bronze'
        return 'new'

    def __repr__(self):
        return f'<User {self.display_name}>'
