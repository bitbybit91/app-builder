import os
import hmac
import hashlib
import secrets
import base64
from mnemonic import Mnemonic
import nacl.utils
import nacl.public
import nacl.secret
import nacl.hash
import nacl.encoding

MNEMONIC_STRENGTH = 128  # 12 words

def generate_mnemonic():
    mnemo = Mnemonic('english')
    return mnemo.generate(strength=MNEMONIC_STRENGTH)

def validate_mnemonic(mnemonic_phrase):
    mnemo = Mnemonic('english')
    return mnemo.check(mnemonic_phrase)

def mnemonic_to_seed(mnemonic_phrase, passphrase=''):
    mnemo = Mnemonic('english')
    return mnemo.to_seed(mnemonic_phrase, passphrase)

def derive_keypair_from_mnemonic(mnemonic_phrase, passphrase=''):
    seed = mnemonic_to_seed(mnemonic_phrase, passphrase)
    # Use first 32 bytes of seed as private key
    private_key_bytes = seed[:32]
    private_key = nacl.public.PrivateKey(private_key_bytes)
    public_key = private_key.public_key
    return {
        'private_key': base64.b64encode(bytes(private_key)).decode('utf-8'),
        'public_key': base64.b64encode(bytes(public_key)).decode('utf-8'),
        'public_key_hex': bytes(public_key).hex(),
    }

def generate_session_token():
    return secrets.token_urlsafe(32)

def hash_session_token(token, hmac_secret):
    return hmac.new(
        hmac_secret.encode('utf-8'),
        token.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

def verify_session_token(token, stored_hash, hmac_secret):
    expected_hash = hash_session_token(token, hmac_secret)
    return hmac.compare_digest(expected_hash, stored_hash)

def hash_mnemonic(mnemonic_phrase):
    return hashlib.sha256(mnemonic_phrase.encode('utf-8')).hexdigest()

def encrypt_message(sender_private_key_b64, recipient_public_key_b64, plaintext):
    sender_private_key = nacl.public.PrivateKey(base64.b64decode(sender_private_key_b64))
    recipient_public_key = nacl.public.PublicKey(base64.b64decode(recipient_public_key_b64))
    box = nacl.public.Box(sender_private_key, recipient_public_key)
    nonce = nacl.utils.random(nacl.public.Box.NONCE_SIZE)
    encrypted = box.encrypt(plaintext.encode('utf-8'), nonce)
    return {
        'encrypted_content': base64.b64encode(encrypted.ciphertext).decode('utf-8'),
        'nonce': base64.b64encode(nonce).decode('utf-8'),
        'ephemeral_public_key': base64.b64encode(bytes(sender_private_key.public_key)).decode('utf-8'),
    }

def decrypt_message(recipient_private_key_b64, sender_public_key_b64, encrypted_content_b64, nonce_b64):
    recipient_private_key = nacl.public.PrivateKey(base64.b64decode(recipient_private_key_b64))
    sender_public_key = nacl.public.PublicKey(base64.b64decode(sender_public_key_b64))
    box = nacl.public.Box(recipient_private_key, sender_public_key)
    ciphertext = base64.b64decode(encrypted_content_b64)
    nonce = base64.b64decode(nonce_b64)
    decrypted = box.decrypt(ciphertext, nonce)
    return decrypted.decode('utf-8')
