<section class="hero">
    <div class="container">
        <h1>Trade Monero <span class="highlight">Peer-to-Peer</span></h1>
        <p class="hero-subtitle">Buy and sell Monero (XMR) directly with other users. No intermediaries, no KYC, private by default.</p>
        <div class="hero-actions">
            <a href="/trades/buy" class="btn btn-primary btn-lg">Buy Monero</a>
            <a href="/trades/sell" class="btn btn-outline btn-lg">Sell Monero</a>
        </div>
        <div class="hero-stats">
            <div class="stat">
                <span class="stat-number"><?= $buyCount ?? 0 ?></span>
                <span class="stat-label">Buy Offers</span>
            </div>
            <div class="stat">
                <span class="stat-number"><?= $sellCount ?? 0 ?></span>
                <span class="stat-label">Sell Offers</span>
            </div>
        </div>
    </div>
</section>

<section class="features">
    <div class="container">
        <h2 class="section-title">Why Capital Monero?</h2>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">&#128274;</div>
                <h3>Private &amp; Secure</h3>
                <p>Trade Monero without sharing personal information. Your privacy is our priority.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#9878;</div>
                <h3>Escrow Protection</h3>
                <p>All trades are protected by our escrow system, ensuring safe transactions for both parties.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#127760;</div>
                <h3>Global Access</h3>
                <p>Trade with users worldwide using your preferred payment method and currency.</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">&#128176;</div>
                <h3>Multiple Payment Methods</h3>
                <p>Bank transfer, cash, PayPal, gift cards, and many more payment options available.</p>
            </div>
        </div>
    </div>
</section>

<?php if (!empty($recentTrades)): ?>
<section class="recent-trades">
    <div class="container">
        <h2 class="section-title">Recent Trade Offers</h2>
        <div class="trades-grid">
            <?php foreach ($recentTrades as $trade): ?>
                <div class="trade-card">
                    <div class="trade-card-header">
                        <span class="badge badge-<?= $trade['type'] === 'buy' ? 'buy' : 'sell' ?>">
                            <?= $trade['type'] === 'buy' ? 'Buying' : 'Selling' ?>
                        </span>
                        <span class="trade-user"><?= htmlspecialchars($trade['username']) ?></span>
                    </div>
                    <h3 class="trade-card-title">
                        <a href="/trades/view?id=<?= $trade['id'] ?>"><?= htmlspecialchars($trade['title']) ?></a>
                    </h3>
                    <div class="trade-card-details">
                        <div class="detail">
                            <span class="detail-label">Amount</span>
                            <span class="detail-value"><?= number_format($trade['amount_min']) ?> – <?= number_format($trade['amount_max']) ?> <?= htmlspecialchars($trade['currency']) ?></span>
                        </div>
                        <div class="detail">
                            <span class="detail-label">Payment</span>
                            <span class="detail-value"><?= htmlspecialchars($trade['payment_method']) ?></span>
                        </div>
                    </div>
                    <a href="/trades/view?id=<?= $trade['id'] ?>" class="btn btn-sm btn-outline">View Trade</a>
                </div>
            <?php endforeach; ?>
        </div>
        <div class="text-center mt-2">
            <a href="/trades" class="btn btn-outline">View All Trades</a>
        </div>
    </div>
</section>
<?php endif; ?>

<section class="cta">
    <div class="container text-center">
        <h2>Ready to Start Trading?</h2>
        <p>Join Capital Monero today and start trading Monero peer-to-peer.</p>
        <?php if (empty($user)): ?>
            <a href="/register" class="btn btn-primary btn-lg">Create Free Account</a>
        <?php else: ?>
            <a href="/trades/create" class="btn btn-primary btn-lg">Create a Trade</a>
        <?php endif; ?>
    </div>
</section>
