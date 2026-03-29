<section class="page-header">
    <div class="container">
        <h1>My Trades</h1>
        <p>Manage your trade offers</p>
    </div>
</section>

<section class="dashboard-section">
    <div class="container">
        <div class="dashboard-nav">
            <a href="/trades/create" class="btn btn-primary">Create New Trade</a>
            <a href="/dashboard" class="btn btn-outline">Back to Dashboard</a>
        </div>

        <?php if (empty($trades)): ?>
            <div class="empty-state">
                <p>You haven't created any trades yet.</p>
                <a href="/trades/create" class="btn btn-primary">Create Your First Trade</a>
            </div>
        <?php else: ?>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Type</th>
                            <th>Title</th>
                            <th>Amount Range</th>
                            <th>Payment</th>
                            <th>Status</th>
                            <th>Created</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($trades as $trade): ?>
                            <tr>
                                <td><span class="badge badge-<?= $trade['type'] ?>"><?= strtoupper($trade['type']) ?></span></td>
                                <td><?= htmlspecialchars($trade['title']) ?></td>
                                <td><?= number_format($trade['amount_min']) ?>–<?= number_format($trade['amount_max']) ?> <?= htmlspecialchars($trade['currency']) ?></td>
                                <td><?= htmlspecialchars($trade['payment_method']) ?></td>
                                <td><span class="badge badge-status"><?= htmlspecialchars($trade['status']) ?></span></td>
                                <td><?= date('M j, Y', strtotime($trade['created_at'])) ?></td>
                                <td><a href="/trades/view?id=<?= $trade['id'] ?>" class="btn btn-sm btn-outline">View</a></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</section>
