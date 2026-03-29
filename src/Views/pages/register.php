<section class="page-header">
    <div class="container">
        <h1>Create Account</h1>
        <p>Join Capital Monero and start trading</p>
    </div>
</section>

<section class="auth-section">
    <div class="container">
        <div class="auth-card">
            <form method="POST" action="/register" class="form">
                <?= \App\Core\CSRF::field() ?>

                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required autofocus
                           placeholder="Choose a username (3-30 characters)"
                           minlength="3" maxlength="30"
                           value="<?= htmlspecialchars($_SESSION['form_data']['username'] ?? '') ?>">
                </div>

                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required
                           placeholder="Enter your email address"
                           value="<?= htmlspecialchars($_SESSION['form_data']['email'] ?? '') ?>">
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required
                           placeholder="Choose a strong password (min 8 characters)"
                           minlength="8">
                </div>

                <div class="form-group">
                    <label for="password_confirm">Confirm Password</label>
                    <input type="password" id="password_confirm" name="password_confirm" required
                           placeholder="Repeat your password"
                           minlength="8">
                </div>

                <button type="submit" class="btn btn-primary btn-block">Create Account</button>
            </form>

            <p class="auth-link">Already have an account? <a href="/login">Login here</a></p>
        </div>
    </div>
</section>
<?php unset($_SESSION['form_data']); ?>
