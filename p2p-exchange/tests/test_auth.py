def test_register_page(client):
    resp = client.get('/register')
    assert resp.status_code == 200
    assert b'Register' in resp.data or b'register' in resp.data.lower()

def test_register_success(client):
    resp = client.post('/register', data={
        'username': 'newuser1',
        'password': 'password123',
        'confirm_password': 'password123',
    }, follow_redirects=True)
    assert resp.status_code == 200

def test_register_short_username(client):
    resp = client.post('/register', data={
        'username': 'ab',
        'password': 'password123',
        'confirm_password': 'password123',
    }, follow_redirects=True)
    assert b'3-20' in resp.data or b'alphanumeric' in resp.data

def test_register_password_mismatch(client):
    resp = client.post('/register', data={
        'username': 'validuser',
        'password': 'password123',
        'confirm_password': 'different123',
    }, follow_redirects=True)
    assert b'match' in resp.data.lower() or b'Passwords' in resp.data

def test_register_short_password(client):
    resp = client.post('/register', data={
        'username': 'validuser',
        'password': 'short',
        'confirm_password': 'short',
    }, follow_redirects=True)
    assert b'8' in resp.data

def test_register_duplicate_username(client):
    client.post('/register', data={
        'username': 'dupuser',
        'password': 'password123',
        'confirm_password': 'password123',
    })
    resp = client.post('/register', data={
        'username': 'dupuser',
        'password': 'password456',
        'confirm_password': 'password456',
    }, follow_redirects=True)
    assert b'taken' in resp.data.lower() or b'already' in resp.data.lower()

def test_login_page(client):
    resp = client.get('/login')
    assert resp.status_code == 200

def test_login_success(client):
    client.post('/register', data={
        'username': 'loginuser',
        'password': 'password123',
        'confirm_password': 'password123',
    })
    resp = client.post('/login', data={
        'username': 'loginuser',
        'password': 'password123',
    }, follow_redirects=True)
    assert resp.status_code == 200
    assert b'dashboard' in resp.data.lower() or b'Dashboard' in resp.data

def test_login_wrong_password(client):
    client.post('/register', data={
        'username': 'loginuser2',
        'password': 'password123',
        'confirm_password': 'password123',
    })
    resp = client.post('/login', data={
        'username': 'loginuser2',
        'password': 'wrongpassword',
    }, follow_redirects=True)
    assert b'Invalid' in resp.data or b'invalid' in resp.data.lower()

def test_logout(auth_client):
    resp = auth_client.get('/logout', follow_redirects=True)
    assert resp.status_code == 200

def test_dashboard_requires_login(client):
    resp = client.get('/dashboard', follow_redirects=False)
    assert resp.status_code == 302
    assert '/login' in resp.headers.get('Location', '')
