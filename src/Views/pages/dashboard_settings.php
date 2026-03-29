<section class="page-header">
    <div class="container">
        <h1>Settings</h1>
        <p>Update your profile settings</p>
    </div>
</section>

<section class="form-section">
    <div class="container">
        <div class="dashboard-nav">
            <a href="/dashboard" class="btn btn-outline">Back to Dashboard</a>
        </div>

        <div class="form-card">
            <h3>Profile Information</h3>
            <div class="detail-list mb-2">
                <div class="detail-item">
                    <span class="detail-label">Username</span>
                    <span class="detail-value"><?= htmlspecialchars($user['username']) ?></span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Email</span>
                    <span class="detail-value"><?= htmlspecialchars($user['email']) ?></span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Member since</span>
                    <span class="detail-value"><?= date('F j, Y', strtotime($user['created_at'])) ?></span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Trades completed</span>
                    <span class="detail-value"><?= (int)$user['trades_completed'] ?></span>
                </div>
            </div>

            <form method="POST" action="/dashboard/settings" class="form">
                <?= \App\Core\CSRF::field() ?>

                <div class="form-group">
                    <label for="bio">Bio</label>
                    <textarea id="bio" name="bio" rows="4"
                              placeholder="Tell other traders about yourself..."><?= htmlspecialchars($user['bio'] ?? '') ?></textarea>
                </div>

                <button type="submit" class="btn btn-primary">Save Changes</button>
            </form>
        </div>
    </div>
</section>
