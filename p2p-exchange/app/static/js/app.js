/**
 * P2P XMR Exchange - Client Application
 * No external dependencies. Tor-compatible.
 */

var App = (function() {
    'use strict';

    // Session management
    var session = {
        get: function() {
            try {
                var s = localStorage.getItem('p2p_session');
                return s ? JSON.parse(s) : null;
            } catch(e) { return null; }
        },
        set: function(data) {
            localStorage.setItem('p2p_session', JSON.stringify(data));
        },
        clear: function() {
            localStorage.removeItem('p2p_session');
        },
        getToken: function() {
            var s = this.get();
            return s ? s.token : null;
        }
    };

    // API request helper
    function apiRequest(method, path, data) {
        return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.open(method, '/api' + path, true);
            xhr.setRequestHeader('Content-Type', 'application/json');
            var token = session.getToken();
            if (token) xhr.setRequestHeader('X-Session-Token', token);
            xhr.onload = function() {
                try {
                    var result = JSON.parse(xhr.responseText);
                    if (xhr.status >= 200 && xhr.status < 300) {
                        resolve(result);
                    } else {
                        var err = new Error(result.error || 'Request failed');
                        err.status = xhr.status;
                        err.data = result;
                        reject(err);
                    }
                } catch(e) {
                    reject(new Error('Invalid JSON response'));
                }
            };
            xhr.onerror = function() { reject(new Error('Network error')); };
            xhr.send(data ? JSON.stringify(data) : null);
        });
    }

    // API methods
    var api = {
        // Auth
        createSession: function(publicKey, displayName) {
            return apiRequest('POST', '/auth/session', {public_key: publicKey, display_name: displayName});
        },
        verifySession: function() {
            return apiRequest('GET', '/auth/verify');
        },
        generateMnemonic: function() {
            return apiRequest('GET', '/auth/mnemonic/generate');
        },
        recoverFromMnemonic: function(mnemonic) {
            return apiRequest('POST', '/auth/mnemonic/recover', {mnemonic: mnemonic});
        },
        logout: function() {
            return apiRequest('POST', '/auth/logout');
        },

        // Offers
        getOffers: function(params) {
            var qs = params ? '?' + Object.keys(params).filter(function(k) {
                return params[k] !== '' && params[k] !== undefined;
            }).map(function(k) {
                return k + '=' + encodeURIComponent(params[k]);
            }).join('&') : '';
            return apiRequest('GET', '/offers' + qs);
        },
        getOffer: function(id) {
            return apiRequest('GET', '/offers/' + id);
        },
        createOffer: function(data) {
            return apiRequest('POST', '/offers', data);
        },
        updateOffer: function(id, data) {
            return apiRequest('PUT', '/offers/' + id, data);
        },
        deleteOffer: function(id) {
            return apiRequest('DELETE', '/offers/' + id);
        },

        // Trades
        getTrades: function() {
            return apiRequest('GET', '/trades');
        },
        getTrade: function(id) {
            return apiRequest('GET', '/trades/' + id);
        },
        initiateTrade: function(offerId, amountXmr, amountFiat) {
            return apiRequest('POST', '/trades', {offer_id: offerId, amount_xmr: amountXmr, amount_fiat: amountFiat});
        },
        confirmEscrow: function(id, txid) {
            return apiRequest('POST', '/trades/' + id + '/confirm_escrow', {txid: txid});
        },
        fiatSent: function(id) {
            return apiRequest('POST', '/trades/' + id + '/fiat_sent');
        },
        fiatReceived: function(id) {
            return apiRequest('POST', '/trades/' + id + '/fiat_received');
        },
        completeTrade: function(id) {
            return apiRequest('POST', '/trades/' + id + '/complete');
        },
        cancelTrade: function(id) {
            return apiRequest('POST', '/trades/' + id + '/cancel');
        },
        openDispute: function(id, reason) {
            return apiRequest('POST', '/trades/' + id + '/dispute', {reason: reason});
        },

        // Chat
        getMessages: function(tradeId, sinceId) {
            return apiRequest('GET', '/chat/trade/' + tradeId + (sinceId ? '?since_id=' + sinceId : ''));
        },
        sendMessage: function(tradeId, encryptedContent, nonce, ephemeralKey) {
            return apiRequest('POST', '/chat/trade/' + tradeId, {
                encrypted_content: encryptedContent,
                nonce: nonce,
                ephemeral_public_key: ephemeralKey
            });
        },

        // Wallet
        getBalance: function() {
            return apiRequest('GET', '/wallet/balance');
        },
        getDepositAddress: function() {
            return apiRequest('POST', '/wallet/deposit');
        },
        withdraw: function(address, amountXmr) {
            return apiRequest('POST', '/wallet/withdraw', {address: address, amount_xmr: amountXmr});
        },
        getTransactions: function() {
            return apiRequest('GET', '/wallet/transactions');
        },
        getNetworkStatus: function() {
            return apiRequest('GET', '/wallet/status');
        },

        // User
        getUser: function(id) {
            return apiRequest('GET', '/auth/user/' + id);
        }
    };

    // Render helpers
    var render = {
        offerCard: function(offer) {
            var typeLabel = offer.type === 'sell' ? 'Sell XMR' : 'Buy XMR';
            var typeCls   = offer.type === 'sell' ? 'offer-sell' : 'offer-buy';
            var price     = offer.price_type === 'fixed'
                ? offer.price + ' ' + offer.fiat_currency + '/XMR'
                : 'Market ' + (offer.margin_percent >= 0 ? '+' : '') + offer.margin_percent + '%';
            return '<div class="offer-card ' + typeCls + '">' +
                '<div class="offer-header">' +
                '<span class="offer-type-badge">' + typeLabel + '</span>' +
                '<span class="offer-currency">' + offer.fiat_currency + '</span>' +
                '</div>' +
                '<div class="offer-payment">' + (offer.payment_method || '') + '</div>' +
                '<div class="offer-price">' + price + '</div>' +
                '<div class="offer-limits">' + offer.min_amount + ' \u2013 ' + offer.max_amount + ' ' + offer.fiat_currency + '</div>' +
                (offer.country ? '<div class="offer-country">\uD83D\uDCCD ' + offer.country + '</div>' : '') +
                '<div class="offer-actions">' +
                '<a href="#" class="btn btn-primary btn-sm" onclick="App.tradeOffer(' + offer.id + ', event)">Trade</a>' +
                '<a href="/profile/' + offer.user_id + '" class="btn btn-secondary btn-sm">Profile</a>' +
                '</div>' +
                '</div>';
        }
    };

    // Chat with simple encoding placeholder (client-side)
    // For real E2E encryption, integrate TweetNaCl.js on the page.
    var chat = {
        sendEncrypted: function(tradeId, plaintext) {
            var encoded = btoa(unescape(encodeURIComponent(plaintext)));
            var randomBytes = function(n) {
                return Array.from(crypto.getRandomValues(new Uint8Array(n)))
                    .map(function(b) { return String.fromCharCode(b); }).join('');
            };
            var nonce    = btoa(randomBytes(24));
            var ephKey   = btoa(randomBytes(32));
            return api.sendMessage(tradeId, encoded, nonce, ephKey);
        }
    };

    // Flash messages
    function flash(message, type) {
        var container = document.getElementById('flash-messages');
        if (!container) return;
        var div = document.createElement('div');
        div.className = 'flash flash-' + (type || 'info');
        div.textContent = message;
        var btn = document.createElement('button');
        btn.className = 'flash-close';
        btn.textContent = '\xD7';
        btn.onclick = function() { div.remove(); };
        div.appendChild(btn);
        container.appendChild(div);
        setTimeout(function() { if (div.parentNode) div.remove(); }, 5000);
    }

    // Update nav session UI
    function updateNavSession(sessionData) {
        var navSession = document.getElementById('nav-session');
        if (!navSession) return;
        if (sessionData && sessionData.user) {
            navSession.innerHTML =
                '<span class="nav-user">\uD83D\uDC64 ' + sessionData.user.display_name + '</span>' +
                '<a href="/wallet" class="btn btn-sm btn-secondary">Wallet</a>' +
                '<button class="btn btn-sm" onclick="App.logout()">Logout</button>';
        } else {
            navSession.innerHTML =
                '<button id="btn-create-session" class="btn btn-primary btn-sm" onclick="App.initSession()">Connect</button>';
        }
    }

    // Init / connect session
    function initSession() {
        var existing = session.get();
        if (existing) {
            flash('Already connected as: ' + (existing.user ? existing.user.display_name : 'Unknown'), 'info');
            return;
        }
        var mnemonic = prompt('Enter your 12-word mnemonic (or leave blank to generate new):');
        if (mnemonic === null) return;

        var promise = mnemonic.trim()
            ? api.recoverFromMnemonic(mnemonic.trim())
            : api.generateMnemonic();

        promise.then(function(data) {
            if (!mnemonic.trim() && data.mnemonic) {
                alert('Your new mnemonic (SAVE THIS SECURELY):\n\n' + data.mnemonic +
                    '\n\nYou will need this to recover your account.');
            }
            var displayName = prompt('Choose a display name (optional):') || 'Anonymous';
            return api.createSession(data.public_key, displayName).then(function(sessionData) {
                session.set(sessionData);
                flash('Connected as: ' + (sessionData.user ? sessionData.user.display_name : 'Unknown'), 'success');
                updateNavSession(sessionData);
            });
        }).catch(function(err) {
            flash('Connection failed: ' + err.message, 'error');
        });
    }

    function logout() {
        api.logout().then(function() {
            session.clear();
            updateNavSession(null);
            flash('Logged out successfully.', 'info');
        }).catch(function() {
            session.clear();
            updateNavSession(null);
            flash('Logged out.', 'info');
        });
    }

    // Initiate trade from offer card
    function tradeOffer(offerId, event) {
        if (event) event.preventDefault();
        var s = session.get();
        if (!s) {
            flash('Please connect your wallet first.', 'error');
            return;
        }
        api.getOffer(offerId).then(function(offer) {
            var amountFiat = parseFloat(prompt('Enter amount in ' + offer.fiat_currency + ':'));
            if (!amountFiat || amountFiat <= 0) return;
            var amountXmr = offer.price
                ? amountFiat / offer.price
                : parseFloat(prompt('Enter XMR amount:'));
            if (!amountXmr || amountXmr <= 0) return;
            return api.initiateTrade(offerId, amountXmr, amountFiat).then(function(trade) {
                flash('Trade #' + trade.id + ' initiated!', 'success');
                setTimeout(function() { window.location.href = '/trade/' + trade.id; }, 1000);
            });
        }).catch(function(err) {
            flash('Error: ' + err.message, 'error');
        });
    }

    // Restore session state on page load
    document.addEventListener('DOMContentLoaded', function() {
        var s = session.get();
        if (s) {
            updateNavSession(s);
            api.verifySession().catch(function() {
                session.clear();
                updateNavSession(null);
            });
        }
    });

    return {
        session:      session,
        api:          api,
        render:       render,
        chat:         chat,
        flash:        flash,
        initSession:  initSession,
        logout:       logout,
        tradeOffer:   tradeOffer
    };
})();
