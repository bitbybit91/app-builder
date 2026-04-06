"""
Shared test fixtures.
"""

import pytest
from app import create_app, db as _db


@pytest.fixture(scope='session')
def app():
    """Create Flask application for testing."""
    app = create_app('testing')
    yield app


@pytest.fixture(scope='function')
def db(app):
    """Create a fresh database for each test."""
    with app.app_context():
        _db.create_all()
        yield _db
        _db.session.rollback()
        _db.drop_all()


@pytest.fixture(scope='function')
def client(app, db):
    """Flask test client."""
    with app.test_client() as client:
        with app.app_context():
            yield client


@pytest.fixture
def session_token(client):
    """Create a session and return the token."""
    response = client.post('/api/auth/session', json={'nickname': 'testuser'})
    data = response.get_json()
    return data['session_token']


@pytest.fixture
def auth_headers(session_token):
    """Authorization headers with session token."""
    return {'Authorization': f'Bearer {session_token}'}


@pytest.fixture
def second_session(client):
    """Create a second session for two-party trades."""
    response = client.post('/api/auth/session', json={'nickname': 'testuser2'})
    data = response.get_json()
    return {
        'token': data['session_token'],
        'user': data['user'],
        'headers': {'Authorization': f'Bearer {data["session_token"]}'},
    }
