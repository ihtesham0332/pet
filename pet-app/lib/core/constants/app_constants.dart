class AppConstants {
  AppConstants._();

  static const String appName = 'Pet Health Assistant';
  static const String appVersion = '1.0.0';

  // ── Host Configuration ──────────────────────────────────────────
  // Physical Android/iOS device: set to your computer's LAN IP
  //   Find it: ipconfig (Windows) or ifconfig (Mac/Linux)
  //   Example: '192.168.1.100'
  //
  // Android emulator: leave as '10.0.2.2'
  // iOS simulator / Web: leave blank (uses 'localhost')
  static const String hostOverride = '';

  static String get host {
    if (hostOverride.isNotEmpty) return hostOverride;
    // Uses ADB reverse (physical USB) → localhost works
    // For Android emulator: set hostOverride = '10.0.2.2'
    return 'localhost';
  }
  static String get cloudApiBaseUrl => 'http://$host:8001';
  static const Duration apiTimeout = Duration(seconds: 120);

  // AI
  static const String aiApiKey = 'ak_2In46X2Gp5hD8QO7vW5Vr5EU2ME2B';

  // Limits
  static const int freeSymptomChecksPerMonth = 3;
  static const int maxPetsFreeTier = 1;
  static const int maxPetsPremiumTier = 5;

  // Subscription
  static const String freeTier = 'free';
  static const String premiumTier = 'premium';
  static const String proTier = 'pro';
  static const double premiumPrice = 9.99;
  static const double proPrice = 19.99;
}
