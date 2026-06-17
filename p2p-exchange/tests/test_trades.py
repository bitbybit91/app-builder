import json
import pytest
from app.models.trade import TradeStatus

def create_offer_and_users(client, app, db):
    from app.models.user import User
    from app.services.encryption import generate_mnemonic, derive_keypair_from_mnemonic, generate_session_token, hash_session_token
    with app.app_context():
        m1 = generate_mnemonic()
        kp1 = derive_keypair_from_mnemonic(m1)
        t1 = generate_session_token()
        th1 = hash_session_token(t1, app.config['HMAC_SECRET'])
        seller = User(session_token_hash=th1, public_key=kp1['public_key'], display_name='Seller')
        db.session.add(seller)
        m2 = generate_mnemonic()
        kp2 = derive_keypair_from_mnemonic(m2)
        t2 = generate_session_token()
        th2 = hash_session_token(t2, app.config['HMAC_SECRET'])
        buyer = User(session_token_hash=th2, public_key=kp2['public_key'], display_name='Buyer')
        db.session.add(buyer)
        db.session.commit()
        seller_id = seller.id
        buyer_id = buyer.id
    offer_resp = client.post('/api/offers',
        data=json.dumps({'type': 'sell', 'fiat_currency': 'USD', 'payment_method': 'Bank', 'min_amount': 10, 'max_amount': 500}),
        content_type='application/json',
        headers={'X-Session-Token': t1})
    offer_id = json.loads(offer_resp.data)['id']
    return {'seller_token': t1, 'buyer_token': t2, 'offer_id': offer_id, 'seller_id': seller_id, 'buyer_id': buyer_id}

def test_initiate_trade(client, app, db):
    ctx = create_offer_and_users(client, app, db)
    resp = client.post('/api/trades',
        data=json.dumps({'offer_id': ctx['offer_id'], 'amount_xmr': 0.5, 'amount_fiat': 75.0}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    assert resp.status_code == 201
    data = json.loads(resp.data)
    assert data['status'] == TradeStatus.INITIATED

def test_trade_state_machine(client, app, db):
    ctx = create_offer_and_users(client, app, db)
    trade_resp = client.post('/api/trades',
        data=json.dumps({'offer_id': ctx['offer_id'], 'amount_xmr': 0.1, 'amount_fiat': 15.0}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    trade_id = json.loads(trade_resp.data)['id']
    # Confirm escrow (seller)
    resp = client.post(f'/api/trades/{trade_id}/confirm_escrow',
        data=json.dumps({'txid': 'abc123'}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['seller_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.ESCROW_FUNDED
    # Fiat sent (buyer)
    resp = client.post(f'/api/trades/{trade_id}/fiat_sent',
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.FIAT_SENT
    # Fiat received (seller)
    resp = client.post(f'/api/trades/{trade_id}/fiat_received',
        content_type='application/json',
        headers={'X-Session-Token': ctx['seller_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.FIAT_RECEIVED
    # Complete (seller)
    resp = client.post(f'/api/trades/{trade_id}/complete',
        content_type='application/json',
        headers={'X-Session-Token': ctx['seller_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.COMPLETED

def test_cancel_trade(client, app, db):
    ctx = create_offer_and_users(client, app, db)
    trade_resp = client.post('/api/trades',
        data=json.dumps({'offer_id': ctx['offer_id'], 'amount_xmr': 0.1, 'amount_fiat': 15.0}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    trade_id = json.loads(trade_resp.data)['id']
    resp = client.post(f'/api/trades/{trade_id}/cancel',
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.CANCELLED

def test_dispute_trade(client, app, db):
    ctx = create_offer_and_users(client, app, db)
    trade_resp = client.post('/api/trades',
        data=json.dumps({'offer_id': ctx['offer_id'], 'amount_xmr': 0.1, 'amount_fiat': 15.0}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    trade_id = json.loads(trade_resp.data)['id']
    # Fund escrow first
    client.post(f'/api/trades/{trade_id}/confirm_escrow',
        data=json.dumps({'txid': 'tx123'}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['seller_token']})
    resp = client.post(f'/api/trades/{trade_id}/dispute',
        data=json.dumps({'reason': 'Payment not received'}),
        content_type='application/json',
        headers={'X-Session-Token': ctx['buyer_token']})
    assert resp.status_code == 200
    assert json.loads(resp.data)['status'] == TradeStatus.DISPUTED
