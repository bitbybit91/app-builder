"""
E2E Encryption Service
=======================
Implements X25519 key exchange and XChaCha20-Poly1305 encryption
using PyNaCl (libsodium bindings).

The server NEVER sees plaintext — all encryption/decryption happens client-side.
This module provides server-side utilities for:
  - Generating ephemeral keypairs for trade sessions
  - Verifying message structure (but NOT decrypting)
  - Key derivation from BIP39 mnemonics for persistent identity
"""

import base64
import hashlib
import hmac
import logging
import secrets

from nacl.public import PrivateKey, PublicKey, Box
from nacl.utils import random as nacl_random
from nacl.encoding import Base64Encoder
from mnemonic import Mnemonic

logger = logging.getLogger(__name__)


def generate_keypair():
    """
    Generate an X25519 keypair for E2E encryption.

    Returns:
        dict: {'private_key': base64, 'public_key': base64}
    """
    private_key = PrivateKey.generate()
    public_key = private_key.public_key

    return {
        'private_key': base64.b64encode(bytes(private_key)).decode('ascii'),
        'public_key': base64.b64encode(bytes(public_key)).decode('ascii'),
    }


def generate_mnemonic():
    """
    Generate a 12-word BIP39 mnemonic for persistent identity.

    Returns:
        str: 12-word mnemonic phrase.
    """
    m = Mnemonic('english')
    return m.generate(strength=128)  # 128 bits = 12 words


def mnemonic_to_keypair(mnemonic_phrase):
    """
    Derive an X25519 keypair from a BIP39 mnemonic.

    Uses HMAC-SHA256 of the mnemonic seed as the private key material.

    Args:
        mnemonic_phrase: 12-word BIP39 mnemonic.

    Returns:
        dict: {'private_key': base64, 'public_key': base64}

    Raises:
        ValueError: If the mnemonic is invalid.
    """
    m = Mnemonic('english')
    if not m.check(mnemonic_phrase):
        raise ValueError('Invalid mnemonic phrase')

    # Derive seed from mnemonic
    seed = m.to_seed(mnemonic_phrase, passphrase='p2p-exchange-identity')

    # Use first 32 bytes of HMAC-SHA256(seed) as private key material
    key_material = hmac.new(
        b'p2p-exchange-x25519',
        seed,
        hashlib.sha256,
    ).digest()

    private_key = PrivateKey(key_material)
    public_key = private_key.public_key

    return {
        'private_key': base64.b64encode(bytes(private_key)).decode('ascii'),
        'public_key': base64.b64encode(bytes(public_key)).decode('ascii'),
    }


def validate_message_structure(ciphertext_b64, nonce_b64, sender_pubkey_b64):
    """
    Validate that an encrypted message has the correct structure.
    Does NOT decrypt — server cannot decrypt E2E messages.

    Args:
        ciphertext_b64: Base64-encoded ciphertext.
        nonce_b64: Base64-encoded nonce.
        sender_pubkey_b64: Base64-encoded sender ephemeral public key.

    Returns:
        bool: True if structure is valid.

    Raises:
        ValueError: If structure is invalid.
    """
    try:
        ciphertext = base64.b64decode(ciphertext_b64)
        nonce = base64.b64decode(nonce_b64)
        sender_pubkey = base64.b64decode(sender_pubkey_b64)
    except Exception as exc:
        raise ValueError(f'Invalid Base64 encoding: {exc}') from exc

    if len(nonce) != 24:
        raise ValueError(f'Nonce must be 24 bytes, got {len(nonce)}')

    if len(sender_pubkey) != 32:
        raise ValueError(f'Public key must be 32 bytes, got {len(sender_pubkey)}')

    if len(ciphertext) < 16:
        raise ValueError('Ciphertext too short (must include auth tag)')

    return True


def generate_session_token():
    """
    Generate a cryptographically secure session token.

    Returns:
        str: 64-character hex token.
    """
    return secrets.token_hex(32)


def hash_session_token(token, hmac_key):
    """
    HMAC-SHA256 hash a session token for storage.

    Args:
        token: Raw session token string.
        hmac_key: HMAC key string.

    Returns:
        str: Hex-encoded HMAC hash.
    """
    return hmac.new(
        hmac_key.encode('utf-8'),
        token.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()
