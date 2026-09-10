import 'package:flutter/foundation.dart' show kDebugMode;

class AppConstants {
  AppConstants._();

  static const String appName = 'Pet Health Assistant';
  static const String appVersion = '1.0.0';

  // ── Production Cloud URL ─────────────────────────────────────────
  // Set this to your deployed backend URL before publishing to
  // Google Play Store (e.g. 'https://pet-backend.railway.app').
  static const String productionApiUrl = 'https://api.pethealth.ai/v1';

  // ── Local Development Host ───────────────────────────────────────
  // Physical Android/iOS device: set to your computer's LAN IP
  //   Find it: ipconfig (Windows) or ifconfig (Mac/Linux)
  //   Example: '192.168.1.100'
  //
  // Android emulator: use '10.0.2.2'
  // iOS simulator / Web: leave blank (uses 'localhost')
  static const String hostOverride = '10.141.212.99';

  static String get host {
    if (hostOverride.isNotEmpty) return hostOverride;
    return 'localhost';
  }

  // ── API Base URL ─────────────────────────────────────────────────
  // Automatically picks the right URL based on build mode:
  //   • Debug  → local development server (your PC)
  //   • Release → production cloud server
  static String get cloudApiBaseUrl {
    if (kDebugMode) {
      return 'http://$host:8001';
    }
    return productionApiUrl;
  }

  // ── Timeouts ─────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // ── Retry Configuration ──────────────────────────────────────────
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

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
