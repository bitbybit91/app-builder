"""
Tests for Trades Routes
========================
"""

import pytest


class TestTradeInitiation:
    """Test trade creation from offers."""

    def _create_offer(self, client, headers, offer_type='sell'):
        resp = client.post('/api/offers', json={
            'offer_type': offer_type,
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=headers)
        return resp.get_json()['offer']

    def test_initiate_trade(self, client, auth_headers, second_session):
        # First user creates offer
        offer = self._create_offer(client, auth_headers)

        # Second user initiates trade
        response = client.post('/api/trades', json={
            'offer_id': offer['id'],
            'crypto_amount': 1.0,
            'fiat_amount': 150.0,
            'buyer_wallet_address': '4' + 'A' * 94,
        }, headers=second_session['headers'])
        assert response.status_code == 201
        data = response.get_json()
        assert data['trade']['status'] == 'initiated'
        assert data['trade']['crypto_amount'] == 1.0

    def test_cannot_trade_with_self(self, client, auth_headers):
        offer = self._create_offer(client, auth_headers)

        response = client.post('/api/trades', json={
            'offer_id': offer['id'],
            'crypto_amount': 1.0,
            'fiat_amount': 150.0,
        }, headers=auth_headers)
        assert response.status_code == 400

    def test_trade_requires_auth(self, client, auth_headers):
        offer = self._create_offer(client, auth_headers)

        response = client.post('/api/trades', json={
            'offer_id': offer['id'],
            'crypto_amount': 1.0,
            'fiat_amount': 150.0,
        })
        assert response.status_code == 401

    def test_trade_amount_out_of_range(self, client, auth_headers, second_session):
        offer = self._create_offer(client, auth_headers)

        response = client.post('/api/trades', json={
            'offer_id': offer['id'],
            'crypto_amount': 1.0,
            'fiat_amount': 99999.0,  # Above max_amount
        }, headers=second_session['headers'])
        assert response.status_code == 400


class TestTradeActions:
    """Test trade state transitions."""

    def _setup_trade(self, client, auth_headers, second_session):
        # Create offer as first user
        offer_resp = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        offer = offer_resp.get_json()['offer']

        # Second user initiates trade (as buyer)
        trade_resp = client.post('/api/trades', json={
            'offer_id': offer['id'],
            'crypto_amount': 1.0,
            'fiat_amount': 150.0,
            'buyer_wallet_address': '4' + 'A' * 94,
        }, headers=second_session['headers'])
        return trade_resp.get_json()['trade']

    def test_list_trades(self, client, auth_headers, second_session):
        self._setup_trade(client, auth_headers, second_session)

        response = client.get('/api/trades', headers=auth_headers)
        assert response.status_code == 200
        assert response.get_json()['total'] >= 1

    def test_get_trade(self, client, auth_headers, second_session):
        trade = self._setup_trade(client, auth_headers, second_session)

        response = client.get(f'/api/trades/{trade["id"]}', headers=auth_headers)
        assert response.status_code == 200

    def test_cancel_trade(self, client, auth_headers, second_session):
        trade = self._setup_trade(client, auth_headers, second_session)

        response = client.post(f'/api/trades/{trade["id"]}/cancel', headers=auth_headers)
        assert response.status_code == 200
        assert response.get_json()['trade']['status'] == 'cancelled'

    def test_mark_fiat_sent_wrong_state(self, client, auth_headers, second_session):
        trade = self._setup_trade(client, auth_headers, second_session)

        # Buyer tries to mark fiat sent before escrow funded
        response = client.post(
            f'/api/trades/{trade["id"]}/fiat-sent',
            headers=second_session['headers'],
        )
        assert response.status_code == 400

    def test_open_dispute(self, client, auth_headers, second_session):
        trade = self._setup_trade(client, auth_headers, second_session)

        # Mark escrow funded
        client.post(
            f'/api/trades/{trade["id"]}/escrow-funded',
            json={'tx_id': 'abc123'},
            headers=auth_headers,
        )

        # Open dispute
        response = client.post(
            f'/api/trades/{trade["id"]}/dispute',
            json={'reason': 'Seller not responding'},
            headers=second_session['headers'],
        )
        assert response.status_code == 200
        assert response.get_json()['trade']['status'] == 'disputed'
