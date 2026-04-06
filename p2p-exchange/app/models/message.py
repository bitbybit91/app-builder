from datetime import datetime, timezone
from app import db

class Message(db.Model):
    __tablename__ = 'messages'

    id = db.Column(db.Integer, primary_key=True)
    trade_id = db.Column(db.Integer, db.ForeignKey('trades.id'), nullable=False)
    sender_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    encrypted_content = db.Column(db.Text, nullable=False)
    nonce = db.Column(db.String(256), nullable=False)
    ephemeral_public_key = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'trade_id': self.trade_id,
            'sender_id': self.sender_id,
            'encrypted_content': self.encrypted_content,
            'nonce': self.nonce,
            'ephemeral_public_key': self.ephemeral_public_key,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<Message {self.id} trade={self.trade_id}>'
