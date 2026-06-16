"""
Offers Routes
==============
CRUD operations for buy/sell offers.
"""

import logging

import bleach
from flask import Blueprint, request, jsonify
from app import db, limiter
from app.models.offer import Offer
from app.routes.auth import get_current_user

logger = logging.getLogger(__name__)

offers_bp = Blueprint('offers', __name__)

# Allowed payment methods
PAYMENT_METHODS = [
    'bank_transfer', 'cash_deposit', 'cash_in_person',
    'paypal', 'revolut', 'wise', 'zelle', 'venmo',
    'gift_card', 'crypto', 'other',
]


@offers_bp.route('', methods=['GET'])
@limiter.limit('200/hour')
def list_offers():
    """
    List offers with filtering and pagination.

    Query params:
        type: 'buy' or 'sell'
        currency: Fiat currency code (e.g., 'USD')
        payment_method: Payment method filter
        country: Country code
        trade_type: 'online' or 'local'
        page: Page number (default 1)
        per_page: Results per page (default 20, max 100)
        sort: 'newest', 'price_asc', 'price_desc', 'trust' (default 'newest')
    """
    query = Offer.query.filter_by(is_active=True)

    # Filters
    offer_type = request.args.get('type')
    if offer_type in ('buy', 'sell'):
        query = query.filter_by(offer_type=offer_type)

    currency = request.args.get('currency')
    if currency:
        query = query.filter_by(fiat_currency=currency.upper())

    payment_method = request.args.get('payment_method')
    if payment_method:
        query = query.filter_by(payment_method=payment_method)

    country = request.args.get('country')
    if country:
        query = query.filter_by(country=country.upper())

    trade_type = request.args.get('trade_type')
    if trade_type in ('online', 'local'):
        query = query.filter_by(trade_type=trade_type)

    # Sorting
    sort = request.args.get('sort', 'newest')
    if sort == 'price_asc':
        query = query.order_by(Offer.price_margin.asc())
    elif sort == 'price_desc':
        query = query.order_by(Offer.price_margin.desc())
    elif sort == 'trust':
        query = query.join(Offer.user).order_by(db.desc('trust_score'))
    else:
        query = query.order_by(Offer.created_at.desc())

    # Pagination
    page = max(1, request.args.get('page', 1, type=int))
    per_page = min(100, max(1, request.args.get('per_page', 20, type=int)))

    pagination = query.paginate(page=page, per_page=per_page, error_out=False)

    return jsonify({
        'offers': [o.to_dict() for o in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages,
        'has_next': pagination.has_next,
    }), 200


@offers_bp.route('', methods=['POST'])
@limiter.limit('20/hour')
def create_offer():
    """
    Create a new buy/sell offer.

    Request body:
        {
            "offer_type": "buy" | "sell",
            "fiat_currency": "USD",
            "price_type": "market" | "fixed",
            "price_margin": 5.0,
            "fixed_price": null,
            "min_amount": 50,
            "max_amount": 5000,
            "payment_method": "bank_transfer",
            "payment_details": "...",
            "terms": "...",
            "trade_time_limit": 60,
            "country": "US",
            "location": "New York",
            "trade_type": "online"
        }
    """
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    data = request.get_json(silent=True) or {}

    # Validate required fields
    required = ['offer_type', 'fiat_currency', 'min_amount', 'max_amount', 'payment_method']
    for field in required:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400

    if data['offer_type'] not in ('buy', 'sell'):
        return jsonify({'error': 'offer_type must be "buy" or "sell"'}), 400

    if data['payment_method'] not in PAYMENT_METHODS:
        return jsonify({'error': f'Invalid payment method. Allowed: {PAYMENT_METHODS}'}), 400

    min_amount = float(data.get('min_amount', 0))
    max_amount = float(data.get('max_amount', 0))
    if min_amount <= 0 or max_amount <= 0 or min_amount > max_amount:
        return jsonify({'error': 'Invalid amount range'}), 400

    # Sanitize text fields
    terms = bleach.clean(data.get('terms', ''), strip=True)
    payment_details = bleach.clean(data.get('payment_details', ''), strip=True)

    offer = Offer(
        user_id=user.id,
        offer_type=data['offer_type'],
        fiat_currency=data['fiat_currency'].upper(),
        price_type=data.get('price_type', 'market'),
        price_margin=float(data.get('price_margin', 0)),
        fixed_price=float(data['fixed_price']) if data.get('fixed_price') else None,
        min_amount=min_amount,
        max_amount=max_amount,
        payment_method=data['payment_method'],
        payment_details=payment_details,
        terms=terms,
        trade_time_limit=int(data.get('trade_time_limit', 60)),
        country=data.get('country', '').upper()[:4] if data.get('country') else None,
        location=bleach.clean(data.get('location', ''), strip=True) or None,
        trade_type=data.get('trade_type', 'online'),
    )

    db.session.add(offer)
    db.session.commit()

    logger.info('Offer created: %s %s by %s', offer.offer_type, offer.id[:8], user.nickname)

    return jsonify({'offer': offer.to_dict()}), 201


@offers_bp.route('/<offer_id>', methods=['GET'])
@limiter.limit('200/hour')
def get_offer(offer_id):
    """Get a single offer by ID."""
    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({'error': 'Offer not found'}), 404

    return jsonify({'offer': offer.to_dict()}), 200


@offers_bp.route('/<offer_id>', methods=['PUT'])
@limiter.limit('20/hour')
def update_offer(offer_id):
    """Update an offer (owner only)."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({'error': 'Offer not found'}), 404

    if offer.user_id != user.id:
        return jsonify({'error': 'Not authorized'}), 403

    data = request.get_json(silent=True) or {}

    # Update allowed fields
    if 'min_amount' in data:
        offer.min_amount = float(data['min_amount'])
    if 'max_amount' in data:
        offer.max_amount = float(data['max_amount'])
    if 'price_margin' in data:
        offer.price_margin = float(data['price_margin'])
    if 'fixed_price' in data:
        offer.fixed_price = float(data['fixed_price']) if data['fixed_price'] else None
    if 'terms' in data:
        offer.terms = bleach.clean(data['terms'], strip=True)
    if 'payment_details' in data:
        offer.payment_details = bleach.clean(data['payment_details'], strip=True)
    if 'is_active' in data:
        offer.is_active = bool(data['is_active'])
    if 'trade_time_limit' in data:
        offer.trade_time_limit = int(data['trade_time_limit'])

    db.session.commit()

    return jsonify({'offer': offer.to_dict()}), 200


@offers_bp.route('/<offer_id>', methods=['DELETE'])
@limiter.limit('20/hour')
def delete_offer(offer_id):
    """Deactivate an offer (owner only)."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    offer = Offer.query.get(offer_id)
    if not offer:
        return jsonify({'error': 'Offer not found'}), 404

    if offer.user_id != user.id:
        return jsonify({'error': 'Not authorized'}), 403

    offer.is_active = False
    db.session.commit()

    return jsonify({'message': 'Offer deactivated'}), 200


@offers_bp.route('/my', methods=['GET'])
@limiter.limit('100/hour')
def my_offers():
    """Get offers created by the current user."""
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401

    offers = Offer.query.filter_by(user_id=user.id).order_by(Offer.created_at.desc()).all()
    return jsonify({'offers': [o.to_dict() for o in offers]}), 200


@offers_bp.route('/payment-methods', methods=['GET'])
def list_payment_methods():
    """List available payment methods."""
    return jsonify({'payment_methods': PAYMENT_METHODS}), 200
