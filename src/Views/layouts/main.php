<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($title ?? 'Capital Monero') ?></title>
    <meta name="description" content="Capital Monero — Secure peer-to-peer Monero (XMR) trading platform. Buy and sell Monero directly with other users.">
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <header class="site-header">
        <nav class="nav-container">
            <a href="/" class="logo">
                <span class="logo-icon">&#9670;</span>
                <span class="logo-text">Capital<strong>Monero</strong></span>
            </a>
            <button class="nav-toggle" aria-label="Toggle navigation" onclick="document.querySelector('.nav-links').classList.toggle('active')">
                &#9776;
            </button>
            <div class="nav-links">
                <a href="/trades">All Trades</a>
                <a href="/trades/buy">Buy XMR</a>
                <a href="/trades/sell">Sell XMR</a>
                <?php if (!empty($user)): ?>
                    <a href="/trades/create" class="btn btn-sm btn-primary">Create Trade</a>
                    <a href="/dashboard">Dashboard</a>
                    <a href="/logout">Logout</a>
                <?php else: ?>
                    <a href="/login" class="btn btn-sm btn-outline">Login</a>
                    <a href="/register" class="btn btn-sm btn-primary">Register</a>
                <?php endif; ?>
            </div>
        </nav>
    </header>

    <?php if (!empty($_SESSION['flash_success'])): ?>
        <div class="alert alert-success">
            <?= htmlspecialchars($_SESSION['flash_success']) ?>
            <?php unset($_SESSION['flash_success']); ?>
        </div>
    <?php endif; ?>

    <?php if (!empty($_SESSION['flash_error'])): ?>
        <div class="alert alert-error">
            <?= htmlspecialchars($_SESSION['flash_error']) ?>
            <?php unset($_SESSION['flash_error']); ?>
        </div>
    <?php endif; ?>

    <main>
        <?= $content ?>
    </main>

    <footer class="site-footer">
        <div class="container">
            <div class="footer-grid">
                <div class="footer-section">
                    <h3><span class="logo-icon">&#9670;</span> Capital Monero</h3>
                    <p>Secure peer-to-peer Monero trading. Buy and sell XMR directly with other users using your preferred payment method.</p>
                </div>
                <div class="footer-section">
                    <h4>Platform</h4>
                    <ul>
                        <li><a href="/trades/buy">Buy Monero</a></li>
                        <li><a href="/trades/sell">Sell Monero</a></li>
                        <li><a href="/trades/create">Create Trade</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h4>Information</h4>
                    <ul>
                        <li><a href="/about">About Us</a></li>
                        <li><a href="/faq">FAQ</a></li>
                        <li><a href="/terms">Terms of Service</a></li>
                        <li><a href="/contact">Contact</a></li>
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; <?= date('Y') ?> capitalmonero.com — All rights reserved.</p>
            </div>
        </div>
    </footer>

    <script src="/assets/js/app.js"></script>
</body>
</html>
