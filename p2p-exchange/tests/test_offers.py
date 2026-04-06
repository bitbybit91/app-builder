"""
Tests for Offers Routes
========================
"""

import pytest


class TestOfferCreation:
    """Test offer CRUD operations."""

    def test_create_offer(self, client, auth_headers):
        response = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'price_type': 'market',
            'price_margin': 5.0,
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
            'terms': 'Fast payment required',
        }, headers=auth_headers)
        assert response.status_code == 201
        data = response.get_json()
        assert data['offer']['offer_type'] == 'sell'
        assert data['offer']['fiat_currency'] == 'USD'
        assert data['offer']['min_amount'] == 50
        assert data['offer']['max_amount'] == 5000

    def test_create_offer_requires_auth(self, client):
        response = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        })
        assert response.status_code == 401

    def test_create_offer_invalid_type(self, client, auth_headers):
        response = client.post('/api/offers', json={
            'offer_type': 'invalid',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        assert response.status_code == 400

    def test_create_offer_invalid_payment_method(self, client, auth_headers):
        response = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'not_a_real_method',
        }, headers=auth_headers)
        assert response.status_code == 400

    def test_create_offer_invalid_amount_range(self, client, auth_headers):
        response = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 5000,  # min > max
            'max_amount': 50,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        assert response.status_code == 400


class TestOfferListing:
    """Test offer listing and filtering."""

    def test_list_offers_empty(self, client):
        response = client.get('/api/offers')
        assert response.status_code == 200
        data = response.get_json()
        assert data['offers'] == []
        assert data['total'] == 0

    def test_list_offers_with_data(self, client, auth_headers):
        # Create an offer
        client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'EUR',
            'min_amount': 100,
            'max_amount': 1000,
            'payment_method': 'revolut',
        }, headers=auth_headers)

        response = client.get('/api/offers')
        assert response.status_code == 200
        data = response.get_json()
        assert data['total'] == 1
        assert data['offers'][0]['fiat_currency'] == 'EUR'

    def test_filter_by_currency(self, client, auth_headers):
        # Create offers with different currencies
        for currency in ['USD', 'EUR', 'GBP']:
            client.post('/api/offers', json={
                'offer_type': 'sell',
                'fiat_currency': currency,
                'min_amount': 50,
                'max_amount': 5000,
                'payment_method': 'bank_transfer',
            }, headers=auth_headers)

        response = client.get('/api/offers?currency=EUR')
        data = response.get_json()
        assert data['total'] == 1
        assert data['offers'][0]['fiat_currency'] == 'EUR'

    def test_filter_by_type(self, client, auth_headers):
        client.post('/api/offers', json={
            'offer_type': 'buy',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)

        response = client.get('/api/offers?type=buy')
        data = response.get_json()
        assert all(o['offer_type'] == 'buy' for o in data['offers'])


class TestOfferManagement:
    """Test offer update and deletion."""

    def test_get_offer_by_id(self, client, auth_headers):
        create_resp = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        offer_id = create_resp.get_json()['offer']['id']

        response = client.get(f'/api/offers/{offer_id}')
        assert response.status_code == 200

    def test_update_offer(self, client, auth_headers):
        create_resp = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        offer_id = create_resp.get_json()['offer']['id']

        response = client.put(f'/api/offers/{offer_id}', json={
            'min_amount': 100,
            'terms': 'Updated terms',
        }, headers=auth_headers)
        assert response.status_code == 200
        assert response.get_json()['offer']['min_amount'] == 100

    def test_delete_offer(self, client, auth_headers):
        create_resp = client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)
        offer_id = create_resp.get_json()['offer']['id']

        response = client.delete(f'/api/offers/{offer_id}', headers=auth_headers)
        assert response.status_code == 200

    def test_list_my_offers(self, client, auth_headers):
        client.post('/api/offers', json={
            'offer_type': 'sell',
            'fiat_currency': 'USD',
            'min_amount': 50,
            'max_amount': 5000,
            'payment_method': 'bank_transfer',
        }, headers=auth_headers)

        response = client.get('/api/offers/my', headers=auth_headers)
        assert response.status_code == 200
        assert len(response.get_json()['offers']) == 1
