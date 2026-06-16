/* =============================================================================
   P2P Exchange — Client-Side JavaScript
   No external dependencies. Tor-friendly. Vanilla JS only.
   ============================================================================= */

'use strict';

// ---------------------------------------------------------------------------
// Session Management
// ---------------------------------------------------------------------------

/**
 * Get stored session token from localStorage.
 * @returns {string|null}
 */
function getSessionToken() {
    return localStorage.getItem('session_token');
}

/**
 * Get stored user ID from localStorage.
 * @returns {string|null}
 */
function getUserId() {
    return localStorage.getItem('user_id');
}

/**
 * Get stored nickname from localStorage.
 * @returns {string|null}
 */
function getNickname() {
    return localStorage.getItem('nickname');
}

/**
 * Store session data in localStorage.
 * @param {string} token - Session token.
 * @param {Object} user - User object with id and nickname.
 */
function saveSession(token, user) {
    localStorage.setItem('session_token', token);
    localStorage.setItem('user_id', user.id);
    localStorage.setItem('nickname', user.nickname);
}

/**
 * Clear session data.
 */
function clearSession() {
    localStorage.removeItem('session_token');
    localStorage.removeItem('user_id');
    localStorage.removeItem('nickname');
}

/**
 * Create a new anonymous session.
 */
function createSession() {
    var nickname = prompt('Choose a nickname (leave blank for random):');
    var body = {};
    if (nickname && nickname.trim()) {
        body.nickname = nickname.trim();
    }

    api('/api/auth/session', {
        method: 'POST',
        body: JSON.stringify(body),
    })
    .then(function(data) {
        saveSession(data.session_token, data.user);
        // Store encryption keypair (in production: use IndexedDB or secure storage)
        if (data.encryption_keypair) {
            localStorage.setItem('enc_pubkey', data.encryption_keypair.public_key);
            localStorage.setItem('enc_privkey', data.encryption_keypair.private_key);
        }
        updateNavbar();
        alert('Session created! You are: ' + data.user.nickname);
    })
    .catch(function(err) {
        alert('Error: ' + (err.message || 'Failed to create session'));
    });
}

// ---------------------------------------------------------------------------
// API Helper
// ---------------------------------------------------------------------------

/**
 * Make an API request with session token in Authorization header.
 * @param {string} url - API endpoint URL.
 * @param {Object} [options] - Fetch options (method, body, headers, etc.).
 * @returns {Promise<Object>} Parsed JSON response.
 */
function api(url, options) {
    options = options || {};
    var headers = options.headers || {};
    headers['Content-Type'] = headers['Content-Type'] || 'application/json';

    var token = getSessionToken();
    if (token) {
        headers['Authorization'] = 'Bearer ' + token;
    }

    options.headers = headers;

    return fetch(url, options)
        .then(function(response) {
            return response.json().then(function(data) {
                if (!response.ok) {
                    var err = new Error(data.error || 'Request failed');
                    err.status = response.status;
                    throw err;
                }
                return data;
            });
        });
}

// ---------------------------------------------------------------------------
// Render Helpers
// ---------------------------------------------------------------------------

/**
 * Render an offer card HTML.
 * @param {Object} o - Offer object from API.
 * @returns {string} HTML string.
 */
function renderOfferCard(o) {
    var typeClass = o.offer_type === 'buy' ? 'offer-type-buy' : 'offer-type-sell';
    var typeLabel = o.offer_type === 'buy' ? 'BUYING' : 'SELLING';
    var priceInfo = o.price_type === 'fixed'
        ? o.fixed_price + ' ' + o.fiat_currency
        : (o.price_margin >= 0 ? '+' : '') + o.price_margin + '% market';

    return '<div class="offer-card">' +
        '<div class="offer-info">' +
            '<h3>' +
                '<span class="offer-type ' + typeClass + '">' + typeLabel + '</span> ' +
                'XMR for ' + o.fiat_currency +
            '</h3>' +
            '<div class="offer-meta">' +
                '<span>💰 ' + priceInfo + '</span>' +
                '<span>📊 ' + o.min_amount + ' – ' + o.max_amount + ' ' + o.fiat_currency + '</span>' +
                '<span>💳 ' + (o.payment_method || '').replace(/_/g, ' ') + '</span>' +
                '<span>👤 ' + (o.user_nickname || 'Anon') +
                    ' (⭐' + (o.user_trust_score || 0) + ', ' + (o.user_trade_count || 0) + ' trades)</span>' +
            '</div>' +
        '</div>' +
        '<div class="offer-actions">' +
            '<a href="/trade/' + o.id + '" class="btn btn-primary btn-sm" onclick="initiateTrade(\'' + o.id + '\', event)">Trade</a>' +
        '</div>' +
    '</div>';
}

/**
 * Initiate a trade from an offer card.
 * @param {string} offerId - Offer ID.
 * @param {Event} e - Click event.
 */
function initiateTrade(offerId, e) {
    e.preventDefault();

    if (!getSessionToken()) {
        alert('You need to start a session first.');
        return;
    }

    var amount = prompt('Enter fiat amount for this trade:');
    if (!amount) return;

    var xmrAmount = prompt('Enter XMR amount:');
    if (!xmrAmount) return;

    var walletAddr = prompt('Enter your XMR wallet address (to receive XMR):');

    api('/api/trades', {
        method: 'POST',
        body: JSON.stringify({
            offer_id: offerId,
            crypto_amount: parseFloat(xmrAmount),
            fiat_amount: parseFloat(amount),
            buyer_wallet_address: walletAddr || '',
        }),
    })
    .then(function(data) {
        window.location.href = '/trade/' + data.trade.id;
    })
    .catch(function(err) {
        alert('Error: ' + (err.message || 'Failed to initiate trade'));
    });
}

// ---------------------------------------------------------------------------
// Navbar
// ---------------------------------------------------------------------------

/**
 * Update navbar based on session state.
 */
function updateNavbar() {
    var navUser = document.getElementById('navUser');
    var navLogin = document.getElementById('navLogin');
    var navNickname = document.getElementById('navNickname');

    if (getSessionToken() && getNickname()) {
        if (navUser) navUser.style.display = '';
        if (navLogin) navLogin.style.display = 'none';
        if (navNickname) navNickname.textContent = '👤 ' + getNickname();
    } else {
        if (navUser) navUser.style.display = 'none';
        if (navLogin) navLogin.style.display = '';
    }
}

// ---------------------------------------------------------------------------
// Mobile Nav Toggle
// ---------------------------------------------------------------------------

document.addEventListener('DOMContentLoaded', function() {
    var toggle = document.getElementById('navToggle');
    var links = document.getElementById('navLinks');
    if (toggle && links) {
        toggle.addEventListener('click', function() {
            links.classList.toggle('active');
        });
    }

    updateNavbar();
});
