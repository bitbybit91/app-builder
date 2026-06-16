"""
Trade Model
============
Active trades between buyer and seller, including escrow state.
"""

import uuid
from datetime import datetime, timezone

from app import db


class Trade(db.Model):
    """A trade initiated from an offer."""

    __tablename__ = 'trades'

    # Trade states
    STATUS_INITIATED = 'initiated'
    STATUS_ESCROW_FUNDED = 'escrow_funded'
    STATUS_FIAT_SENT = 'fiat_sent'
    STATUS_FIAT_RECEIVED = 'fiat_received'
    STATUS_COMPLETED = 'completed'
    STATUS_CANCELLED = 'cancelled'
    STATUS_DISPUTED = 'disputed'
    STATUS_RESOLVED = 'resolved'

    VALID_STATUSES = [
        STATUS_INITIATED, STATUS_ESCROW_FUNDED, STATUS_FIAT_SENT,
        STATUS_FIAT_RECEIVED, STATUS_COMPLETED, STATUS_CANCELLED,
        STATUS_DISPUTED, STATUS_RESOLVED,
    ]

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    offer_id = db.Column(db.String(36), db.ForeignKey('offers.id'), nullable=False, index=True)

    # Participants
    buyer_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False, index=True)
    seller_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False, index=True)

    # Trade details
    crypto_amount = db.Column(db.Float, nullable=False)  # XMR amount
    fiat_amount = db.Column(db.Float, nullable=False)
    fiat_currency = db.Column(db.String(8), nullable=False)
    payment_method = db.Column(db.String(64), nullable=False)

    # Escrow
    escrow_address = db.Column(db.String(128), nullable=True)
    escrow_tx_id = db.Column(db.String(128), nullable=True)
    escrow_confirmations = db.Column(db.Integer, default=0, nullable=False)
    buyer_wallet_address = db.Column(db.String(128), nullable=True)

    # Bond
    bond_amount = db.Column(db.Float, default=0.0, nullable=False)
    bond_tx_id = db.Column(db.String(128), nullable=True)

    # Status
    status = db.Column(db.String(20), default=STATUS_INITIATED, nullable=False, index=True)

    # Dispute
    dispute_reason = db.Column(db.Text, nullable=True)
    dispute_opened_by = db.Column(db.String(36), nullable=True)
    dispute_resolution = db.Column(db.Text, nullable=True)
    dispute_resolved_in_favor_of = db.Column(db.String(36), nullable=True)

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
    escrow_funded_at = db.Column(db.DateTime, nullable=True)
    fiat_sent_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    cancelled_at = db.Column(db.DateTime, nullable=True)
    disputed_at = db.Column(db.DateTime, nullable=True)

    # Relationships
    buyer = db.relationship('User', foreign_keys=[buyer_id], backref='trades_as_buyer')
    seller = db.relationship('User', foreign_keys=[seller_id], backref='trades_as_seller')
    messages = db.relationship('Message', backref='trade', lazy='dynamic', order_by='Message.created_at')

    def __repr__(self):
        return f'<Trade {self.id[:8]} {self.status}>'

    def to_dict(self, include_escrow=False):
        """Serialize to dictionary."""
        data = {
            'id': self.id,
            'offer_id': self.offer_id,
            'buyer_id': self.buyer_id,
            'seller_id': self.seller_id,
            'buyer_nickname': self.buyer.nickname if self.buyer else None,
            'seller_nickname': self.seller.nickname if self.seller else None,
            'crypto_amount': self.crypto_amount,
            'fiat_amount': self.fiat_amount,
            'fiat_currency': self.fiat_currency,
            'payment_method': self.payment_method,
            'status': self.status,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'escrow_funded_at': self.escrow_funded_at.isoformat() if self.escrow_funded_at else None,
            'fiat_sent_at': self.fiat_sent_at.isoformat() if self.fiat_sent_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
        }
        if include_escrow:
            data.update({
                'escrow_address': self.escrow_address,
                'escrow_tx_id': self.escrow_tx_id,
                'escrow_confirmations': self.escrow_confirmations,
                'buyer_wallet_address': self.buyer_wallet_address,
                'bond_amount': self.bond_amount,
            })
        return data
