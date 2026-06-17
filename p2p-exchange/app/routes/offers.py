import bleach
from flask import Blueprint, request, jsonify
from app import db
from app.models.offer import Offer
from app.routes.auth import get_current_user

offers_bp = Blueprint('offers', __name__)

ALLOWED_FIAT = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'KRW', 'INR', 'BRL', 'MXN', 'CAD', 'AUD', 'CHF', 'SEK', 'NOK', 'DKK', 'PLN', 'CZK', 'HUF', 'RON', 'BGN', 'HRK', 'RSD', 'UAH', 'RUB', 'TRY', 'ZAR', 'NGN', 'GHS', 'KES', 'TZS', 'UGX', 'VND', 'THB', 'IDR', 'PHP', 'MYR', 'SGD', 'HKD', 'TWD', 'AED', 'SAR', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'ILS', 'EGP', 'MAD', 'TND', 'DZD', 'LYD', 'XOF', 'XAF', 'ETB', 'OTHER']

@offers_bp.route('', methods=['GET'])
def list_offers():
    page = request.args.get('page', 1, type=int)
    per_page = min(request.args.get('per_page', 20, type=int), 100)
    offer_type = request.args.get('type')
    fiat_currency = request.args.get('fiat_currency')
    payment_method = request.args.get('payment_method')
    country = request.args.get('country')
    sort_by = request.args.get('sort', 'created_at')
    
    query = Offer.query.filter_by(is_active=True)
    if offer_type in ['buy', 'sell']:
        query = query.filter_by(type=offer_type)
    if fiat_currency:
        query = query.filter_by(fiat_currency=fiat_currency.upper())
    if payment_method:
        query = query.filter(Offer.payment_method.ilike(f'%{payment_method}%'))
    if country:
        query = query.filter(Offer.country.ilike(f'%{country}%'))
    
    if sort_by == 'price':
        query = query.order_by(Offer.price.asc())
    else:
        query = query.order_by(Offer.created_at.desc())
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    return jsonify({
        'offers': [o.to_dict() for o in pagination.items],
        'total': pagination.total,
        'page': page,
        'pages': pagination.pages,
        'per_page': per_page,
    })

@offers_bp.route('/<int:offer_id>', methods=['GET'])
def get_offer(offer_id):
    offer = Offer.query.get_or_404(offer_id)
    return jsonify(offer.to_dict())

@offers_bp.route('', methods=['POST'])
def create_offer():
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    data = request.get_json() or {}
    required = ['type', 'fiat_currency', 'payment_method', 'min_amount', 'max_amount']
    for field in required:
        if field not in data:
            return jsonify({'error': f'{field} is required'}), 400
    if data['type'] not in ['buy', 'sell']:
        return jsonify({'error': 'type must be buy or sell'}), 400
    if data.get('min_amount', 0) <= 0 or data.get('max_amount', 0) <= 0:
        return jsonify({'error': 'amounts must be positive'}), 400
    if data['min_amount'] > data['max_amount']:
        return jsonify({'error': 'min_amount must be <= max_amount'}), 400
    terms = bleach.clean(data.get('terms', ''), strip=True)[:2000]
    offer = Offer(
        user_id=user.id,
        type=data['type'],
        fiat_currency=data['fiat_currency'].upper()[:10],
        payment_method=bleach.clean(data['payment_method'], strip=True)[:100],
        price_type=data.get('price_type', 'market'),
        price=data.get('price'),
        margin_percent=data.get('margin_percent', 0.0),
        min_amount=float(data['min_amount']),
        max_amount=float(data['max_amount']),
        terms=terms,
        country=bleach.clean(data.get('country', ''), strip=True)[:100],
    )
    db.session.add(offer)
    db.session.commit()
    return jsonify(offer.to_dict()), 201

@offers_bp.route('/<int:offer_id>', methods=['PUT'])
def update_offer(offer_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    offer = Offer.query.get_or_404(offer_id)
    if offer.user_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    data = request.get_json() or {}
    if 'payment_method' in data:
        offer.payment_method = bleach.clean(data['payment_method'], strip=True)[:100]
    if 'price_type' in data:
        offer.price_type = data['price_type']
    if 'price' in data:
        offer.price = data['price']
    if 'margin_percent' in data:
        offer.margin_percent = data['margin_percent']
    if 'min_amount' in data:
        offer.min_amount = float(data['min_amount'])
    if 'max_amount' in data:
        offer.max_amount = float(data['max_amount'])
    if 'terms' in data:
        offer.terms = bleach.clean(data['terms'], strip=True)[:2000]
    if 'country' in data:
        offer.country = bleach.clean(data['country'], strip=True)[:100]
    if 'is_active' in data:
        offer.is_active = bool(data['is_active'])
    db.session.commit()
    return jsonify(offer.to_dict())

@offers_bp.route('/<int:offer_id>', methods=['DELETE'])
def delete_offer(offer_id):
    user = get_current_user()
    if not user:
        return jsonify({'error': 'Authentication required'}), 401
    offer = Offer.query.get_or_404(offer_id)
    if offer.user_id != user.id:
        return jsonify({'error': 'Forbidden'}), 403
    offer.is_active = False
    db.session.commit()
    return jsonify({'success': True, 'message': 'Offer deactivated'})
