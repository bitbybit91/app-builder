import json
import pytest
from app.services.encryption import generate_mnemonic, derive_keypair_from_mnemonic

def make_offer_data(**kwargs):
    data = {
        'type': 'sell',
        'fiat_currency': 'USD',
        'payment_method': 'Bank Transfer',
        'min_amount': 10.0,
        'max_amount': 1000.0,
        'country': 'US',
        'terms': 'Payment within 30 minutes.',
    }
    data.update(kwargs)
    return data

def test_list_offers_empty(client):
    resp = client.get('/api/offers')
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert 'offers' in data

def test_create_offer(client, test_user):
    resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 201
    data = json.loads(resp.data)
    assert data['type'] == 'sell'
    assert data['fiat_currency'] == 'USD'

def test_create_offer_unauthorized(client):
    resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json')
    assert resp.status_code == 401

def test_create_offer_invalid_type(client, test_user):
    resp = client.post('/api/offers',
        data=json.dumps(make_offer_data(type='invalid')),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 400

def test_get_offer(client, test_user):
    create_resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    offer_id = json.loads(create_resp.data)['id']
    resp = client.get(f'/api/offers/{offer_id}')
    assert resp.status_code == 200
    assert json.loads(resp.data)['id'] == offer_id

def test_filter_offers_by_type(client, test_user):
    client.post('/api/offers',
        data=json.dumps(make_offer_data(type='sell')),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    resp = client.get('/api/offers?type=sell')
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert all(o['type'] == 'sell' for o in data['offers'])

def test_update_offer(client, test_user):
    create_resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    offer_id = json.loads(create_resp.data)['id']
    resp = client.put(f'/api/offers/{offer_id}',
        data=json.dumps({'payment_method': 'Cash'}),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['payment_method'] == 'Cash'

def test_update_offer_forbidden(client, test_user, app, db):
    with app.app_context():
        from app.models.user import User
        from app.services.encryption import generate_mnemonic, derive_keypair_from_mnemonic, generate_session_token, hash_session_token
        m2 = generate_mnemonic()
        kp2 = derive_keypair_from_mnemonic(m2)
        t2 = generate_session_token()
        th2 = hash_session_token(t2, app.config['HMAC_SECRET'])
        u2 = User(session_token_hash=th2, public_key=kp2['public_key'], display_name='Other')
        db.session.add(u2)
        db.session.commit()
    create_resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    offer_id = json.loads(create_resp.data)['id']
    resp = client.put(f'/api/offers/{offer_id}',
        data=json.dumps({'payment_method': 'Cash'}),
        content_type='application/json',
        headers={'X-Session-Token': t2})
    assert resp.status_code == 403

def test_delete_offer(client, test_user):
    create_resp = client.post('/api/offers',
        data=json.dumps(make_offer_data()),
        content_type='application/json',
        headers={'X-Session-Token': test_user['token']})
    offer_id = json.loads(create_resp.data)['id']
    resp = client.delete(f'/api/offers/{offer_id}',
        headers={'X-Session-Token': test_user['token']})
    assert resp.status_code == 200
