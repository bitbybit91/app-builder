# CapitalMonero P2P Exchange - Flutter Mobile App

A production-ready Flutter mobile application for the **CapitalMonero P2P Cryptocurrency Exchange** platform. This app enables privacy-focused peer-to-peer trading of Bitcoin (BTC) and Monero (XMR) with support for 20+ fiat currencies and 20+ payment methods.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-blue?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

| Category | Features |
|----------|----------|
| **Trading** | P2P buy/sell ads, trade initiation, escrow flow, real-time price margins |
| **Currencies** | Bitcoin (BTC) + Monero (XMR), 20 fiat currencies |
| **Privacy** | Tor support via SOCKS5 proxy, no KYC required |
| **Security** | 2FA (TOTP), biometric authentication, encrypted local storage |
| **Wallet** | Multi-currency wallet with deposit QR codes, withdrawal, BTC↔XMR swap |
| **Messaging** | Real-time trade chat, trade status notifications |
| **Admin** | Admin panel for dispute resolution, user management |

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required
- **Flutter SDK** 3.0.0 or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK** 3.0.0 or higher (included with Flutter)
- **Git** for version control

### For Android Development
- **Android Studio** 2022.1.1 or higher ([Download](https://developer.android.com/studio))
- **Android SDK** with API level 21-34
- **Java JDK 8** or higher

### For iOS Development (macOS only)
- **Xcode** 14.0 or higher ([Download](https://developer.apple.com/xcode/))
- **CocoaPods** (`sudo gem install cocoapods`)

### Verify Installation
```bash
flutter doctor -v
```

---

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/bitbybit91/app-builder.git
cd app-builder/capitalmonero_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure the App (Optional)
See [Configuration](#-configuration) section below.

### 4. Run the App

**Development (Debug Mode):**
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices              # List available devices
flutter run -d <device_id>   # Run on specific device
```

**Hot Reload:**
Press `r` in the terminal while the app is running, or use your IDE's hot reload feature.

---

## ⚙️ Configuration

### API Endpoints

The app connects to the CapitalMonero backend. Configure endpoints in `lib/config/api_config.dart`:

```dart
// Clearnet API (default)
const String baseUrl = 'https://capitalmonero.com/api';

// Tor Hidden Service (for enhanced privacy)
const String torUrl = 'http://fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion/api';
```

### Tor Support

Enable Tor mode at runtime in the app's Settings screen, or programmatically:

```dart
import 'package:capitalmonero_app/services/api_service.dart';

// Enable Tor
ApiService.instance.useTor = true;

// Disable Tor (use clearnet)
ApiService.instance.useTor = false;
```

> **Note:** Using Tor requires a running Tor proxy (SOCKS5) on the device. Apps like Orbot can provide this on Android.

### App Constants

Modify app-wide constants in `lib/config/constants.dart`:

```dart
class AppConstants {
  static const String appName = 'CapitalMonero';
  static const String appVersion = '1.0.0';
  static const double tradeFeePercent = 1.0;      // 1% trade fee
  static const double affiliateCommission = 20.0;  // 20% affiliate commission
}
```

### Supported Currencies

**Cryptocurrencies:** BTC, XMR

**Fiat Currencies:** USD, EUR, GBP, CAD, AUD, CHF, JPY, CNY, INR, BRL, RUB, ZAR, MXN, SGD, HKD, NOK, SEK, TRY, ARS, NGN

### Supported Payment Methods

Bank Transfer, Cash Deposit, PayPal, Revolut, Wise, Venmo, Zelle, Cash App, Amazon Gift Card, Steam Gift Card, Google Pay, Apple Pay, SEPA, Cash by Mail, Cash in Person, Western Union, MoneyGram, Cryptocurrency, M-Pesa, UPI

---

## 🔨 Building for Production

### Android APK

```bash
# Build release APK
flutter build apk --release

# Build APK for specific architecture (smaller size)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)

```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build for iOS
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and distribute.

### Build Configuration

For release builds, update the following:

**Android** (`android/app/build.gradle`):
```gradle
defaultConfig {
    applicationId "com.capitalmonero.app"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
}
```

**iOS** (`ios/Runner/Info.plist`):
- `CFBundleIdentifier`: `com.capitalmonero.app`
- `CFBundleShortVersionString`: `1.0.0`
- `CFBundleVersion`: `1`

---

## 📱 Usage Guide

### First Launch
1. Launch the app
2. Register a new account or login
3. Set up 2FA for enhanced security (recommended)
4. Enable biometric lock in Settings (optional)

### Trading Flow

**Creating a Buy/Sell Offer:**
1. Navigate to **Offers** → **Create Offer**
2. Select Buy or Sell
3. Choose cryptocurrency (BTC/XMR)
4. Set price (fixed or margin-based)
5. Configure payment method and limits
6. Add trade terms
7. Submit

**Starting a Trade:**
1. Browse offers on the **Offers** screen
2. Tap an offer to view details
3. Enter the amount and tap **Start Trade**
4. Follow the escrow process:
   - Seller: Funds escrow
   - Buyer: Sends payment and marks as paid
   - Seller: Confirms payment and releases crypto

### Wallet

- View balances for BTC and XMR
- Deposit: Scan QR code or copy address
- Withdraw: Enter address and amount
- Swap: Exchange between BTC and XMR

### Settings

- **Tor Mode**: Toggle for enhanced privacy
- **Biometric Lock**: Fingerprint/Face ID authentication
- **2FA**: Enable/disable two-factor authentication
- **Preferred Currency**: Set default fiat currency

---

## 📁 Project Structure

```
capitalmonero_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # MaterialApp configuration
│   ├── config/
│   │   ├── api_config.dart    # API endpoints
│   │   ├── app_theme.dart     # Dark theme styling
│   │   ├── constants.dart     # App constants
│   │   └── routes.dart        # Named routes
│   ├── models/                # Data models (User, Offer, Trade, etc.)
│   ├── services/              # API, Auth, Storage, Biometrics
│   ├── providers/             # State management (Provider pattern)
│   ├── screens/               # UI screens
│   │   ├── auth/              # Login, Register, 2FA
│   │   ├── home/              # Home, Dashboard
│   │   ├── offers/            # Offer list, detail, create
│   │   ├── trades/            # Trade list, detail, chat
│   │   ├── wallet/            # Wallet, deposit, withdraw, swap
│   │   ├── profile/           # Profile, settings
│   │   ├── admin/             # Admin panel screens
│   │   └── disputes/          # Dispute management
│   └── widgets/               # Reusable UI components
├── android/                   # Android platform files
├── ios/                       # iOS platform files
├── test/                      # Unit and widget tests
├── pubspec.yaml              # Dependencies
└── analysis_options.yaml     # Linting rules
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## 🎨 Theming

The app uses a dark theme matching the CapitalMonero web platform. Colors are defined in `lib/config/app_theme.dart`:

| Color | Hex | Usage |
|-------|-----|-------|
| Background Primary | `#0d0d1a` | Main background |
| Background Secondary | `#1a1a2e` | Secondary areas |
| Card Background | `#16213e` | Cards and containers |
| Accent | `#e94560` | Primary accent (buttons, links) |
| Success | `#00b894` | Success states |
| Warning | `#fdcb6e` | Warning states |
| Danger | `#d63031` | Error states |
| Monero Orange | `#f26822` | XMR branding |

---

## 🔌 API Endpoints

The app communicates with these backend endpoints:

| Category | Endpoint | Description |
|----------|----------|-------------|
| **Auth** | `POST /login` | User login |
| | `POST /register` | User registration |
| | `POST /logout` | Logout |
| | `GET /user` | Get current user |
| | `POST /2fa/verify` | Verify 2FA code |
| | `POST /2fa/enable` | Enable 2FA |
| **Offers** | `GET /offers` | List offers |
| | `POST /offers` | Create offer |
| | `GET /offers/{id}` | Get offer details |
| **Trades** | `GET /trades` | List user trades |
| | `POST /trades` | Start a trade |
| | `POST /trades/{id}/paid` | Mark payment sent |
| | `POST /trades/{id}/complete` | Release & complete |
| **Wallet** | `GET /wallets` | Get wallet balances |
| | `POST /wallets/withdraw` | Withdraw funds |
| | `POST /wallets/swap` | Swap BTC↔XMR |
| **Admin** | `GET /admin/stats` | Admin statistics |
| | `GET /admin/users` | Manage users |
| | `GET /admin/disputes` | Manage disputes |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `flutter analyze` before committing
- Ensure all tests pass with `flutter test`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Links

- **Website**: [capitalmonero.com](https://capitalmonero.com)
- **Tor**: `fae6oumbrz6drrjkwhuidvckur47eg2v64jlinrv3wutshb2sc7k2tqd.onion`
- **Flutter Docs**: [docs.flutter.dev](https://docs.flutter.dev)

---

## ❓ Troubleshooting

### Common Issues

**Flutter SDK not found:**
```bash
# Ensure Flutter is in your PATH
export PATH="$PATH:/path/to/flutter/bin"
```

**Android build fails:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

**iOS pod install fails:**
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

**Gradle version issues:**
Update `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.3-all.zip
```

---

Built with ❤️ using Flutter
