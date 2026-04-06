def test_wallet_requires_login(client):
    resp = client.get('/wallet', follow_redirects=False)
    assert resp.status_code == 302
    assert '/login' in resp.headers.get('Location', '')

def test_wallet_page(auth_client):
    resp = auth_client.get('/wallet')
    assert resp.status_code == 200
    assert b'Wallet' in resp.data or b'wallet' in resp.data.lower()

def test_wallet_withdraw_no_balance(auth_client):
    resp = auth_client.post('/wallet/withdraw', data={
        'address': '4AdUndXHHZ9pfQj27bTRZqtqSoFNEfNpDRrBAKcgMCTTJmhB5p3p4vqeZ7xGN48w3yF4JVZ9RTCBA',
        'amount': '1.0',
    }, follow_redirects=True)
    assert resp.status_code == 200
    assert b'Insufficient' in resp.data or b'insufficient' in resp.data.lower() or b'balance' in resp.data.lower()

def test_wallet_withdraw_invalid_amount(auth_client):
    resp = auth_client.post('/wallet/withdraw', data={
        'address': '4AdUndXHHZ9pfQj27bTRZqtqSoFNEfNpDRrBAKcgMCTTJmhB5p3p4vqeZ7xGN48w3yF4JVZ9RTCBA',
        'amount': 'notanumber',
    }, follow_redirects=True)
    assert resp.status_code == 200
    assert b'Invalid' in resp.data or b'invalid' in resp.data.lower()
