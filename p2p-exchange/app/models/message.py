"""
Message Model
==============
E2E encrypted trade chat messages.
Server stores only ciphertext — never plaintext.
"""

import uuid
from datetime import datetime, timezone

from app import db


class Message(db.Model):
    """An encrypted chat message within a trade."""

    __tablename__ = 'messages'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    trade_id = db.Column(db.String(36), db.ForeignKey('trades.id'), nullable=False, index=True)
    sender_id = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)

    # Encrypted payload (Base64-encoded NaCl box ciphertext)
    ciphertext = db.Column(db.Text, nullable=False)

    # Sender's ephemeral public key for this message (Base64)
    sender_ephemeral_pubkey = db.Column(db.String(64), nullable=False)

    # Nonce used for encryption (Base64)
    nonce = db.Column(db.String(48), nullable=False)

    # Timestamps — server records when it received the message
    created_at = db.Column(
        db.DateTime, default=lambda: datetime.now(timezone.utc), nullable=False,
    )

    # Relationships
    sender = db.relationship('User', backref='sent_messages')

    def __repr__(self):
        return f'<Message {self.id[:8]} in trade {self.trade_id[:8]}>'

    def to_dict(self):
        """Serialize to dictionary — ciphertext only, no plaintext ever."""
        return {
            'id': self.id,
            'trade_id': self.trade_id,
            'sender_id': self.sender_id,
            'sender_nickname': self.sender.nickname if self.sender else None,
            'ciphertext': self.ciphertext,
            'sender_ephemeral_pubkey': self.sender_ephemeral_pubkey,
            'nonce': self.nonce,
            'created_at': self.created_at.isoformat(),
        }
