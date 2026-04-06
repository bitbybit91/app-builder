import os
import re
import logging
from functools import wraps
from flask import (
    Flask, render_template, request, redirect, url_for,
    session, flash, jsonify, g
)
from flask_session import Session
from flask_bcrypt import Bcrypt

from config import config as app_config
from database import get_db, init_db, init_app as db_init_app
from monero_rpc import MoneroWalletRPC, MoneroRPCError
from coingecko import get_xmr_price, get_xmr_prices

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

bcrypt = Bcrypt()


def create_app(config_name=None):
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    app = Flask(__name__)
    app.config.from_object(app_config[config_name])

    os.makedirs(app.config.get('SESSION_FILE_DIR', 'flask_session'), exist_ok=True)

    if app.config.get('SESSION_TYPE', 'filesystem') != 'null':
        Session(app)

    bcrypt.init_app(app)
    db_init_app(app)

    def get_monero_rpc():
        return MoneroWalletRPC(
            url=app.config['MONERO_RPC_URL'],
            username=app.config.get('MONERO_RPC_USER', ''),
            password=app.config.get('MONERO_RPC_PASS', ''),
        )

    def login_required(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if 'user_id' not in session:
                flash('Please log in to continue.', 'warning')
                return redirect(url_for('login'))
            return f(*args, **kwargs)
        return decorated

    @app.after_request
    def set_security_headers(response):
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['Referrer-Policy'] = 'no-referrer'
        return response

    # ─── Auth Routes ────────────────────────────────────────────────────────────

    @app.route('/')
    def index():
        xmr_price = get_xmr_price('usd', app.config.get('COINGECKO_CACHE_TTL', 300))
        return render_template('index.html', xmr_price=xmr_price)

    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '')
            confirm_password = request.form.get('confirm_password', '')

            if not re.match(r'^[a-zA-Z0-9]{3,20}$', username):
                flash('Username must be 3-20 alphanumeric characters.', 'error')
                return render_template('register.html')
            if len(password) < 8:
                flash('Password must be at least 8 characters.', 'error')
                return render_template('register.html')
            if password != confirm_password:
                flash('Passwords do not match.', 'error')
                return render_template('register.html')

            db = get_db()
            existing = db.execute('SELECT id FROM users WHERE username = ?', (username,)).fetchone()
            if existing:
                flash('Username already taken.', 'error')
                return render_template('register.html')

            password_hash = bcrypt.generate_password_hash(password, rounds=12).decode('utf-8')

            monero_address = ''
            monero_account_index = 0
            try:
                rpc = get_monero_rpc()
                account_info = rpc.create_account(label=username)
                monero_account_index = account_info['account_index']
                monero_address = account_info['address']
            except MoneroRPCError as e:
                logger.warning(f"Monero RPC unavailable during registration: {e}")

            db.execute(
                '''INSERT INTO users (username, password_hash, monero_address, monero_account_index)
                   VALUES (?, ?, ?, ?)''',
                (username, password_hash, monero_address, monero_account_index)
            )
            db.commit()
            flash('Registration successful! Please log in.', 'success')
            return redirect(url_for('login'))

        return render_template('register.html')

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '')

            db = get_db()
            user = db.execute('SELECT * FROM users WHERE username = ?', (username,)).fetchone()

            if not user or not bcrypt.check_password_hash(user['password_hash'], password):
                flash('Invalid username or password.', 'error')
                return render_template('login.html')

            session.clear()
            session['user_id'] = user['id']
            session['username'] = user['username']
            session.permanent = True

            db.execute('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?', (user['id'],))
            db.commit()

            flash(f'Welcome back, {username}!', 'success')
            return redirect(url_for('dashboard'))

        return render_template('login.html')

    @app.route('/logout')
    def logout():
        session.clear()
        flash('You have been logged out.', 'info')
        return redirect(url_for('index'))

    # ─── Dashboard ──────────────────────────────────────────────────────────────

    @app.route('/dashboard')
    @login_required
    def dashboard():
        db = get_db()
        user = db.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()

        balance_confirmed = user['balance_xmr']
        balance_unconfirmed = 0.0
        try:
            rpc = get_monero_rpc()
            bal = rpc.get_balance(account_index=user['monero_account_index'])
            balance_confirmed = bal['unlocked_balance'] / 1e12
            balance_unconfirmed = (bal['balance'] - bal['unlocked_balance']) / 1e12
            db.execute('UPDATE users SET balance_xmr = ? WHERE id = ?', (balance_confirmed, user['id']))
            db.commit()
        except MoneroRPCError as e:
            logger.warning(f"Monero RPC unavailable: {e}")

        xmr_prices = get_xmr_prices(['usd', 'eur', 'gbp'], app.config.get('COINGECKO_CACHE_TTL', 300))
        usd_value = balance_confirmed * xmr_prices.get('usd', 0)

        active_offers = db.execute(
            'SELECT * FROM offers WHERE user_id = ? AND is_active = 1 ORDER BY created_at DESC',
            (session['user_id'],)
        ).fetchall()

        open_trades = db.execute(
            '''SELECT t.*, o.payment_method, o.fiat_currency as offer_fiat,
                      buyer.username as buyer_name, seller.username as seller_name
               FROM trades t
               JOIN offers o ON t.offer_id = o.id
               JOIN users buyer ON t.buyer_id = buyer.id
               JOIN users seller ON t.seller_id = seller.id
               WHERE (t.buyer_id = ? OR t.seller_id = ?)
                 AND t.status NOT IN ('completed', 'cancelled')
               ORDER BY t.created_at DESC''',
            (session['user_id'], session['user_id'])
        ).fetchall()

        return render_template('dashboard.html',
            user=user,
            balance_confirmed=balance_confirmed,
            balance_unconfirmed=balance_unconfirmed,
            xmr_prices=xmr_prices,
            usd_value=usd_value,
            active_offers=active_offers,
            open_trades=open_trades,
        )

    # ─── Offers ─────────────────────────────────────────────────────────────────

    @app.route('/offers')
    def offers():
        db = get_db()
        offer_type = request.args.get('type', '')
        currency = request.args.get('currency', '')
        payment_method = request.args.get('payment_method', '')

        query = '''SELECT o.*, u.username as seller_name
                   FROM offers o JOIN users u ON o.user_id = u.id
                   WHERE o.is_active = 1'''
        params = []
        if offer_type in ('buy', 'sell'):
            query += ' AND o.offer_type = ?'
            params.append(offer_type)
        if currency:
            query += ' AND o.fiat_currency = ?'
            params.append(currency.upper())
        if payment_method:
            query += ' AND o.payment_method LIKE ?'
            params.append(f'%{payment_method}%')
        query += ' ORDER BY o.created_at DESC'

        offer_list = db.execute(query, params).fetchall()

        xmr_price = get_xmr_price('usd', app.config.get('COINGECKO_CACHE_TTL', 300))
        offers_with_price = []
        for offer in offer_list:
            effective_price = xmr_price * (1 + offer['price_margin'] / 100)
            offers_with_price.append({
                'id': offer['id'],
                'user_id': offer['user_id'],
                'seller_name': offer['seller_name'],
                'offer_type': offer['offer_type'],
                'fiat_currency': offer['fiat_currency'],
                'price_margin': offer['price_margin'],
                'min_amount': offer['min_amount'],
                'max_amount': offer['max_amount'],
                'payment_method': offer['payment_method'],
                'terms': offer['terms'],
                'effective_price': round(effective_price, 2),
                'created_at': offer['created_at'],
            })

        return render_template('offers.html',
            offers=offers_with_price,
            xmr_price=xmr_price,
            filter_type=offer_type,
            filter_currency=currency,
            filter_payment=payment_method,
        )

    @app.route('/offers/create', methods=['GET', 'POST'])
    @login_required
    def create_offer():
        if request.method == 'POST':
            offer_type = request.form.get('offer_type', '').strip()
            fiat_currency = request.form.get('fiat_currency', '').strip().upper()
            price_margin_str = request.form.get('price_margin', '0').strip()
            min_amount_str = request.form.get('min_amount', '').strip()
            max_amount_str = request.form.get('max_amount', '').strip()
            payment_method = request.form.get('payment_method', '').strip()
            terms = request.form.get('terms', '').strip()

            if offer_type not in ('buy', 'sell'):
                flash('Offer type must be buy or sell.', 'error')
                return render_template('create_offer.html')
            if not fiat_currency or len(fiat_currency) < 2:
                flash('Please provide a valid fiat currency.', 'error')
                return render_template('create_offer.html')
            if not payment_method:
                flash('Payment method is required.', 'error')
                return render_template('create_offer.html')

            try:
                price_margin = float(price_margin_str)
                min_amount = float(min_amount_str)
                max_amount = float(max_amount_str)
            except ValueError:
                flash('Invalid numeric values.', 'error')
                return render_template('create_offer.html')

            if not (-20 <= price_margin <= 50):
                flash('Price margin must be between -20% and +50%.', 'error')
                return render_template('create_offer.html')
            if min_amount <= 0:
                flash('Minimum amount must be greater than 0.', 'error')
                return render_template('create_offer.html')
            if min_amount >= max_amount:
                flash('Minimum amount must be less than maximum amount.', 'error')
                return render_template('create_offer.html')

            db = get_db()
            db.execute(
                '''INSERT INTO offers
                   (user_id, offer_type, fiat_currency, price_margin, min_amount, max_amount, payment_method, terms)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                (session['user_id'], offer_type, fiat_currency, price_margin,
                 min_amount, max_amount, payment_method, terms)
            )
            db.commit()
            flash('Offer created successfully!', 'success')
            return redirect(url_for('dashboard'))

        return render_template('create_offer.html')

    @app.route('/offers/<int:offer_id>/deactivate', methods=['POST'])
    @login_required
    def deactivate_offer(offer_id):
        db = get_db()
        offer = db.execute('SELECT * FROM offers WHERE id = ?', (offer_id,)).fetchone()
        if not offer:
            flash('Offer not found.', 'error')
            return redirect(url_for('dashboard'))
        if offer['user_id'] != session['user_id']:
            flash('You can only deactivate your own offers.', 'error')
            return redirect(url_for('dashboard'))
        db.execute('UPDATE offers SET is_active = 0 WHERE id = ?', (offer_id,))
        db.commit()
        flash('Offer deactivated.', 'success')
        return redirect(url_for('dashboard'))

    # ─── Trades ─────────────────────────────────────────────────────────────────

    @app.route('/trades/initiate', methods=['POST'])
    @login_required
    def initiate_trade():
        offer_id_str = request.form.get('offer_id', '')
        amount_fiat_str = request.form.get('amount_fiat', '')

        try:
            offer_id = int(offer_id_str)
            amount_fiat = float(amount_fiat_str)
        except ValueError:
            flash('Invalid trade parameters.', 'error')
            return redirect(url_for('offers'))

        db = get_db()
        offer = db.execute('SELECT * FROM offers WHERE id = ? AND is_active = 1', (offer_id,)).fetchone()
        if not offer:
            flash('Offer not found or inactive.', 'error')
            return redirect(url_for('offers'))

        if offer['user_id'] == session['user_id']:
            flash('You cannot trade with your own offer.', 'error')
            return redirect(url_for('offers'))

        if amount_fiat < offer['min_amount'] or amount_fiat > offer['max_amount']:
            flash(f"Amount must be between {offer['min_amount']} and {offer['max_amount']} {offer['fiat_currency']}.", 'error')
            return redirect(url_for('offers'))

        xmr_price = get_xmr_price(offer['fiat_currency'].lower(), app.config.get('COINGECKO_CACHE_TTL', 300))
        effective_price = xmr_price * (1 + offer['price_margin'] / 100) if xmr_price else 0
        amount_xmr = (amount_fiat / effective_price) if effective_price else 0

        if offer['offer_type'] == 'sell':
            buyer_id = session['user_id']
            seller_id = offer['user_id']
        else:
            buyer_id = offer['user_id']
            seller_id = session['user_id']

        cursor = db.execute(
            '''INSERT INTO trades (offer_id, buyer_id, seller_id, amount_xmr, amount_fiat, fiat_currency, status)
               VALUES (?, ?, ?, ?, ?, ?, 'open')''',
            (offer_id, buyer_id, seller_id, amount_xmr, amount_fiat, offer['fiat_currency'])
        )
        trade_id = cursor.lastrowid
        db.commit()
        flash('Trade initiated successfully!', 'success')
        return redirect(url_for('trade_detail', trade_id=trade_id))

    @app.route('/trades/<int:trade_id>')
    @login_required
    def trade_detail(trade_id):
        db = get_db()
        trade = db.execute(
            '''SELECT t.*, o.payment_method, o.terms as offer_terms, o.fiat_currency as offer_fiat,
                      o.offer_type, o.price_margin,
                      buyer.username as buyer_name, seller.username as seller_name
               FROM trades t
               JOIN offers o ON t.offer_id = o.id
               JOIN users buyer ON t.buyer_id = buyer.id
               JOIN users seller ON t.seller_id = seller.id
               WHERE t.id = ?''',
            (trade_id,)
        ).fetchone()

        if not trade:
            flash('Trade not found.', 'error')
            return redirect(url_for('dashboard'))

        if session['user_id'] not in (trade['buyer_id'], trade['seller_id']):
            flash('You are not a participant in this trade.', 'error')
            return redirect(url_for('dashboard'))

        messages = db.execute(
            '''SELECT m.*, u.username as sender_name
               FROM messages m JOIN users u ON m.sender_id = u.id
               WHERE m.trade_id = ?
               ORDER BY m.created_at ASC''',
            (trade_id,)
        ).fetchall()

        return render_template('trade.html', trade=trade, messages=messages,
                               user_id=session['user_id'])

    @app.route('/trades/<int:trade_id>/fund_escrow', methods=['POST'])
    @login_required
    def fund_escrow(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade or trade['status'] != 'open':
            flash('Trade not found or cannot be funded.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] != trade['seller_id']:
            flash('Only the seller can fund escrow.', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))

        escrow_tx_id = request.form.get('escrow_tx_id', '').strip()
        if not escrow_tx_id:
            flash('Escrow transaction ID is required.', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))

        db.execute(
            "UPDATE trades SET status = 'escrow_funded', escrow_tx_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (escrow_tx_id, trade_id)
        )
        db.execute(
            "INSERT INTO transactions (user_id, tx_type, amount_xmr, tx_hash, status) VALUES (?, 'escrow_lock', ?, ?, 'confirmed')",
            (trade['seller_id'], trade['amount_xmr'], escrow_tx_id)
        )
        db.commit()
        flash('Escrow funded successfully!', 'success')
        return redirect(url_for('trade_detail', trade_id=trade_id))

    @app.route('/trades/<int:trade_id>/mark_fiat_sent', methods=['POST'])
    @login_required
    def mark_fiat_sent(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade or trade['status'] != 'escrow_funded':
            flash('Trade not found or not in correct state.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] != trade['buyer_id']:
            flash('Only the buyer can mark fiat as sent.', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))

        db.execute(
            "UPDATE trades SET status = 'fiat_sent', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (trade_id,)
        )
        db.commit()
        flash('Fiat payment marked as sent.', 'success')
        return redirect(url_for('trade_detail', trade_id=trade_id))

    @app.route('/trades/<int:trade_id>/complete', methods=['POST'])
    @login_required
    def complete_trade(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade or trade['status'] != 'fiat_sent':
            flash('Trade not found or not in correct state.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] != trade['seller_id']:
            flash('Only the seller can complete the trade.', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))

        release_tx_id = ''
        try:
            db_conn = get_db()
            buyer = db_conn.execute('SELECT * FROM users WHERE id = ?', (trade['buyer_id'],)).fetchone()
            if buyer and buyer['monero_address']:
                rpc = get_monero_rpc()
                seller = db_conn.execute('SELECT * FROM users WHERE id = ?', (trade['seller_id'],)).fetchone()
                result = rpc.transfer(
                    amount_xmr=trade['amount_xmr'],
                    address=buyer['monero_address'],
                    account_index=seller['monero_account_index'] if seller else 0,
                )
                release_tx_id = result.get('tx_hash', '')
        except MoneroRPCError as e:
            logger.warning(f"Monero RPC unavailable during trade completion: {e}")

        db.execute(
            "UPDATE trades SET status = 'completed', release_tx_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (release_tx_id, trade_id)
        )
        if release_tx_id:
            db.execute(
                "INSERT INTO transactions (user_id, tx_type, amount_xmr, tx_hash, status) VALUES (?, 'escrow_release', ?, ?, 'confirmed')",
                (trade['buyer_id'], trade['amount_xmr'], release_tx_id)
            )
        db.commit()
        flash('Trade completed successfully!', 'success')
        return redirect(url_for('trade_detail', trade_id=trade_id))

    @app.route('/trades/<int:trade_id>/dispute', methods=['POST'])
    @login_required
    def dispute_trade(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade or trade['status'] not in ('escrow_funded', 'fiat_sent'):
            flash('Trade cannot be disputed in its current state.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] not in (trade['buyer_id'], trade['seller_id']):
            flash('You are not a participant in this trade.', 'error')
            return redirect(url_for('dashboard'))

        db.execute(
            "UPDATE trades SET status = 'disputed', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (trade_id,)
        )
        db.commit()
        flash('Trade has been disputed. An admin will review the case.', 'warning')
        return redirect(url_for('trade_detail', trade_id=trade_id))

    @app.route('/trades/<int:trade_id>/cancel', methods=['POST'])
    @login_required
    def cancel_trade(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade or trade['status'] not in ('open',):
            flash('Trade cannot be cancelled in its current state.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] not in (trade['buyer_id'], trade['seller_id']):
            flash('You are not a participant in this trade.', 'error')
            return redirect(url_for('dashboard'))

        db.execute(
            "UPDATE trades SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (trade_id,)
        )
        db.commit()
        flash('Trade cancelled.', 'info')
        return redirect(url_for('dashboard'))

    @app.route('/trades/<int:trade_id>/chat', methods=['POST'])
    @login_required
    def send_message(trade_id):
        db = get_db()
        trade = db.execute('SELECT * FROM trades WHERE id = ?', (trade_id,)).fetchone()
        if not trade:
            flash('Trade not found.', 'error')
            return redirect(url_for('dashboard'))
        if session['user_id'] not in (trade['buyer_id'], trade['seller_id']):
            flash('You are not a participant in this trade.', 'error')
            return redirect(url_for('dashboard'))

        message_text = request.form.get('message_text', '').strip()
        if not message_text:
            flash('Message cannot be empty.', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))
        if len(message_text) > 2000:
            flash('Message too long (max 2000 characters).', 'error')
            return redirect(url_for('trade_detail', trade_id=trade_id))

        db.execute(
            'INSERT INTO messages (trade_id, sender_id, message_text) VALUES (?, ?, ?)',
            (trade_id, session['user_id'], message_text)
        )
        db.commit()
        return redirect(url_for('trade_detail', trade_id=trade_id))

    # ─── Wallet ─────────────────────────────────────────────────────────────────

    @app.route('/wallet')
    @login_required
    def wallet():
        db = get_db()
        user = db.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()

        balance_confirmed = user['balance_xmr']
        balance_unconfirmed = 0.0
        try:
            rpc = get_monero_rpc()
            bal = rpc.get_balance(account_index=user['monero_account_index'])
            balance_confirmed = bal['unlocked_balance'] / 1e12
            balance_unconfirmed = (bal['balance'] - bal['unlocked_balance']) / 1e12
            db.execute('UPDATE users SET balance_xmr = ? WHERE id = ?', (balance_confirmed, user['id']))
            db.commit()
        except MoneroRPCError as e:
            logger.warning(f"Monero RPC unavailable: {e}")

        transactions = db.execute(
            'SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
            (session['user_id'],)
        ).fetchall()

        xmr_price = get_xmr_price('usd', app.config.get('COINGECKO_CACHE_TTL', 300))

        return render_template('wallet.html',
            user=user,
            balance_confirmed=balance_confirmed,
            balance_unconfirmed=balance_unconfirmed,
            transactions=transactions,
            xmr_price=xmr_price,
        )

    @app.route('/wallet/deposit', methods=['POST'])
    @login_required
    def wallet_deposit():
        db = get_db()
        user = db.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()

        deposit_address = user['monero_address']
        if not deposit_address:
            try:
                rpc = get_monero_rpc()
                deposit_address = rpc.get_address(account_index=user['monero_account_index'])
                db.execute('UPDATE users SET monero_address = ? WHERE id = ?', (deposit_address, user['id']))
                db.commit()
            except MoneroRPCError as e:
                logger.warning(f"Monero RPC unavailable: {e}")
                flash('Could not retrieve deposit address. Please try again later.', 'error')
                return redirect(url_for('wallet'))

        flash(f'Your deposit address: {deposit_address}', 'info')
        return redirect(url_for('wallet'))

    @app.route('/wallet/withdraw', methods=['POST'])
    @login_required
    def wallet_withdraw():
        address = request.form.get('address', '').strip()
        amount_str = request.form.get('amount', '').strip()

        if not address:
            flash('Withdrawal address is required.', 'error')
            return redirect(url_for('wallet'))

        try:
            amount = float(amount_str)
        except ValueError:
            flash('Invalid withdrawal amount.', 'error')
            return redirect(url_for('wallet'))

        if amount <= 0:
            flash('Withdrawal amount must be positive.', 'error')
            return redirect(url_for('wallet'))

        db = get_db()
        user = db.execute('SELECT * FROM users WHERE id = ?', (session['user_id'],)).fetchone()

        if user['balance_xmr'] < amount:
            flash('Insufficient balance.', 'error')
            return redirect(url_for('wallet'))

        tx_hash = ''
        try:
            rpc = get_monero_rpc()
            result = rpc.transfer(
                amount_xmr=amount,
                address=address,
                account_index=user['monero_account_index'],
            )
            tx_hash = result.get('tx_hash', '')
            new_balance = user['balance_xmr'] - amount
            db.execute('UPDATE users SET balance_xmr = ? WHERE id = ?', (new_balance, user['id']))
            db.execute(
                "INSERT INTO transactions (user_id, tx_type, amount_xmr, tx_hash, monero_address, status) VALUES (?, 'withdrawal', ?, ?, ?, 'confirmed')",
                (user['id'], amount, tx_hash, address)
            )
            db.commit()
            flash(f'Withdrawal successful! TX: {tx_hash}', 'success')
        except MoneroRPCError as e:
            db.execute(
                "INSERT INTO transactions (user_id, tx_type, amount_xmr, monero_address, status) VALUES (?, 'withdrawal', ?, ?, 'failed')",
                (user['id'], amount, address)
            )
            db.commit()
            flash(f'Withdrawal failed: {e}', 'error')

        return redirect(url_for('wallet'))

    @app.errorhandler(404)
    def not_found(e):
        return render_template('base.html'), 404

    @app.errorhandler(500)
    def server_error(e):
        return render_template('base.html'), 500

    return app


if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        init_db()
    app.run(host='0.0.0.0', port=8000)
