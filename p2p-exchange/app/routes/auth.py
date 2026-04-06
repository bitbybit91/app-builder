"""
Authentication Routes
======================
No-KYC auth: session tokens, mnemonic-derived identity, BitID.
No passwords, no emails, no phone numbers.
"""

import logging

from flask import Blueprint, request, jsonify, current_app
from app import db, limiter
from app.models.user import User
from app.services.encryption import (
    generate_session_token,
    hash_session_token,
    generate_mnemonic,
    mnemonic_to_keypair,
    generate_keypair,
)

logger = logging.getLogger(__name__)

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/session', methods=['POST'])
@limiter.limit('20/hour')
def create_session():
    """
    Create a new anonymous session.
    No registration required — generates a pseudonymous identity.

    Request body (optional):
        {"nickname": "optional-custom-name"}

    Returns:
        201: {"session_token": str, "user": {...}, "encryption_keypair": {...}}
    """
    data = request.get_json(silent=True) or {}
    nickname = data.get('nickname', '')

    # Generate random nickname if not provided
    if not nickname:
        import uuid
        nickname = f'anon-{uuid.uuid4().hex[:8]}'

    # Check nickname uniqueness
    existing = User.query.filter_by(nickname=nickname).first()
    if existing:
        return jsonify({'error': 'Nickname already taken'}), 409

    # Generate session token
    token = generate_session_token()
    hmac_key = current_app.config['SESSION_HMAC_KEY']
    token_hash = hash_session_token(token, hmac_key)

    # Generate encryption keypair for E2E chat
    keypair = generate_keypair()

    # Create user
    user = User(
        nickname=nickname,
        session_token_hash=token_hash,
    )
    db.session.add(user)
    db.session.commit()

    logger.info('New session created for user %s (%s)', nickname, user.id[:8])

    return jsonify({
        'session_token': token,
        'user': user.to_dict(),
        'encryption_keypair': keypair,
    }), 201


@auth_bp.route('/session/verify', methods=['POST'])
@limiter.limit('60/hour')
def verify_session():
    """
    Verify a session token.

    Request body:
        {"session_token": str}

    Returns:
        200: {"valid": true, "user": {...}}
        401: {"valid": false}
    """
    data = request.get_json(silent=True) or {}
    token = data.get('session_token', '')

    if not token:
        return jsonify({'valid': False, 'error': 'No token provided'}), 401

    hmac_key = current_app.config['SESSION_HMAC_KEY']
    token_hash = hash_session_token(token, hmac_key)

    user = User.query.filter_by(session_token_hash=token_hash).first()
    if not user:
        return jsonify({'valid': False}), 401

    return jsonify({'valid': True, 'user': user.to_dict()}), 200


@auth_bp.route('/mnemonic/generate', methods=['POST'])
@limiter.limit('10/hour')
def generate_mnemonic_identity():
    """
    Generate a 12-word BIP39 mnemonic for persistent identity.
    The mnemonic deterministically derives a keypair.

    Returns:
        201: {"mnemonic": str, "public_key": str, "encryption_keypair": {...}}
    """
    mnemonic = generate_mnemonic()
    keypair = mnemonic_to_keypair(mnemonic)

    return jsonify({
        'mnemonic': mnemonic,
        'public_key': keypair['public_key'],
        'encryption_keypair': keypair,
    }), 201


@auth_bp.route('/mnemonic/recover', methods=['POST'])
@limiter.limit('10/hour')
def recover_from_mnemonic():
    """
    Recover identity from a 12-word BIP39 mnemonic.

    Request body:
        {"mnemonic": str}

    Returns:
        200: {"user": {...}, "session_token": str, "encryption_keypair": {...}}
        404: {"error": "Identity not found"} if no user with that public key
    """
    data = request.get_json(silent=True) or {}
    mnemonic = data.get('mnemonic', '')

    if not mnemonic:
        return jsonify({'error': 'Mnemonic required'}), 400

    try:
        keypair = mnemonic_to_keypair(mnemonic)
    except ValueError as exc:
        return jsonify({'error': 'Invalid mnemonic phrase'}), 400
    user = User.query.filter_by(public_key=keypair['public_key']).first()
    if not user:
        return jsonify({'error': 'Identity not found. Create a new session first.'}), 404

    # Generate new session token
    token = generate_session_token()
    hmac_key = current_app.config['SESSION_HMAC_KEY']
    user.session_token_hash = hash_session_token(token, hmac_key)
    db.session.commit()

    return jsonify({
        'user': user.to_dict(),
        'session_token': token,
        'encryption_keypair': keypair,
    }), 200


@auth_bp.route('/mnemonic/bind', methods=['POST'])
@limiter.limit('10/hour')
def bind_mnemonic():
    """
    Bind a mnemonic-derived public key to an existing session.
    This upgrades an anonymous session to a persistent identity.

    Request body:
        {"session_token": str, "mnemonic": str}

    Returns:
        200: {"user": {...}}
    """
    data = request.get_json(silent=True) or {}
    token = data.get('session_token', '')
    mnemonic = data.get('mnemonic', '')

    if not token or not mnemonic:
        return jsonify({'error': 'session_token and mnemonic required'}), 400

    # Verify session
    hmac_key = current_app.config['SESSION_HMAC_KEY']
    token_hash = hash_session_token(token, hmac_key)
    user = User.query.filter_by(session_token_hash=token_hash).first()
    if not user:
        return jsonify({'error': 'Invalid session'}), 401

    try:
        keypair = mnemonic_to_keypair(mnemonic)
    except ValueError:
        return jsonify({'error': 'Invalid mnemonic phrase'}), 400
    existing = User.query.filter_by(public_key=keypair['public_key']).first()
    if existing and existing.id != user.id:
        return jsonify({'error': 'This mnemonic is already bound to another identity'}), 409

    user.public_key = keypair['public_key']
    db.session.commit()

    return jsonify({'user': user.to_dict()}), 200


def get_current_user():
    """
    Extract and validate the current user from the Authorization header.

    Returns:
        User or None
    """
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return None

    token = auth_header[7:]
    hmac_key = current_app.config['SESSION_HMAC_KEY']
    token_hash = hash_session_token(token, hmac_key)

    return User.query.filter_by(session_token_hash=token_hash).first()
