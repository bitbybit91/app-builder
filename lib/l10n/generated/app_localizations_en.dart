// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CapitalMonero';

  @override
  String get username => 'Username';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get newPassword => 'New password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAccount => 'Create account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get recoverAccount => 'Recover account';

  @override
  String get recoveryInstructions =>
      'Enter your 12-word recovery phrase to regain access to your account and set a new password.';

  @override
  String get mnemonicPhrase => 'Recovery phrase';

  @override
  String get twoFactorCode => 'Two-factor code';

  @override
  String get twoFactorSetup => 'Set up two-factor authentication';

  @override
  String get twoFactorSetupIntro =>
      'Scan the QR code or copy the secret into your authenticator app, then enter the 6-digit code to confirm.';

  @override
  String get copySecret => 'Copy secret';

  @override
  String get confirm => 'Confirm';

  @override
  String get sessionLockedTitle => 'Session locked';

  @override
  String get sessionLockedSubtitle =>
      'Unlock with your PIN or biometrics to continue.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get useBiometrics => 'Use biometrics';

  @override
  String get acceptTerms => 'I accept the terms of service and privacy policy';

  @override
  String get optional => 'optional';

  @override
  String get offers => 'Offers';

  @override
  String get wallet => 'Wallet';

  @override
  String get messages => 'Messages';

  @override
  String get search => 'Search';

  @override
  String get profile => 'Profile';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get buying => 'Buying';

  @override
  String get selling => 'Selling';

  @override
  String get online => 'Online';

  @override
  String get local => 'Local';

  @override
  String get createOffer => 'Create offer';

  @override
  String get newOffer => 'New offer';

  @override
  String get editOffer => 'Edit offer';

  @override
  String get offerType => 'Offer type';

  @override
  String get coin => 'Coin';

  @override
  String get currency => 'Currency';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get priceEquation => 'Price equation';

  @override
  String get priceEquationHelp =>
      'Use \'market\' to track the live price. Example: market*1.02';

  @override
  String get minAmount => 'Minimum amount';

  @override
  String get maxAmount => 'Maximum amount';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get terms => 'Terms';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noOffersTitle => 'No offers found';

  @override
  String get noOffersHint => 'Try a different filter or create your own offer.';

  @override
  String get openTrade => 'Open trade';

  @override
  String get trade => 'Trade';

  @override
  String get tradeHistory => 'Trade history';

  @override
  String get tradeChat => 'Trade chat';

  @override
  String get dispute => 'Dispute';

  @override
  String get openDispute => 'Open dispute';

  @override
  String get fundEscrow => 'Fund escrow';

  @override
  String get markPaymentSent => 'Mark payment sent';

  @override
  String get markPaymentReceived => 'Confirm payment received';

  @override
  String get releaseEscrow => 'Release escrow';

  @override
  String get balance => 'Balance';

  @override
  String get depositAddress => 'Deposit address';

  @override
  String get generateNewAddress => 'Generate new address';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get destinationAddress => 'Destination address';

  @override
  String get amount => 'Amount';

  @override
  String get transactionHistory => 'Transaction history';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get send => 'Send';

  @override
  String get encryptWithPgp => 'Encrypt with PGP';

  @override
  String get messagePlaceholder => 'Type your message…';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'You\'re all caught up';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get publicProfile => 'Public profile';

  @override
  String get feedbackScore => 'Feedback score';

  @override
  String get trades => 'Trades';

  @override
  String get memberSince => 'Member since';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get trustLevel => 'Trust level';

  @override
  String get languages => 'Languages';

  @override
  String get savePgpKey => 'Save PGP key';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get users => 'Users';

  @override
  String get disputes => 'Disputes';

  @override
  String get moderation => 'Moderation';

  @override
  String get statistics => 'Statistics';

  @override
  String get ban => 'Ban';

  @override
  String get warn => 'Warn';

  @override
  String get verify => 'Verify';

  @override
  String get search_hint => 'Search offers by coin, currency or country';

  @override
  String get filter => 'Filter';

  @override
  String get sortByPrice => 'Sort by price';

  @override
  String get sortByReputation => 'Sort by reputation';

  @override
  String get sortByRecency => 'Sort by recency';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';
}
