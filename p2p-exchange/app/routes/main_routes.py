"""
Main Routes
============
Serves HTML pages (frontend templates).
"""

from flask import Blueprint, render_template, redirect, url_for

main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    """Landing page."""
    return render_template('index.html')


@main_bp.route('/offers')
def offers_page():
    """Offers listing page."""
    return render_template('offers.html')


@main_bp.route('/offers/create')
def create_offer_page():
    """Create offer page."""
    return render_template('create_offer.html')


@main_bp.route('/trade/<trade_id>')
def trade_page(trade_id):
    """Active trade page with chat."""
    return render_template('trade.html', trade_id=trade_id)


@main_bp.route('/chat/<trade_id>')
def chat_page(trade_id):
    """Standalone chat page for a trade."""
    return render_template('chat.html', trade_id=trade_id)


@main_bp.route('/profile/<nickname>')
def profile_page(nickname):
    """Public trader profile page."""
    return render_template('profile.html', nickname=nickname)


@main_bp.route('/wallet')
def wallet_page():
    """Wallet page — balances, deposit, withdraw."""
    return render_template('wallet.html')


@main_bp.route('/about')
def about_page():
    """About / FAQ page."""
    return render_template('about.html')
