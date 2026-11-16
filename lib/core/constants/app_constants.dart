import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const String appName = 'Maekel';
  static const String phoneCountryCode = '+251';
  static const String currencyCode = 'ETB';
  static const String cityName = 'Addis Ababa';
  static const String mockOtpCode = '123456';
  static const int otpLength = 6;
  static const int localPhoneLength = 9;

  /// Gateway BFF.
  /// - Android emulator → host loopback via 10.0.2.2
  /// - Chrome / desktop / iOS simulator → 127.0.0.1
  /// Override with --dart-define=API_BASE_URL=...
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }
}
