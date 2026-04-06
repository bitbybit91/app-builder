import os
import pytest

os.environ['FLASK_ENV'] = 'testing'

@pytest.fixture(scope='function')
def app():
    from app import create_app
    application = create_app('testing')
    with application.app_context():
        from database import init_db
        init_db()
        yield application

@pytest.fixture(scope='function')
def client(app):
    return app.test_client()

@pytest.fixture(scope='function')
def auth_client(client):
    """Returns a client with an authenticated session."""
    client.post('/register', data={
        'username': 'testuser',
        'password': 'testpassword123',
        'confirm_password': 'testpassword123',
    })
    client.post('/login', data={
        'username': 'testuser',
        'password': 'testpassword123',
    })
    return client

@pytest.fixture(scope='function')
def second_user_client(app):
    """Returns a second authenticated client for testing trades."""
    client2 = app.test_client()
    client2.post('/register', data={
        'username': 'otheruser',
        'password': 'otherpassword123',
        'confirm_password': 'otherpassword123',
    })
    client2.post('/login', data={
        'username': 'otheruser',
        'password': 'otherpassword123',
    })
    return client2
