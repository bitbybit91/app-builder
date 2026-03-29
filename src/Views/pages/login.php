<section class="page-header">
    <div class="container">
        <h1>Login</h1>
        <p>Welcome back to Capital Monero</p>
    </div>
</section>

<section class="auth-section">
    <div class="container">
        <div class="auth-card">
            <form method="POST" action="/login" class="form">
                <?= \App\Core\CSRF::field() ?>

                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required autofocus
                           placeholder="Enter your username"
                           value="<?= htmlspecialchars($_SESSION['form_data']['username'] ?? '') ?>">
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required
                           placeholder="Enter your password">
                </div>

                <button type="submit" class="btn btn-primary btn-block">Login</button>
            </form>

            <p class="auth-link">Don't have an account? <a href="/register">Register here</a></p>
        </div>
    </div>
</section>
<?php unset($_SESSION['form_data']); ?>
