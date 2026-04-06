from flask import Blueprint, render_template

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    return render_template('index.html')

@main_bp.route('/offers')
def offers():
    return render_template('offers.html')

@main_bp.route('/create-offer')
def create_offer():
    return render_template('create_offer.html')

@main_bp.route('/trade/<int:trade_id>')
def trade(trade_id):
    return render_template('trade.html', trade_id=trade_id)

@main_bp.route('/chat/<int:trade_id>')
def chat(trade_id):
    return render_template('chat.html', trade_id=trade_id)

@main_bp.route('/wallet')
def wallet():
    return render_template('wallet.html')

@main_bp.route('/profile/<int:user_id>')
def profile(user_id):
    return render_template('profile.html', user_id=user_id)

@main_bp.route('/about')
def about():
    return render_template('about.html')
