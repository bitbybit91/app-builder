# Capital Monero

A peer-to-peer Monero (XMR) trading platform built with PHP for [capitalmonero.com](https://capitalmonero.com).

## Features

- **User Registration & Login** — Secure authentication with password hashing and session management
- **Trade Listings** — Browse, search, and filter buy/sell Monero offers
- **Trade Creation** — Post your own buy or sell offers with payment preferences
- **Trade Responses** — Respond to offers with your desired amount and message
- **In-Trade Messaging** — Communicate securely with trading partners
- **User Dashboard** — Manage your trades, responses, and profile settings
- **Contact System** — Built-in contact form for support inquiries
- **Responsive Design** — Mobile-friendly dark theme UI
- **Security** — CSRF protection, input validation, parameterized queries, password hashing

## Requirements

- PHP 8.0 or higher
- SQLite3 PHP extension (`php-sqlite3`)
- Apache with `mod_rewrite` enabled (or Nginx with equivalent rewrite rules)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/bitbybit91/app-builder.git capitalmonero
cd capitalmonero
```

### 2. Run Database Migration

```bash
php database/migrate.php
```

### 3. Start the Development Server

```bash
php -S localhost:8000 -t public
```

Then open [http://localhost:8000](http://localhost:8000) in your browser.

### 4. Apache Deployment

Point your Apache virtual host document root to the `public/` directory:

```apache
<VirtualHost *:80>
    ServerName capitalmonero.com
    DocumentRoot /var/www/capitalmonero/public

    <Directory /var/www/capitalmonero/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Make sure `mod_rewrite` is enabled:

```bash
sudo a2enmod rewrite
sudo systemctl restart apache2
```

## Project Structure

```
├── config/
│   └── app.php              # Application configuration
├── database/
│   └── migrate.php           # Database migration script
├── public/
│   ├── index.php             # Application entry point
│   ├── .htaccess             # Apache URL rewriting
│   └── assets/
│       ├── css/style.css     # Stylesheet
│       └── js/app.js         # Frontend JavaScript
└── src/
    ├── Controllers/
    │   ├── AuthController.php
    │   ├── DashboardController.php
    │   ├── HomeController.php
    │   ├── PageController.php
    │   └── TradeController.php
    ├── Core/
    │   ├── App.php           # Application bootstrap & routing
    │   ├── Auth.php          # Authentication helper
    │   ├── CSRF.php          # CSRF protection
    │   ├── Database.php      # SQLite database wrapper
    │   ├── Router.php        # URL router
    │   ├── Validator.php     # Form validation
    │   └── View.php          # Template engine
    ├── Models/
    │   ├── Message.php
    │   ├── Trade.php
    │   ├── TradeResponse.php
    │   └── User.php
    └── Views/
        ├── layouts/
        │   └── main.php      # Main page layout
        └── pages/
            ├── 404.php
            ├── about.php
            ├── contact.php
            ├── dashboard.php
            ├── dashboard_settings.php
            ├── dashboard_trades.php
            ├── faq.php
            ├── home.php
            ├── login.php
            ├── register.php
            ├── terms.php
            ├── trade_create.php
            ├── trade_view.php
            └── trades.php
```

## Security

- All user passwords are hashed with `password_hash()` (bcrypt)
- CSRF tokens protect all POST forms
- All database queries use parameterized statements (PDO prepared statements)
- All user output is escaped with `htmlspecialchars()`
- Sessions use `httponly` cookies with `SameSite=Lax`
- Session IDs are regenerated on login

## License

All rights reserved — capitalmonero.com
