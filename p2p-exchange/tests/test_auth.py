import json
import pytest
from app.services.encryption import generate_mnemonic, derive_keypair_from_mnemonic

def test_generate_mnemonic_endpoint(client):
    resp = client.get('/api/auth/mnemonic/generate')
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert 'mnemonic' in data
    assert len(data['mnemonic'].split()) == 12
    assert 'public_key' in data

def test_recover_from_mnemonic(client):
    mnemonic = generate_mnemonic()
    resp = client.post('/api/auth/mnemonic/recover',
        data=json.dumps({'mnemonic': mnemonic}),
        content_type='application/json')
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert 'public_key' in data

def test_recover_invalid_mnemonic(client):
    resp = client.post('/api/auth/mnemonic/recover',
        data=json.dumps({'mnemonic': 'invalid mnemonic here x y z'}),
        content_type='application/json')
    assert resp.status_code == 400

def test_create_session(client):
    mnemonic = generate_mnemonic()
    kp = derive_keypair_from_mnemonic(mnemonic)
    resp = client.post('/api/auth/session',
        data=json.dumps({'public_key': kp['public_key'], 'display_name': 'Tester'}),
        content_type='application/json')
    assert resp.status_code == 201
    data = json.loads(resp.data)
    assert 'token' in data
    assert 'user' in data
    assert data['user']['display_name'] == 'Tester'

def test_create_session_missing_public_key(client):
    resp = client.post('/api/auth/session',
        data=json.dumps({'display_name': 'Tester'}),
        content_type='application/json')
    assert resp.status_code == 400

def test_verify_session(client, test_user):
    resp = client.get('/api/auth/verify',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert data['valid'] is True

def test_verify_invalid_session(client):
    resp = client.get('/api/auth/verify',
        headers={'X-Session-Token': 'invalid-token'})
    assert resp.status_code == 401

def test_bind_mnemonic(client, test_user):
    resp = client.post('/api/auth/mnemonic/bind',
        data=json.dumps({'mnemonic': test_user['mnemonic']}),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert data['success'] is True

def test_logout(client, test_user):
    resp = client.post('/api/auth/logout',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 200
