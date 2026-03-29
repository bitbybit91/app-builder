<?php
$currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'CHF'];
$paymentMethods = ['Bank Transfer', 'Cash (in person)', 'PayPal', 'Venmo', 'Zelle', 'Wise (TransferWise)', 'Revolut', 'Gift Cards', 'Cryptocurrency', 'Other'];
$formData = $_SESSION['form_data'] ?? [];
unset($_SESSION['form_data']);
?>

<section class="page-header">
    <div class="container">
        <h1>Create Trade Offer</h1>
        <p>Post a buy or sell offer for Monero</p>
    </div>
</section>

<section class="form-section">
    <div class="container">
        <div class="form-card">
            <form method="POST" action="/trades/create" class="form">
                <?= \App\Core\CSRF::field() ?>

                <div class="form-group">
                    <label for="type">I want to</label>
                    <select id="type" name="type" required>
                        <option value="buy" <?= ($formData['type'] ?? '') === 'buy' ? 'selected' : '' ?>>Buy Monero (XMR)</option>
                        <option value="sell" <?= ($formData['type'] ?? '') === 'sell' ? 'selected' : '' ?>>Sell Monero (XMR)</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="title">Trade Title</label>
                    <input type="text" id="title" name="title" required
                           placeholder="e.g., Buying XMR with PayPal - Fast response"
                           minlength="5" maxlength="100"
                           value="<?= htmlspecialchars($formData['title'] ?? '') ?>">
                </div>

                <div class="form-group">
                    <label for="description">Description (optional)</label>
                    <textarea id="description" name="description" rows="4"
                              placeholder="Add details about your trade terms, requirements, etc."><?= htmlspecialchars($formData['description'] ?? '') ?></textarea>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="amount_min">Minimum Amount</label>
                        <input type="number" id="amount_min" name="amount_min" required
                               step="0.01" min="1"
                               placeholder="10"
                               value="<?= htmlspecialchars($formData['amount_min'] ?? '') ?>">
                    </div>
                    <div class="form-group">
                        <label for="amount_max">Maximum Amount</label>
                        <input type="number" id="amount_max" name="amount_max" required
                               step="0.01" min="1"
                               placeholder="1000"
                               value="<?= htmlspecialchars($formData['amount_max'] ?? '') ?>">
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="currency">Currency</label>
                        <select id="currency" name="currency">
                            <?php foreach ($currencies as $cur): ?>
                                <option value="<?= $cur ?>" <?= ($formData['currency'] ?? 'USD') === $cur ? 'selected' : '' ?>><?= $cur ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="price_per_xmr">Price per XMR (optional)</label>
                        <input type="number" id="price_per_xmr" name="price_per_xmr"
                               step="0.01" min="0"
                               placeholder="Market rate if empty"
                               value="<?= htmlspecialchars($formData['price_per_xmr'] ?? '') ?>">
                    </div>
                </div>

                <div class="form-group">
                    <label for="payment_method">Payment Method</label>
                    <select id="payment_method" name="payment_method" required>
                        <option value="">Select payment method...</option>
                        <?php foreach ($paymentMethods as $method): ?>
                            <option value="<?= $method ?>" <?= ($formData['payment_method'] ?? '') === $method ? 'selected' : '' ?>><?= $method ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="form-group">
                    <label for="location">Location (optional)</label>
                    <input type="text" id="location" name="location"
                           placeholder="e.g., United States, Europe, Worldwide"
                           value="<?= htmlspecialchars($formData['location'] ?? '') ?>">
                </div>

                <button type="submit" class="btn btn-primary btn-block">Create Trade Offer</button>
            </form>
        </div>
    </div>
</section>
