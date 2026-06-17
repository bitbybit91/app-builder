import hashlib
from datetime import datetime, timezone
from flask import Blueprint, request, jsonify, current_app
from app import db
from app.models.user import User
from app.services.encryption import (
    generate_mnemonic, validate_mnemonic, derive_keypair_from_mnemonic,
    generate_session_token, hash_session_token, verify_session_token, hash_mnemonic
)

auth_bp = Blueprint('auth', __name__)

def get_current_user():
    token = request.headers.get('X-Session-Token') or request.cookies.get('session_token')
    if not token:
        return None
    hmac_secret = current_app.config['HMAC_SECRET']
    token_hash = hash_session_token(token, hmac_secret)
    user = User.query.filter_by(session_token_hash=token_hash).first()
    if user:
        user.last_seen = datetime.now(timezone.utc)
        db.session.commit()
    return user

@auth_bp.route('/session', methods=['POST'])
def create_session():
    data = request.get_json() or {}
    public_key = data.get('public_key', '')
    display_name = data.get('display_name', 'Anonymous')
    if not public_key:
        return jsonify({'error': 'public_key required'}), 400
    existing = User.query.filter_by(public_key=public_key).first()
    if existing:
        token = generate_session_token()
        hmac_secret = current_app.config['HMAC_SECRET']
        token_hash = hash_session_token(token, hmac_secret)
        existing.session_token_hash = token_hash
        existing.last_seen = datetime.now(timezone.utc)
        db.session.commit()
        return jsonify({'token': token, 'user': existing.to_dict()})
    token = generate_session_token()
    hmac_secret = current_app.config['HMAC_SECRET']
    token_hash = hash_session_token(token, hmac_secret)
    user = User(
        session_token_hash=token_hash,
        public_key=public_key,
        display_name=display_name[:50] if display_name else 'Anonymous',
    )
    db.session.add(user)
    db.session.commit()
    return jsonify({'token': token, 'user': user.to_dict()}), 201

@auth_bp.route('/verify', methods=['GET'])
def verify_session():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Invalid or expired session'}), 401
    return jsonify({'valid': True, 'user': user.to_dict()})

@auth_bp.route('/mnemonic/generate', methods=['GET'])
def generate_mnemonic_route():
    words = generate_mnemonic()
    keypair = derive_keypair_from_mnemonic(words)
    return jsonify({
        'mnemonic': words,
        'public_key': keypair['public_key'],
        'public_key_hex': keypair['public_key_hex'],
    })

@auth_bp.route('/mnemonic/recover', methods=['POST'])
def recover_from_mnemonic():
    data = request.get_json() or {}
    mnemonic_phrase = data.get('mnemonic', '').strip()
    if not mnemonic_phrase:
        return jsonify({'error': 'mnemonic required'}), 400
    if not validate_mnemonic(mnemonic_phrase):
        return jsonify({'error': 'Invalid mnemonic phrase'}), 400
    keypair = derive_keypair_from_mnemonic(mnemonic_phrase)
    return jsonify({
        'public_key': keypair['public_key'],
        'public_key_hex': keypair['public_key_hex'],
    })

@auth_bp.route('/mnemonic/bind', methods=['POST'])
def bind_mnemonic():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    data = request.get_json() or {}
    mnemonic_phrase = data.get('mnemonic', '').strip()
    if not mnemonic_phrase:
        return jsonify({'error': 'mnemonic required'}), 400
    if not validate_mnemonic(mnemonic_phrase):
        return jsonify({'error': 'Invalid mnemonic phrase'}), 400
    keypair = derive_keypair_from_mnemonic(mnemonic_phrase)
    if keypair['public_key'] != user.public_key:
        return jsonify({'error': 'Mnemonic does not match your public key'}), 400
    mnemonic_h = hash_mnemonic(mnemonic_phrase)
    existing = User.query.filter_by(mnemonic_hash=mnemonic_h).first()
    if existing and existing.id != user.id:
        return jsonify({'error': 'Mnemonic already in use'}), 409
    user.mnemonic_hash = mnemonic_h
    db.session.commit()
    return jsonify({'success': True, 'message': 'Mnemonic bound to your account'})

@auth_bp.route('/logout', methods=['POST'])
def logout():
    user = get_current_user()
    if user:
        import secrets
        user.session_token_hash = secrets.token_hex(32)
        db.session.commit()
    return jsonify({'success': True})
