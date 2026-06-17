from datetime import datetime, timezone
from app import db

class TradeStatus:
    INITIATED = 'initiated'
    ESCROW_FUNDED = 'escrow_funded'
    FIAT_SENT = 'fiat_sent'
    FIAT_RECEIVED = 'fiat_received'
    COMPLETED = 'completed'
    CANCELLED = 'cancelled'
    DISPUTED = 'disputed'

    ALL = [INITIATED, ESCROW_FUNDED, FIAT_SENT, FIAT_RECEIVED, COMPLETED, CANCELLED, DISPUTED]

class Trade(db.Model):
    __tablename__ = 'trades'

    id = db.Column(db.Integer, primary_key=True)
    offer_id = db.Column(db.Integer, db.ForeignKey('offers.id'), nullable=False)
    buyer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    seller_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    amount_xmr = db.Column(db.Float, nullable=False)
    amount_fiat = db.Column(db.Float, nullable=False)
    fiat_currency = db.Column(db.String(10), nullable=False)
    status = db.Column(db.String(20), nullable=False, default=TradeStatus.INITIATED)
    escrow_address = db.Column(db.String(256), nullable=True)
    escrow_txid = db.Column(db.String(256), nullable=True)
    release_txid = db.Column(db.String(256), nullable=True)
    dispute_reason = db.Column(db.Text, nullable=True)
    dispute_winner_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    completed_at = db.Column(db.DateTime, nullable=True)

    buyer = db.relationship('User', foreign_keys=[buyer_id], backref='purchases')
    seller = db.relationship('User', foreign_keys=[seller_id], backref='sales')
    dispute_winner = db.relationship('User', foreign_keys=[dispute_winner_id])
    messages = db.relationship('Message', backref='trade', lazy='dynamic', order_by='Message.created_at')

    def to_dict(self):
        return {
            'id': self.id,
            'offer_id': self.offer_id,
            'buyer_id': self.buyer_id,
            'seller_id': self.seller_id,
            'amount_xmr': self.amount_xmr,
            'amount_fiat': self.amount_fiat,
            'fiat_currency': self.fiat_currency,
            'status': self.status,
            'escrow_address': self.escrow_address,
            'escrow_txid': self.escrow_txid,
            'dispute_reason': self.dispute_reason,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
        }

    def can_transition_to(self, new_status):
        transitions = {
            TradeStatus.INITIATED: [TradeStatus.ESCROW_FUNDED, TradeStatus.CANCELLED],
            TradeStatus.ESCROW_FUNDED: [TradeStatus.FIAT_SENT, TradeStatus.CANCELLED, TradeStatus.DISPUTED],
            TradeStatus.FIAT_SENT: [TradeStatus.FIAT_RECEIVED, TradeStatus.DISPUTED],
            TradeStatus.FIAT_RECEIVED: [TradeStatus.COMPLETED],
            TradeStatus.COMPLETED: [],
            TradeStatus.CANCELLED: [],
            TradeStatus.DISPUTED: [TradeStatus.COMPLETED, TradeStatus.CANCELLED],
        }
        return new_status in transitions.get(self.status, [])

    def __repr__(self):
        return f'<Trade {self.id} {self.status}>'
