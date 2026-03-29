<section class="page-header">
    <div class="container">
        <h1>Dashboard</h1>
        <p>Welcome back, <?= htmlspecialchars($user['username']) ?>!</p>
    </div>
</section>

<section class="dashboard-section">
    <div class="container">
        <div class="dashboard-stats">
            <div class="stat-card">
                <span class="stat-number"><?= count($myTrades) ?></span>
                <span class="stat-label">My Trades</span>
            </div>
            <div class="stat-card">
                <span class="stat-number"><?= count($myResponses) ?></span>
                <span class="stat-label">My Responses</span>
            </div>
            <div class="stat-card">
                <span class="stat-number"><?= (int)$user['trades_completed'] ?></span>
                <span class="stat-label">Completed</span>
            </div>
        </div>

        <div class="dashboard-nav">
            <a href="/trades/create" class="btn btn-primary">Create New Trade</a>
            <a href="/dashboard/trades" class="btn btn-outline">My Trades</a>
            <a href="/dashboard/settings" class="btn btn-outline">Settings</a>
        </div>

        <div class="dashboard-grid">
            <div class="card">
                <h3>My Recent Trades</h3>
                <?php if (empty($myTrades)): ?>
                    <p class="text-muted">You haven't created any trades yet. <a href="/trades/create">Create one now</a>.</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Type</th>
                                    <th>Title</th>
                                    <th>Amount</th>
                                    <th>Status</th>
                                    <th>Date</th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach (array_slice($myTrades, 0, 10) as $trade): ?>
                                    <tr>
                                        <td><span class="badge badge-<?= $trade['type'] ?>"><?= strtoupper($trade['type']) ?></span></td>
                                        <td><?= htmlspecialchars($trade['title']) ?></td>
                                        <td><?= number_format($trade['amount_min']) ?>–<?= number_format($trade['amount_max']) ?> <?= htmlspecialchars($trade['currency']) ?></td>
                                        <td><span class="badge badge-status"><?= htmlspecialchars($trade['status']) ?></span></td>
                                        <td><?= date('M j', strtotime($trade['created_at'])) ?></td>
                                        <td><a href="/trades/view?id=<?= $trade['id'] ?>" class="btn btn-sm btn-outline">View</a></td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>

            <div class="card">
                <h3>My Responses</h3>
                <?php if (empty($myResponses)): ?>
                    <p class="text-muted">You haven't responded to any trades yet. <a href="/trades">Browse trades</a>.</p>
                <?php else: ?>
                    <div class="table-responsive">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Trade</th>
                                    <th>Amount</th>
                                    <th>Status</th>
                                    <th>Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach (array_slice($myResponses, 0, 10) as $resp): ?>
                                    <tr>
                                        <td><?= htmlspecialchars($resp['trade_title']) ?></td>
                                        <td><?= number_format($resp['amount'], 2) ?></td>
                                        <td><span class="badge badge-status"><?= htmlspecialchars($resp['status']) ?></span></td>
                                        <td><?= date('M j', strtotime($resp['created_at'])) ?></td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</section>
