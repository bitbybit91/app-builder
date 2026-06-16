"""
Tests for Authentication Routes
=================================
"""

import pytest


class TestSessionCreation:
    """Test anonymous session creation."""

    def test_create_session_anonymous(self, client):
        response = client.post('/api/auth/session', json={})
        assert response.status_code == 201
        data = response.get_json()
        assert 'session_token' in data
        assert 'user' in data
        assert data['user']['nickname'].startswith('anon-')
        assert 'encryption_keypair' in data

    def test_create_session_with_nickname(self, client):
        response = client.post('/api/auth/session', json={'nickname': 'satoshi'})
        assert response.status_code == 201
        data = response.get_json()
        assert data['user']['nickname'] == 'satoshi'

    def test_duplicate_nickname_rejected(self, client):
        client.post('/api/auth/session', json={'nickname': 'unique1'})
        response = client.post('/api/auth/session', json={'nickname': 'unique1'})
        assert response.status_code == 409

    def test_session_token_is_64_chars(self, client):
        response = client.post('/api/auth/session', json={})
        data = response.get_json()
        assert len(data['session_token']) == 64


class TestSessionVerification:
    """Test session token verification."""

    def test_verify_valid_token(self, client, session_token):
        response = client.post('/api/auth/session/verify', json={
            'session_token': session_token,
        })
        assert response.status_code == 200
        data = response.get_json()
        assert data['valid'] is True
        assert 'user' in data

    def test_verify_invalid_token(self, client):
        response = client.post('/api/auth/session/verify', json={
            'session_token': 'invalid-token',
        })
        assert response.status_code == 401
        data = response.get_json()
        assert data['valid'] is False

    def test_verify_empty_token(self, client):
        response = client.post('/api/auth/session/verify', json={})
        assert response.status_code == 401


class TestMnemonicIdentity:
    """Test mnemonic-based persistent identity."""

    def test_generate_mnemonic(self, client):
        response = client.post('/api/auth/mnemonic/generate')
        assert response.status_code == 201
        data = response.get_json()
        assert 'mnemonic' in data
        words = data['mnemonic'].split()
        assert len(words) == 12
        assert 'public_key' in data

    def test_bind_mnemonic_to_session(self, client, session_token):
        # Generate mnemonic
        gen_resp = client.post('/api/auth/mnemonic/generate')
        mnemonic = gen_resp.get_json()['mnemonic']

        # Bind to session
        response = client.post('/api/auth/mnemonic/bind', json={
            'session_token': session_token,
            'mnemonic': mnemonic,
        })
        assert response.status_code == 200

    def test_recover_nonexistent_identity(self, client):
        gen_resp = client.post('/api/auth/mnemonic/generate')
        mnemonic = gen_resp.get_json()['mnemonic']

        response = client.post('/api/auth/mnemonic/recover', json={
            'mnemonic': mnemonic,
        })
        assert response.status_code == 404
