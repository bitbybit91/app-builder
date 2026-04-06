import pytest
from app.services.encryption import (
    generate_mnemonic, validate_mnemonic, derive_keypair_from_mnemonic,
    generate_session_token, hash_session_token, verify_session_token,
    hash_mnemonic, encrypt_message, decrypt_message
)

def test_generate_mnemonic():
    mnemonic = generate_mnemonic()
    words = mnemonic.strip().split()
    assert len(words) == 12

def test_validate_mnemonic_valid():
    mnemonic = generate_mnemonic()
    assert validate_mnemonic(mnemonic) is True

def test_validate_mnemonic_invalid():
    assert validate_mnemonic('invalid mnemonic phrase that is not valid bip39') is False

def test_derive_keypair_deterministic():
    mnemonic = generate_mnemonic()
    kp1 = derive_keypair_from_mnemonic(mnemonic)
    kp2 = derive_keypair_from_mnemonic(mnemonic)
    assert kp1['public_key'] == kp2['public_key']
    assert kp1['private_key'] == kp2['private_key']

def test_derive_keypair_different_mnemonics():
    m1 = generate_mnemonic()
    m2 = generate_mnemonic()
    kp1 = derive_keypair_from_mnemonic(m1)
    kp2 = derive_keypair_from_mnemonic(m2)
    assert kp1['public_key'] != kp2['public_key']

def test_session_token_generation():
    token = generate_session_token()
    assert len(token) > 20
    token2 = generate_session_token()
    assert token != token2

def test_session_token_hmac():
    token = generate_session_token()
    secret = 'test-secret'
    h1 = hash_session_token(token, secret)
    h2 = hash_session_token(token, secret)
    assert h1 == h2

def test_verify_session_token_valid():
    token = generate_session_token()
    secret = 'test-secret'
    token_hash = hash_session_token(token, secret)
    assert verify_session_token(token, token_hash, secret) is True

def test_verify_session_token_invalid():
    token = generate_session_token()
    secret = 'test-secret'
    token_hash = hash_session_token(token, secret)
    assert verify_session_token('wrong-token', token_hash, secret) is False

def test_hash_mnemonic_deterministic():
    mnemonic = generate_mnemonic()
    h1 = hash_mnemonic(mnemonic)
    h2 = hash_mnemonic(mnemonic)
    assert h1 == h2

def test_encrypt_decrypt_message():
    m1 = generate_mnemonic()
    m2 = generate_mnemonic()
    kp1 = derive_keypair_from_mnemonic(m1)
    kp2 = derive_keypair_from_mnemonic(m2)
    plaintext = 'Hello, this is a secret message!'
    encrypted = encrypt_message(kp1['private_key'], kp2['public_key'], plaintext)
    assert 'encrypted_content' in encrypted
    assert 'nonce' in encrypted
    assert 'ephemeral_public_key' in encrypted
    decrypted = decrypt_message(kp2['private_key'], kp1['public_key'], encrypted['encrypted_content'], encrypted['nonce'])
    assert decrypted == plaintext
