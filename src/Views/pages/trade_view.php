<section class="page-header">
    <div class="container">
        <div class="trade-view-header">
            <div>
                <span class="badge badge-<?= $trade['type'] === 'buy' ? 'buy' : 'sell' ?> badge-lg">
                    <?= $trade['type'] === 'buy' ? 'BUYING' : 'SELLING' ?>
                </span>
                <h1><?= htmlspecialchars($trade['title']) ?></h1>
                <p class="trade-meta">
                    Posted by <strong><?= htmlspecialchars($trade['username']) ?></strong>
                    (<?= (int)$trade['trades_completed'] ?> trades completed)
                    &middot; <?= date('M j, Y', strtotime($trade['created_at'])) ?>
                    &middot; Status: <span class="badge badge-status"><?= htmlspecialchars($trade['status']) ?></span>
                </p>
            </div>
        </div>
    </div>
</section>

<section class="trade-detail">
    <div class="container">
        <div class="trade-detail-grid">
            <div class="trade-detail-main">
                <div class="card">
                    <h3>Trade Details</h3>
                    <div class="detail-list">
                        <div class="detail-item">
                            <span class="detail-label">Amount Range</span>
                            <span class="detail-value">
                                <?= number_format($trade['amount_min']) ?> – <?= number_format($trade['amount_max']) ?>
                                <?= htmlspecialchars($trade['currency']) ?>
                            </span>
                        </div>
                        <?php if ($trade['price_per_xmr']): ?>
                        <div class="detail-item">
                            <span class="detail-label">Price per XMR</span>
                            <span class="detail-value"><?= number_format($trade['price_per_xmr'], 2) ?> <?= htmlspecialchars($trade['currency']) ?></span>
                        </div>
                        <?php endif; ?>
                        <div class="detail-item">
                            <span class="detail-label">Payment Method</span>
                            <span class="detail-value"><?= htmlspecialchars($trade['payment_method']) ?></span>
                        </div>
                        <?php if (!empty($trade['location'])): ?>
                        <div class="detail-item">
                            <span class="detail-label">Location</span>
                            <span class="detail-value"><?= htmlspecialchars($trade['location']) ?></span>
                        </div>
                        <?php endif; ?>
                    </div>
                </div>

                <?php if (!empty($trade['description'])): ?>
                <div class="card">
                    <h3>Description</h3>
                    <p><?= nl2br(htmlspecialchars($trade['description'])) ?></p>
                </div>
                <?php endif; ?>

                <?php if (\App\Core\Auth::check() && $trade['user_id'] !== \App\Core\Auth::id() && $trade['status'] === 'open'): ?>
                <div class="card">
                    <h3>Respond to This Trade</h3>
                    <form method="POST" action="/trades/respond" class="form">
                        <?= \App\Core\CSRF::field() ?>
                        <input type="hidden" name="trade_id" value="<?= $trade['id'] ?>">

                        <div class="form-group">
                            <label for="amount">Amount (<?= htmlspecialchars($trade['currency']) ?>)</label>
                            <input type="number" id="amount" name="amount" required
                                   step="0.01"
                                   min="<?= $trade['amount_min'] ?>"
                                   max="<?= $trade['amount_max'] ?>"
                                   placeholder="Enter amount">
                        </div>

                        <div class="form-group">
                            <label for="response_message">Message (optional)</label>
                            <textarea id="response_message" name="message" rows="3"
                                      placeholder="Add a message to the trader..."></textarea>
                        </div>

                        <button type="submit" class="btn btn-primary">Submit Response</button>
                    </form>
                </div>
                <?php elseif (!\App\Core\Auth::check()): ?>
                <div class="card text-center">
                    <p><a href="/login">Login</a> or <a href="/register">register</a> to respond to this trade.</p>
                </div>
                <?php endif; ?>
            </div>

            <div class="trade-detail-sidebar">
                <div class="card">
                    <h3>Responses (<?= count($responses) ?>)</h3>
                    <?php if (empty($responses)): ?>
                        <p class="text-muted">No responses yet.</p>
                    <?php else: ?>
                        <div class="response-list">
                            <?php foreach ($responses as $resp): ?>
                                <div class="response-item <?= $resp['id'] === $activeResponseId ? 'active' : '' ?>">
                                    <div class="response-header">
                                        <strong><?= htmlspecialchars($resp['username']) ?></strong>
                                        <span class="badge badge-status"><?= htmlspecialchars($resp['status']) ?></span>
                                    </div>
                                    <div class="response-amount">
                                        <?= number_format($resp['amount'], 2) ?> <?= htmlspecialchars($trade['currency']) ?>
                                    </div>
                                    <?php if (!empty($resp['message'])): ?>
                                        <p class="response-message"><?= htmlspecialchars($resp['message']) ?></p>
                                    <?php endif; ?>
                                    <div class="response-actions">
                                        <a href="/trades/view?id=<?= $trade['id'] ?>&response=<?= $resp['id'] ?>"
                                           class="btn btn-sm btn-outline">Messages</a>
                                    </div>
                                </div>
                            <?php endforeach; ?>
                        </div>
                    <?php endif; ?>
                </div>

                <?php if ($activeResponseId > 0 && \App\Core\Auth::check()): ?>
                <div class="card">
                    <h3>Messages</h3>
                    <div class="message-list">
                        <?php if (empty($messages)): ?>
                            <p class="text-muted">No messages yet.</p>
                        <?php else: ?>
                            <?php foreach ($messages as $msg): ?>
                                <div class="message-item <?= $msg['sender_id'] === \App\Core\Auth::id() ? 'sent' : 'received' ?>">
                                    <div class="message-header">
                                        <strong><?= htmlspecialchars($msg['username']) ?></strong>
                                        <span class="message-time"><?= date('M j, g:i A', strtotime($msg['created_at'])) ?></span>
                                    </div>
                                    <p><?= nl2br(htmlspecialchars($msg['body'])) ?></p>
                                </div>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </div>

                    <form method="POST" action="/trades/message" class="form mt-1">
                        <?= \App\Core\CSRF::field() ?>
                        <input type="hidden" name="response_id" value="<?= $activeResponseId ?>">
                        <input type="hidden" name="trade_id" value="<?= $trade['id'] ?>">
                        <div class="form-group">
                            <textarea name="body" rows="2" placeholder="Type a message..." required></textarea>
                        </div>
                        <button type="submit" class="btn btn-primary btn-sm">Send</button>
                    </form>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</section>
