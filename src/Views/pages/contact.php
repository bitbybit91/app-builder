<?php $formData = $_SESSION['form_data'] ?? []; unset($_SESSION['form_data']); ?>

<section class="page-header">
    <div class="container">
        <h1>Contact Us</h1>
        <p>Have a question or need help? Send us a message.</p>
    </div>
</section>

<section class="form-section">
    <div class="container">
        <div class="form-card">
            <form method="POST" action="/contact" class="form">
                <?= \App\Core\CSRF::field() ?>

                <div class="form-group">
                    <label for="name">Your Name</label>
                    <input type="text" id="name" name="name" required
                           placeholder="Enter your name"
                           value="<?= htmlspecialchars($formData['name'] ?? ($user['username'] ?? '')) ?>">
                </div>

                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email" required
                           placeholder="Enter your email"
                           value="<?= htmlspecialchars($formData['email'] ?? ($user['email'] ?? '')) ?>">
                </div>

                <div class="form-group">
                    <label for="subject">Subject</label>
                    <input type="text" id="subject" name="subject" required
                           placeholder="What is this about?"
                           value="<?= htmlspecialchars($formData['subject'] ?? '') ?>">
                </div>

                <div class="form-group">
                    <label for="message">Message</label>
                    <textarea id="message" name="message" rows="6" required
                              placeholder="Describe your question or issue in detail..."
                              minlength="10"><?= htmlspecialchars($formData['message'] ?? '') ?></textarea>
                </div>

                <button type="submit" class="btn btn-primary btn-block">Send Message</button>
            </form>
        </div>
    </div>
</section>
