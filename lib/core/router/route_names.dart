abstract final class RouteNames {
  // ---------------------------------------------------------------------------
  // Paths
  // ---------------------------------------------------------------------------
  static const String splash = '/splash';

  static const String onboarding = '/onboarding';
  static const String onboardingSeedBackup = '/onboarding/seed-backup';
  static const String onboardingBiometric = '/onboarding/biometric';

  static const String authPin = '/auth/pin';

  static const String home = '/home';
  static const String trading = '/home/trading';
  static const String wallet = '/home/wallet';
  static const String profile = '/home/profile';
  static const String settings = '/home/settings';

  static const String offerDetail = '/offer/:id';
  static const String trade = '/trade/:id';
  static const String tradeChat = '/trade/:id/chat';

  static const String notifications = '/notifications';

  // ---------------------------------------------------------------------------
  // Named route identifiers
  // ---------------------------------------------------------------------------
  static const String splashName = 'splash';

  static const String onboardingName = 'onboarding';
  static const String onboardingSeedBackupName = 'onboarding-seed-backup';
  static const String onboardingBiometricName = 'onboarding-biometric';

  static const String authPinName = 'auth-pin';

  static const String homeName = 'home';
  static const String tradingName = 'trading';
  static const String walletName = 'wallet';
  static const String profileName = 'profile';
  static const String settingsName = 'settings';

  static const String offerDetailName = 'offer-detail';
  static const String tradeName = 'trade';
  static const String tradeChatName = 'trade-chat';

  static const String notificationsName = 'notifications';

  // ---------------------------------------------------------------------------
  // Query parameters
  // ---------------------------------------------------------------------------
  static const String pinModeParam = 'mode'; // 'setup' | 'entry'
}
