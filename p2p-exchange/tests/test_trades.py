import pytest


def test_initiate_trade(app, second_user_client):
    """Buyer can initiate a trade against a seller's offer."""
    seller_client = app.test_client()
    seller_client.post('/register', data={
        'username': 'tradeseller', 'password': 'password123', 'confirm_password': 'password123',
    })
    seller_client.post('/login', data={'username': 'tradeseller', 'password': 'password123'})
    seller_client.post('/offers/create', data={
        'offer_type': 'sell', 'fiat_currency': 'USD', 'price_margin': '0',
        'min_amount': '10', 'max_amount': '1000', 'payment_method': 'Cash',
    })

    # Register and log in the buyer using the second_user_client
    second_user_client.post('/register', data={
        'username': 'tradebuyer', 'password': 'password456', 'confirm_password': 'password456',
    })
    second_user_client.post('/login', data={'username': 'tradebuyer', 'password': 'password456'})

    # Query DB directly (we're inside the app fixture's active app context)
    from database import get_db
    db = get_db()
    offer = db.execute('SELECT id FROM offers WHERE is_active=1 LIMIT 1').fetchone()
    assert offer is not None, "Offer should have been created by seller"
    offer_id = offer['id']

    # Seed the coingecko cache so trade initiation can compute amount_xmr
    import coingecko, time
    coingecko._cache['xmr_usd'] = (150.0, time.time())

    resp = second_user_client.post('/trades/initiate', data={
        'offer_id': str(offer_id),
        'amount_fiat': '100',
    }, follow_redirects=True)
    assert resp.status_code == 200


def test_trade_detail_requires_login(client):
    resp = client.get('/trades/1', follow_redirects=False)
    assert resp.status_code == 302


def test_cancel_trade(app):
    seller = app.test_client()
    buyer = app.test_client()

    seller.post('/register', data={'username': 'cancseller', 'password': 'password123', 'confirm_password': 'password123'})
    seller.post('/login', data={'username': 'cancseller', 'password': 'password123'})
    seller.post('/offers/create', data={
        'offer_type': 'sell', 'fiat_currency': 'USD', 'price_margin': '0',
        'min_amount': '10', 'max_amount': '1000', 'payment_method': 'Cash',
    })

    buyer.post('/register', data={'username': 'cancbuyer', 'password': 'password456', 'confirm_password': 'password456'})
    buyer.post('/login', data={'username': 'cancbuyer', 'password': 'password456'})

    # Query DB directly (we're inside the app fixture's active app context)
    from database import get_db
    db = get_db()
    offer = db.execute("SELECT id FROM offers WHERE is_active=1 ORDER BY id DESC LIMIT 1").fetchone()
    assert offer, "Offer should exist after seller created it"
    offer_id = offer['id']

    # Seed the coingecko cache so trade initiation can compute amount_xmr
    import coingecko, time
    coingecko._cache['xmr_usd'] = (150.0, time.time())

    buyer.post('/trades/initiate', data={'offer_id': str(offer_id), 'amount_fiat': '50'})

    trade = db.execute("SELECT id FROM trades ORDER BY id DESC LIMIT 1").fetchone()
    assert trade, "Trade should exist after initiation"
    trade_id = trade['id']

    resp = buyer.post(f'/trades/{trade_id}/cancel', follow_redirects=True)
    assert resp.status_code == 200

    trade = db.execute("SELECT status FROM trades WHERE id=?", (trade_id,)).fetchone()
    assert trade['status'] == 'cancelled'
