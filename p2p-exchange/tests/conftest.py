import pytest
from app import create_app, db as _db
from app.models.user import User
from app.services.encryption import generate_session_token, hash_session_token

@pytest.fixture(scope='session')
def app():
    app = create_app('testing')
    with app.app_context():
        _db.create_all()
        yield app
        _db.drop_all()

@pytest.fixture(scope='function')
def db(app):
    with app.app_context():
        yield _db
        _db.session.rollback()

@pytest.fixture(scope='function')
def client(app):
    return app.test_client()

@pytest.fixture(scope='function')
def test_user(app, db):
    with app.app_context():
        from app.services.encryption import generate_mnemonic, derive_keypair_from_mnemonic
        mnemonic = generate_mnemonic()
        keypair = derive_keypair_from_mnemonic(mnemonic)
        token = generate_session_token()
        hmac_secret = app.config['HMAC_SECRET']
        token_hash = hash_session_token(token, hmac_secret)
        user = User(
            session_token_hash=token_hash,
            public_key=keypair['public_key'],
            display_name='TestUser',
        )
        db.session.add(user)
        db.session.commit()
        return {'user': user, 'token': token, 'mnemonic': mnemonic, 'keypair': keypair}

@pytest.fixture(scope='function')
def auth_client(client, test_user):
    token = test_user['token']
    class AuthClient:
        def get(self, *args, **kwargs):
            kwargs.setdefault('headers', {})['X-Session-Token'] = token
            return client.get(*args, **kwargs)
        def post(self, *args, **kwargs):
            kwargs.setdefault('headers', {})['X-Session-Token'] = token
            return client.post(*args, **kwargs)
        def put(self, *args, **kwargs):
            kwargs.setdefault('headers', {})['X-Session-Token'] = token
            return client.put(*args, **kwargs)
        def delete(self, *args, **kwargs):
            kwargs.setdefault('headers', {})['X-Session-Token'] = token
            return client.delete(*args, **kwargs)
    return AuthClient()
