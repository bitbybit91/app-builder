def test_offers_page(client):
    resp = client.get('/offers')
    assert resp.status_code == 200

def test_create_offer_requires_login(client):
    resp = client.get('/offers/create', follow_redirects=False)
    assert resp.status_code == 302

def test_create_offer_success(auth_client):
    resp = auth_client.post('/offers/create', data={
        'offer_type': 'sell',
        'fiat_currency': 'USD',
        'price_margin': '0',
        'min_amount': '10',
        'max_amount': '1000',
        'payment_method': 'Bank Transfer',
        'terms': 'Test terms',
    }, follow_redirects=True)
    assert resp.status_code == 200
    assert b'created' in resp.data.lower() or b'dashboard' in resp.data.lower()

def test_create_offer_invalid_type(auth_client):
    resp = auth_client.post('/offers/create', data={
        'offer_type': 'invalid',
        'fiat_currency': 'USD',
        'price_margin': '0',
        'min_amount': '10',
        'max_amount': '1000',
        'payment_method': 'Cash',
    }, follow_redirects=True)
    assert b'buy or sell' in resp.data.lower() or b'type' in resp.data.lower()

def test_create_offer_invalid_margin(auth_client):
    resp = auth_client.post('/offers/create', data={
        'offer_type': 'sell',
        'fiat_currency': 'USD',
        'price_margin': '100',
        'min_amount': '10',
        'max_amount': '1000',
        'payment_method': 'Cash',
    }, follow_redirects=True)
    assert b'margin' in resp.data.lower() or b'-20' in resp.data

def test_create_offer_min_greater_than_max(auth_client):
    resp = auth_client.post('/offers/create', data={
        'offer_type': 'sell',
        'fiat_currency': 'USD',
        'price_margin': '0',
        'min_amount': '1000',
        'max_amount': '10',
        'payment_method': 'Cash',
    }, follow_redirects=True)
    assert b'less than' in resp.data.lower() or b'min' in resp.data.lower()

def test_filter_offers_by_type(auth_client):
    auth_client.post('/offers/create', data={
        'offer_type': 'sell', 'fiat_currency': 'USD',
        'price_margin': '0', 'min_amount': '10', 'max_amount': '500',
        'payment_method': 'Cash',
    })
    resp = auth_client.get('/offers?type=sell')
    assert resp.status_code == 200
    assert b'SELL' in resp.data

def test_deactivate_offer(auth_client, app):
    from database import get_db
    auth_client.post('/offers/create', data={
        'offer_type': 'sell', 'fiat_currency': 'USD',
        'price_margin': '0', 'min_amount': '10', 'max_amount': '500',
        'payment_method': 'Cash',
    })
    with app.app_context():
        db = get_db()
        offer = db.execute('SELECT id FROM offers LIMIT 1').fetchone()
        assert offer is not None
        offer_id = offer['id']
    resp = auth_client.post(f'/offers/{offer_id}/deactivate', follow_redirects=True)
    assert resp.status_code == 200
