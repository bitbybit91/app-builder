"""
Tests for E2E Encryption Service
==================================
"""

import base64
import pytest

from app.services.encryption import (
    generate_keypair,
    generate_mnemonic,
    mnemonic_to_keypair,
    validate_message_structure,
    generate_session_token,
    hash_session_token,
)


class TestKeypairGeneration:
    """Test X25519 keypair generation."""

    def test_generate_keypair_returns_keys(self):
        keypair = generate_keypair()
        assert 'private_key' in keypair
        assert 'public_key' in keypair

    def test_keypair_keys_are_base64(self):
        keypair = generate_keypair()
        # Should be valid Base64
        priv = base64.b64decode(keypair['private_key'])
        pub = base64.b64decode(keypair['public_key'])
        assert len(priv) == 32
        assert len(pub) == 32

    def test_different_keypairs_are_unique(self):
        k1 = generate_keypair()
        k2 = generate_keypair()
        assert k1['public_key'] != k2['public_key']
        assert k1['private_key'] != k2['private_key']


class TestMnemonic:
    """Test BIP39 mnemonic generation and key derivation."""

    def test_generate_mnemonic_returns_12_words(self):
        mnemonic = generate_mnemonic()
        words = mnemonic.split()
        assert len(words) == 12

    def test_mnemonic_to_keypair(self):
        mnemonic = generate_mnemonic()
        keypair = mnemonic_to_keypair(mnemonic)
        assert 'private_key' in keypair
        assert 'public_key' in keypair

    def test_same_mnemonic_gives_same_keypair(self):
        mnemonic = generate_mnemonic()
        k1 = mnemonic_to_keypair(mnemonic)
        k2 = mnemonic_to_keypair(mnemonic)
        assert k1['public_key'] == k2['public_key']
        assert k1['private_key'] == k2['private_key']

    def test_different_mnemonics_give_different_keypairs(self):
        m1 = generate_mnemonic()
        m2 = generate_mnemonic()
        k1 = mnemonic_to_keypair(m1)
        k2 = mnemonic_to_keypair(m2)
        assert k1['public_key'] != k2['public_key']

    def test_invalid_mnemonic_raises(self):
        with pytest.raises(ValueError, match='Invalid mnemonic'):
            mnemonic_to_keypair('invalid words that are not a real mnemonic phrase at all here')


class TestMessageValidation:
    """Test encrypted message structure validation."""

    def test_valid_message_structure(self):
        ciphertext = base64.b64encode(b'x' * 32).decode()
        nonce = base64.b64encode(b'x' * 24).decode()
        pubkey = base64.b64encode(b'x' * 32).decode()
        assert validate_message_structure(ciphertext, nonce, pubkey) is True

    def test_invalid_nonce_length(self):
        ciphertext = base64.b64encode(b'x' * 32).decode()
        nonce = base64.b64encode(b'x' * 16).decode()  # Wrong length
        pubkey = base64.b64encode(b'x' * 32).decode()
        with pytest.raises(ValueError, match='Nonce must be 24 bytes'):
            validate_message_structure(ciphertext, nonce, pubkey)

    def test_invalid_pubkey_length(self):
        ciphertext = base64.b64encode(b'x' * 32).decode()
        nonce = base64.b64encode(b'x' * 24).decode()
        pubkey = base64.b64encode(b'x' * 16).decode()  # Wrong length
        with pytest.raises(ValueError, match='Public key must be 32 bytes'):
            validate_message_structure(ciphertext, nonce, pubkey)

    def test_ciphertext_too_short(self):
        ciphertext = base64.b64encode(b'x' * 8).decode()  # Too short
        nonce = base64.b64encode(b'x' * 24).decode()
        pubkey = base64.b64encode(b'x' * 32).decode()
        with pytest.raises(ValueError, match='Ciphertext too short'):
            validate_message_structure(ciphertext, nonce, pubkey)

    def test_invalid_base64(self):
        with pytest.raises(ValueError, match='Invalid Base64'):
            validate_message_structure('!!!invalid!!!', 'bad', 'data')


class TestSessionTokens:
    """Test session token generation and hashing."""

    def test_generate_session_token_length(self):
        token = generate_session_token()
        assert len(token) == 64  # 32 bytes hex = 64 chars

    def test_tokens_are_unique(self):
        t1 = generate_session_token()
        t2 = generate_session_token()
        assert t1 != t2

    def test_hash_session_token_deterministic(self):
        token = 'test-token'
        key = 'test-key'
        h1 = hash_session_token(token, key)
        h2 = hash_session_token(token, key)
        assert h1 == h2

    def test_hash_different_keys_differ(self):
        token = 'test-token'
        h1 = hash_session_token(token, 'key1')
        h2 = hash_session_token(token, 'key2')
        assert h1 != h2
