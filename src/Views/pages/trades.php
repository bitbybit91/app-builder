<section class="page-header">
    <div class="container">
        <h1><?= $heading ?? 'Trade Offers' ?></h1>
        <p><?= $subtitle ?? 'Browse all active Monero trade offers' ?></p>
    </div>
</section>

<section class="trades-section">
    <div class="container">
        <div class="trades-toolbar">
            <form method="GET" action="/trades" class="search-form">
                <input type="text" name="q" placeholder="Search trades..."
                       value="<?= htmlspecialchars($search ?? '') ?>">
                <button type="submit" class="btn btn-primary btn-sm">Search</button>
            </form>
            <div class="trades-nav">
                <a href="/trades" class="btn btn-sm btn-outline">All</a>
                <a href="/trades/buy" class="btn btn-sm btn-outline">Buy XMR</a>
                <a href="/trades/sell" class="btn btn-sm btn-outline">Sell XMR</a>
            </div>
        </div>

        <?php if (empty($trades)): ?>
            <div class="empty-state">
                <p>No trade offers found.</p>
                <?php if (\App\Core\Auth::check()): ?>
                    <a href="/trades/create" class="btn btn-primary">Create the first trade</a>
                <?php else: ?>
                    <a href="/register" class="btn btn-primary">Sign up to create a trade</a>
                <?php endif; ?>
            </div>
        <?php else: ?>
            <div class="trades-list">
                <?php foreach ($trades as $trade): ?>
                    <div class="trade-row">
                        <div class="trade-row-info">
                            <span class="badge badge-<?= $trade['type'] === 'buy' ? 'buy' : 'sell' ?>">
                                <?= $trade['type'] === 'buy' ? 'BUY' : 'SELL' ?>
                            </span>
                            <div class="trade-row-main">
                                <a href="/trades/view?id=<?= $trade['id'] ?>" class="trade-row-title">
                                    <?= htmlspecialchars($trade['title']) ?>
                                </a>
                                <span class="trade-row-user">by <?= htmlspecialchars($trade['username']) ?>
                                    (<?= (int)$trade['trades_completed'] ?> trades)</span>
                            </div>
                        </div>
                        <div class="trade-row-details">
                            <div class="trade-row-amount">
                                <?= number_format($trade['amount_min']) ?> – <?= number_format($trade['amount_max']) ?>
                                <?= htmlspecialchars($trade['currency']) ?>
                            </div>
                            <div class="trade-row-payment"><?= htmlspecialchars($trade['payment_method']) ?></div>
                            <?php if (!empty($trade['location'])): ?>
                                <div class="trade-row-location"><?= htmlspecialchars($trade['location']) ?></div>
                            <?php endif; ?>
                        </div>
                        <a href="/trades/view?id=<?= $trade['id'] ?>" class="btn btn-sm btn-primary">View</a>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
</section>
