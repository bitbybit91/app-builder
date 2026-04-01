# CapitalMonero

A production-ready cross-platform peer-to-peer cryptocurrency exchange application built with Flutter, based on the AgoraDesk/LocalMonero platform concept.

## Features

- **P2P Trading**: Create buy/sell offers for Monero (XMR) and Bitcoin (BTC)
- **Wallet System**: Monero and Bitcoin wallet integration with deposit/withdrawal
- **Secure Messaging**: Private encrypted messages between users with PGP support
- **User Authentication**: Username/password with TOTP 2FA and mnemonic recovery
- **Search & Discovery**: Search offers by coin, payment method, currency, country
- **Reputation System**: Feedback scores and trust levels
- **Admin Panel**: User management, dispute resolution, platform statistics
- **Multi-language**: 12 languages supported (EN, ES, FR, DE, KO, ZH, JA, PT, TH, SV, DA, NB)

## Architecture

Clean architecture with BLoC state management:
- **Presentation**: Flutter widgets + BLoC/Cubit
- **Domain**: Use cases, entities, repository interfaces
- **Data**: Repository implementations, API clients, local storage

## Getting Started

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build for Android
flutter build apk --flavor production

# Build for iOS
flutter build ios
```

## Platform Support

- **Android**: Min SDK 21, Target SDK 34 (Google Play, Samsung Galaxy, Amazon, F-Droid)
- **iOS**: Deployment Target 14.0 (App Store)

## Package IDs

- Android: `com.capitalmonero.app`
- iOS: `com.capitalmonero.app`
