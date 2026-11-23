import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Maekel'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your Addis Ababa everyday app'**
  String get tagline;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with phone'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a one-time code to your Ethiopian number.'**
  String get phoneSubtitle;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'9XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @phonePrefix.
  ///
  /// In en, this message translates to:
  /// **'+251'**
  String get phonePrefix;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mock OTP — use 123456 for now.'**
  String get otpSubtitle;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpHint;

  /// No description provided for @verifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyLabel;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'What do you need in Addis today?'**
  String get homeGreeting;

  /// No description provided for @moduleRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get moduleRide;

  /// No description provided for @moduleRideDesc.
  ///
  /// In en, this message translates to:
  /// **'Go across the city'**
  String get moduleRideDesc;

  /// No description provided for @moduleMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get moduleMarket;

  /// No description provided for @moduleMarketDesc.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell nearby'**
  String get moduleMarketDesc;

  /// No description provided for @moduleFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get moduleFood;

  /// No description provided for @moduleFoodDesc.
  ///
  /// In en, this message translates to:
  /// **'Order from local kitchens'**
  String get moduleFoodDesc;

  /// No description provided for @moduleEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get moduleEvents;

  /// No description provided for @moduleEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover and host in Addis'**
  String get moduleEventsDesc;

  /// No description provided for @moduleGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get moduleGames;

  /// No description provided for @moduleGamesDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick play breaks'**
  String get moduleGamesDesc;

  /// No description provided for @currencyEtb.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get currencyEtb;

  /// No description provided for @rideTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get rideTitle;

  /// No description provided for @rideConsumer.
  ///
  /// In en, this message translates to:
  /// **'Request a ride'**
  String get rideConsumer;

  /// No description provided for @rideDriver.
  ///
  /// In en, this message translates to:
  /// **'Drive with Maekel'**
  String get rideDriver;

  /// No description provided for @rideStubBody.
  ///
  /// In en, this message translates to:
  /// **'Ride matching and maps come in a later pass. This is the consumer placeholder.'**
  String get rideStubBody;

  /// No description provided for @rideDriverStubBody.
  ///
  /// In en, this message translates to:
  /// **'Driver mode placeholder — availability, jobs, and earnings will live here.'**
  String get rideDriverStubBody;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketTitle;

  /// No description provided for @marketBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse listings'**
  String get marketBrowse;

  /// No description provided for @marketSell.
  ///
  /// In en, this message translates to:
  /// **'Sell something'**
  String get marketSell;

  /// No description provided for @marketStubBody.
  ///
  /// In en, this message translates to:
  /// **'Jiji-style listings for Addis. Browse placeholder — real catalog later.'**
  String get marketStubBody;

  /// No description provided for @marketSellStubBody.
  ///
  /// In en, this message translates to:
  /// **'Create a listing with photos and price in ETB. Upload flow comes later.'**
  String get marketSellStubBody;

  /// No description provided for @foodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodTitle;

  /// No description provided for @foodStubBody.
  ///
  /// In en, this message translates to:
  /// **'Restaurant browse and cart placeholders for Addis delivery.'**
  String get foodStubBody;

  /// No description provided for @gamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesTitle;

  /// No description provided for @gamesHubBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a game. Playable versions land in a later pass.'**
  String get gamesHubBody;

  /// No description provided for @brickBreaker.
  ///
  /// In en, this message translates to:
  /// **'Brick Breaker'**
  String get brickBreaker;

  /// No description provided for @brickBreakerStub.
  ///
  /// In en, this message translates to:
  /// **'Brick Breaker stub — Flame gameplay comes later.'**
  String get brickBreakerStub;

  /// No description provided for @tetris.
  ///
  /// In en, this message translates to:
  /// **'Tetris'**
  String get tetris;

  /// No description provided for @tetrisStub.
  ///
  /// In en, this message translates to:
  /// **'Tetris stub — playable board comes later.'**
  String get tetrisStub;

  /// No description provided for @candyCrush.
  ///
  /// In en, this message translates to:
  /// **'Candy Crush'**
  String get candyCrush;

  /// No description provided for @roadFighter.
  ///
  /// In en, this message translates to:
  /// **'Road Fighter'**
  String get roadFighter;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backHome;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
