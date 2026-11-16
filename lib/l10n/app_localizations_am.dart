// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'Maekel';

  @override
  String get tagline => 'Your Addis Ababa everyday app';

  @override
  String get phoneTitle => 'Sign in with phone';

  @override
  String get phoneSubtitle =>
      'We\'ll send a one-time code to your Ethiopian number.';

  @override
  String get phoneHint => '9XXXXXXXX';

  @override
  String get phonePrefix => '+251';

  @override
  String get continueLabel => 'Continue';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String get otpSubtitle => 'Mock OTP — use 123456 for now.';

  @override
  String get otpHint => '6-digit code';

  @override
  String get verifyLabel => 'Verify';

  @override
  String get signOut => 'Sign out';

  @override
  String get homeGreeting => 'What do you need in Addis today?';

  @override
  String get moduleRide => 'Ride';

  @override
  String get moduleRideDesc => 'Go across the city';

  @override
  String get moduleMarket => 'Market';

  @override
  String get moduleMarketDesc => 'Buy and sell nearby';

  @override
  String get moduleFood => 'Food';

  @override
  String get moduleFoodDesc => 'Order from local kitchens';

  @override
  String get moduleGames => 'Games';

  @override
  String get moduleGamesDesc => 'Quick play breaks';

  @override
  String get currencyEtb => 'ETB';

  @override
  String get rideTitle => 'Ride';

  @override
  String get rideConsumer => 'Request a ride';

  @override
  String get rideDriver => 'Drive with Maekel';

  @override
  String get rideStubBody =>
      'Ride matching and maps come in a later pass. This is the consumer placeholder.';

  @override
  String get rideDriverStubBody =>
      'Driver mode placeholder — availability, jobs, and earnings will live here.';

  @override
  String get marketTitle => 'Market';

  @override
  String get marketBrowse => 'Browse listings';

  @override
  String get marketSell => 'Sell something';

  @override
  String get marketStubBody =>
      'Jiji-style listings for Addis. Browse placeholder — real catalog later.';

  @override
  String get marketSellStubBody =>
      'Create a listing with photos and price in ETB. Upload flow comes later.';

  @override
  String get foodTitle => 'Food';

  @override
  String get foodStubBody =>
      'Restaurant browse and cart placeholders for Addis delivery.';

  @override
  String get gamesTitle => 'Games';

  @override
  String get gamesHubBody =>
      'Pick a game. Playable versions land in a later pass.';

  @override
  String get brickBreaker => 'Brick Breaker';

  @override
  String get brickBreakerStub =>
      'Brick Breaker stub — Flame gameplay comes later.';

  @override
  String get tetris => 'Tetris';

  @override
  String get tetrisStub => 'Tetris stub — playable board comes later.';

  @override
  String get candyCrush => 'Candy Crush';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get backHome => 'Back to home';
}
