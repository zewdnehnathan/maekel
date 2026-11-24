import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_aa.dart';
import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_so.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ti.dart';
import 'app_localizations_zh.dart';

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
    Locale('aa'),
    Locale('am'),
    Locale('ar'),
    Locale('en'),
    Locale('om'),
    Locale('so'),
    Locale('sw'),
    Locale('ti'),
    Locale('zh'),
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
  /// **'Ride matching and maps come in a later pass.'**
  String get rideStubBody;

  /// No description provided for @rideDriverStubBody.
  ///
  /// In en, this message translates to:
  /// **'Driver mode — availability, jobs, and earnings.'**
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
  /// **'Classifieds for Addis.'**
  String get marketStubBody;

  /// No description provided for @marketSellStubBody.
  ///
  /// In en, this message translates to:
  /// **'Create a listing with photos and price in ETB.'**
  String get marketSellStubBody;

  /// No description provided for @foodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get foodTitle;

  /// No description provided for @foodStubBody.
  ///
  /// In en, this message translates to:
  /// **'Restaurant browse and cart for Addis delivery.'**
  String get foodStubBody;

  /// No description provided for @gamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesTitle;

  /// No description provided for @gamesHubBody.
  ///
  /// In en, this message translates to:
  /// **'Play offline, sync your best scores to the Addis board.'**
  String get gamesHubBody;

  /// No description provided for @brickBreaker.
  ///
  /// In en, this message translates to:
  /// **'Brick Breaker'**
  String get brickBreaker;

  /// No description provided for @brickBreakerStub.
  ///
  /// In en, this message translates to:
  /// **'Drag to move paddle · tap to launch'**
  String get brickBreakerStub;

  /// No description provided for @tetris.
  ///
  /// In en, this message translates to:
  /// **'Tetris'**
  String get tetris;

  /// No description provided for @tetrisStub.
  ///
  /// In en, this message translates to:
  /// **'Swipe · tap rotate · double-tap hard drop'**
  String get tetrisStub;

  /// No description provided for @candyCrush.
  ///
  /// In en, this message translates to:
  /// **'Match 3'**
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

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Maekel speaks to you'**
  String get languageSubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @soldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get soldOut;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @rideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go across Addis'**
  String get rideSubtitle;

  /// No description provided for @rideDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get rideDriveTitle;

  /// No description provided for @rideTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get rideTripTitle;

  /// No description provided for @rideTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get rideTripsTitle;

  /// No description provided for @rideOpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride ops'**
  String get rideOpsTitle;

  /// No description provided for @rideSetPickup.
  ///
  /// In en, this message translates to:
  /// **'Set pickup'**
  String get rideSetPickup;

  /// No description provided for @rideSetDropoff.
  ///
  /// In en, this message translates to:
  /// **'Set dropoff'**
  String get rideSetDropoff;

  /// No description provided for @rideUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get rideUseMyLocation;

  /// No description provided for @rideGetQuote.
  ///
  /// In en, this message translates to:
  /// **'Get upfront quote'**
  String get rideGetQuote;

  /// No description provided for @rideRequest.
  ///
  /// In en, this message translates to:
  /// **'Request ride'**
  String get rideRequest;

  /// No description provided for @rideEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get rideEconomy;

  /// No description provided for @rideActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Active trip'**
  String get rideActiveTrip;

  /// No description provided for @rideOutsideServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Pickup or drop-off is outside the Addis Ababa service area.'**
  String get rideOutsideServiceArea;

  /// No description provided for @rideNoTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet.'**
  String get rideNoTripsYet;

  /// No description provided for @rideCancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get rideCancelTrip;

  /// No description provided for @rideRateDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate your driver'**
  String get rideRateDriver;

  /// No description provided for @rideSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get rideSubmitRating;

  /// No description provided for @rideTripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get rideTripNotFound;

  /// No description provided for @rideNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No online drivers nearby. Ask a test driver to go Online on Drive, then Request again.'**
  String get rideNoDrivers;

  /// No description provided for @rideDriverEta.
  ///
  /// In en, this message translates to:
  /// **'Driver ETA about {minutes} min'**
  String rideDriverEta(Object minutes);

  /// No description provided for @rideArrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in about {minutes} min'**
  String rideArrivingIn(Object minutes);

  /// No description provided for @rideYouRated.
  ///
  /// In en, this message translates to:
  /// **'You rated {rating}★'**
  String rideYouRated(Object rating);

  /// No description provided for @rideFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {place}'**
  String rideFrom(String place);

  /// No description provided for @rideTo.
  ///
  /// In en, this message translates to:
  /// **'To: {place}'**
  String rideTo(String place);

  /// No description provided for @rideFareEtb.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB'**
  String rideFareEtb(Object amount);

  /// No description provided for @ridePendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Ride ops approval before you can go online.'**
  String get ridePendingApproval;

  /// No description provided for @rideActiveJob.
  ///
  /// In en, this message translates to:
  /// **'Active job'**
  String get rideActiveJob;

  /// No description provided for @rideCompleteCash.
  ///
  /// In en, this message translates to:
  /// **'Complete + confirm cash'**
  String get rideCompleteCash;

  /// No description provided for @rideReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get rideReportProblem;

  /// No description provided for @ridePassengerNoShow.
  ///
  /// In en, this message translates to:
  /// **'Passenger no-show'**
  String get ridePassengerNoShow;

  /// No description provided for @rideWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong pin'**
  String get rideWrongPin;

  /// No description provided for @rideOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get rideOffers;

  /// No description provided for @rideGoOnlineHint.
  ///
  /// In en, this message translates to:
  /// **'Go online to see matching requests.'**
  String get rideGoOnlineHint;

  /// No description provided for @rideNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No open offers right now. When a passenger requests nearby, the offer appears here with a time limit.'**
  String get rideNoOffers;

  /// No description provided for @rideTodaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s earnings'**
  String get rideTodaysEarnings;

  /// No description provided for @rideFareConfig.
  ///
  /// In en, this message translates to:
  /// **'Fare config'**
  String get rideFareConfig;

  /// No description provided for @rideSaveFareParams.
  ///
  /// In en, this message translates to:
  /// **'Save fare params'**
  String get rideSaveFareParams;

  /// No description provided for @rideDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers ({count})'**
  String rideDrivers(int count);

  /// No description provided for @rideActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Active trips ({count})'**
  String rideActiveTrips(int count);

  /// No description provided for @rideNoActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'No active trips.'**
  String get rideNoActiveTrips;

  /// No description provided for @rideForceCancel.
  ///
  /// In en, this message translates to:
  /// **'Force cancel'**
  String get rideForceCancel;

  /// No description provided for @rideFareConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Fare config saved'**
  String get rideFareConfigSaved;

  /// No description provided for @rideMapHint.
  ///
  /// In en, this message translates to:
  /// **'+/− zoom · click to pin · drag to pan'**
  String get rideMapHint;

  /// No description provided for @rideFareDueCash.
  ///
  /// In en, this message translates to:
  /// **'Fare due: {amount} ETB cash'**
  String rideFareDueCash(Object amount);

  /// No description provided for @marketSellAction.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get marketSellAction;

  /// No description provided for @marketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buy & sell in Addis'**
  String get marketSubtitle;

  /// No description provided for @marketBlurb.
  ///
  /// In en, this message translates to:
  /// **'Classifieds with chat. Inspect before you pay.'**
  String get marketBlurb;

  /// No description provided for @marketSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search phones, cars, furniture…'**
  String get marketSearchHint;

  /// No description provided for @marketCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get marketCategories;

  /// No description provided for @marketNearYou.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get marketNearYou;

  /// No description provided for @marketAdsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ads'**
  String marketAdsCount(int count);

  /// No description provided for @marketNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No listings match. Try another area or clear filters.'**
  String get marketNoMatch;

  /// No description provided for @marketAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get marketAllAreas;

  /// No description provided for @marketCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get marketCondition;

  /// No description provided for @marketAnyCondition.
  ///
  /// In en, this message translates to:
  /// **'Any condition'**
  String get marketAnyCondition;

  /// No description provided for @marketPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get marketPriceRange;

  /// No description provided for @marketPriceRangeEtb.
  ///
  /// In en, this message translates to:
  /// **'Price range (ETB)'**
  String get marketPriceRangeEtb;

  /// No description provided for @marketMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get marketMinimum;

  /// No description provided for @marketMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get marketMaximum;

  /// No description provided for @marketMinMaxError.
  ///
  /// In en, this message translates to:
  /// **'Minimum cannot be higher than maximum.'**
  String get marketMinMaxError;

  /// No description provided for @marketSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get marketSortNewest;

  /// No description provided for @marketSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get marketSortPriceLow;

  /// No description provided for @marketSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get marketSortPriceHigh;

  /// No description provided for @marketAdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ad not found'**
  String get marketAdNotFound;

  /// No description provided for @marketSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get marketSeller;

  /// No description provided for @marketChatSeller.
  ///
  /// In en, this message translates to:
  /// **'Chat with seller'**
  String get marketChatSeller;

  /// No description provided for @marketCallSeller.
  ///
  /// In en, this message translates to:
  /// **'Call seller'**
  String get marketCallSeller;

  /// No description provided for @marketSellerHidPhone.
  ///
  /// In en, this message translates to:
  /// **'Seller hid their phone. Use chat.'**
  String get marketSellerHidPhone;

  /// No description provided for @marketYourListing.
  ///
  /// In en, this message translates to:
  /// **'This is your listing.'**
  String get marketYourListing;

  /// No description provided for @marketEditListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get marketEditListing;

  /// No description provided for @marketReportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get marketReportListing;

  /// No description provided for @marketReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent to ops.'**
  String get marketReportSent;

  /// No description provided for @marketNoAdsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No ads in this category yet.'**
  String get marketNoAdsInCategory;

  /// No description provided for @marketNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No saved ads yet.'**
  String get marketNoFavorites;

  /// No description provided for @marketNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet. Open an ad and tap Chat.'**
  String get marketNoChats;

  /// No description provided for @marketShowPhone.
  ///
  /// In en, this message translates to:
  /// **'Show phone on ads'**
  String get marketShowPhone;

  /// No description provided for @marketNoAdsYet.
  ///
  /// In en, this message translates to:
  /// **'No ads yet'**
  String get marketNoAdsYet;

  /// No description provided for @marketPostSomething.
  ///
  /// In en, this message translates to:
  /// **'Post something to sell in Addis.'**
  String get marketPostSomething;

  /// No description provided for @marketSellNow.
  ///
  /// In en, this message translates to:
  /// **'Sell now'**
  String get marketSellNow;

  /// No description provided for @marketMarkSold.
  ///
  /// In en, this message translates to:
  /// **'Mark sold'**
  String get marketMarkSold;

  /// No description provided for @marketBeforeContact.
  ///
  /// In en, this message translates to:
  /// **'Before you contact'**
  String get marketBeforeContact;

  /// No description provided for @marketIUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get marketIUnderstand;

  /// No description provided for @marketMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Max 8 photos.'**
  String get marketMaxPhotos;

  /// No description provided for @marketPickCategoryArea.
  ///
  /// In en, this message translates to:
  /// **'Pick a category and area.'**
  String get marketPickCategoryArea;

  /// No description provided for @marketAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get marketAddPhoto;

  /// No description provided for @marketKeyDetails.
  ///
  /// In en, this message translates to:
  /// **'Key details'**
  String get marketKeyDetails;

  /// No description provided for @marketOpsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending ads ({count})'**
  String marketOpsPending(int count);

  /// No description provided for @marketOpsQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue empty — nothing to moderate.'**
  String get marketOpsQueueEmpty;

  /// No description provided for @marketOpsReports.
  ///
  /// In en, this message translates to:
  /// **'Open reports ({count})'**
  String marketOpsReports(int count);

  /// No description provided for @marketOpsNoReports.
  ///
  /// In en, this message translates to:
  /// **'No open reports.'**
  String get marketOpsNoReports;

  /// No description provided for @marketOpsCategories.
  ///
  /// In en, this message translates to:
  /// **'Category config ({count})'**
  String marketOpsCategories(int count);

  /// No description provided for @marketOpsNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Add the first one to unlock Sell.'**
  String get marketOpsNoCategories;

  /// No description provided for @marketOpsLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get marketOpsLimits;

  /// No description provided for @marketOpsSuspendSeller.
  ///
  /// In en, this message translates to:
  /// **'Suspend seller'**
  String get marketOpsSuspendSeller;

  /// No description provided for @marketOpsUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get marketOpsUnpublish;

  /// No description provided for @marketOpsSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get marketOpsSuspend;

  /// No description provided for @marketOpsOpenAd.
  ///
  /// In en, this message translates to:
  /// **'Open ad'**
  String get marketOpsOpenAd;

  /// No description provided for @marketOpsRejectAd.
  ///
  /// In en, this message translates to:
  /// **'Reject ad'**
  String get marketOpsRejectAd;

  /// No description provided for @marketOpsAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get marketOpsAddCategory;

  /// No description provided for @marketOpsMaxFreeAds.
  ///
  /// In en, this message translates to:
  /// **'Max active free ads'**
  String get marketOpsMaxFreeAds;

  /// No description provided for @foodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver in Addis'**
  String get foodSubtitle;

  /// No description provided for @foodBlurb.
  ///
  /// In en, this message translates to:
  /// **'Restaurants & groceries · COD · OTP handover'**
  String get foodBlurb;

  /// No description provided for @foodDeliveryPin.
  ///
  /// In en, this message translates to:
  /// **'Delivery pin'**
  String get foodDeliveryPin;

  /// No description provided for @foodSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search merchants or dishes…'**
  String get foodSearchHint;

  /// No description provided for @foodRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get foodRestaurants;

  /// No description provided for @foodGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get foodGroceries;

  /// No description provided for @foodNoMerchants.
  ///
  /// In en, this message translates to:
  /// **'No merchants deliver to {pin}'**
  String foodNoMerchants(String pin);

  /// No description provided for @foodTryOtherPin.
  ///
  /// In en, this message translates to:
  /// **'Try another delivery pin nearby.'**
  String get foodTryOtherPin;

  /// No description provided for @foodMerchantConsole.
  ///
  /// In en, this message translates to:
  /// **'Merchant console'**
  String get foodMerchantConsole;

  /// No description provided for @foodRider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get foodRider;

  /// No description provided for @foodOps.
  ///
  /// In en, this message translates to:
  /// **'Food ops'**
  String get foodOps;

  /// No description provided for @foodCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get foodCartEmpty;

  /// No description provided for @foodCheckoutCod.
  ///
  /// In en, this message translates to:
  /// **'Checkout · COD'**
  String get foodCheckoutCod;

  /// No description provided for @foodMinOrder.
  ///
  /// In en, this message translates to:
  /// **'Min order {amount} ETB'**
  String foodMinOrder(Object amount);

  /// No description provided for @foodAddressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get foodAddressSaved;

  /// No description provided for @foodCodBlurb.
  ///
  /// In en, this message translates to:
  /// **'Pay cash on delivery. Delivery fee shown before you confirm — no surprises.'**
  String get foodCodBlurb;

  /// No description provided for @foodSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get foodSavedPlaces;

  /// No description provided for @foodNoSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet — fill address below and tap Save.'**
  String get foodNoSavedPlaces;

  /// No description provided for @foodMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get foodMenu;

  /// No description provided for @foodAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get foodAddToCart;

  /// No description provided for @foodAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String foodAdded(String name);

  /// No description provided for @foodReplaceCart.
  ///
  /// In en, this message translates to:
  /// **'Replace cart?'**
  String get foodReplaceCart;

  /// No description provided for @foodClearAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Clear & add'**
  String get foodClearAndAdd;

  /// No description provided for @foodCartTotal.
  ///
  /// In en, this message translates to:
  /// **'Cart · {amount} ETB'**
  String foodCartTotal(Object amount);

  /// No description provided for @foodOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get foodOrdersTitle;

  /// No description provided for @foodNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get foodNoOrders;

  /// No description provided for @foodOrderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get foodOrderNotFound;

  /// No description provided for @foodItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get foodItems;

  /// No description provided for @foodDeliveryOtp.
  ///
  /// In en, this message translates to:
  /// **'Delivery OTP'**
  String get foodDeliveryOtp;

  /// No description provided for @foodDeliveryOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Show this code to the rider. They collect COD and enter OTP in the rider app.'**
  String get foodDeliveryOtpHint;

  /// No description provided for @foodCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get foodCancelOrder;

  /// No description provided for @foodCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'You can no longer cancel. The shop has already started preparing this order.'**
  String get foodCannotCancel;

  /// No description provided for @foodNoRestaurant.
  ///
  /// In en, this message translates to:
  /// **'No restaurant linked yet'**
  String get foodNoRestaurant;

  /// No description provided for @foodOpenOps.
  ///
  /// In en, this message translates to:
  /// **'Open Food ops'**
  String get foodOpenOps;

  /// No description provided for @foodAddDish.
  ///
  /// In en, this message translates to:
  /// **'Add dish'**
  String get foodAddDish;

  /// No description provided for @foodNoDishes.
  ///
  /// In en, this message translates to:
  /// **'No dishes yet. Add name + price so customers can order.'**
  String get foodNoDishes;

  /// No description provided for @foodOrderQueue.
  ///
  /// In en, this message translates to:
  /// **'Order queue ({count})'**
  String foodOrderQueue(int count);

  /// No description provided for @foodNoKitchenOrders.
  ///
  /// In en, this message translates to:
  /// **'No open kitchen orders.'**
  String get foodNoKitchenOrders;

  /// No description provided for @foodPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get foodPickup;

  /// No description provided for @foodDropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get foodDropoff;

  /// No description provided for @foodClaimJob.
  ///
  /// In en, this message translates to:
  /// **'Claim job'**
  String get foodClaimJob;

  /// No description provided for @foodPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get foodPickedUp;

  /// No description provided for @foodOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get foodOnTheWay;

  /// No description provided for @foodCompleteCod.
  ///
  /// In en, this message translates to:
  /// **'Complete + COD'**
  String get foodCompleteCod;

  /// No description provided for @foodMyJobs.
  ///
  /// In en, this message translates to:
  /// **'My jobs ({count})'**
  String foodMyJobs(int count);

  /// No description provided for @foodNoActiveDelivery.
  ///
  /// In en, this message translates to:
  /// **'No active delivery.'**
  String get foodNoActiveDelivery;

  /// No description provided for @foodAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available ({count})'**
  String foodAvailable(int count);

  /// No description provided for @foodNoReadyOrders.
  ///
  /// In en, this message translates to:
  /// **'No ready orders waiting for a rider.'**
  String get foodNoReadyOrders;

  /// No description provided for @foodConfirmCod.
  ///
  /// In en, this message translates to:
  /// **'Confirm COD'**
  String get foodConfirmCod;

  /// No description provided for @foodCollectCod.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount} ETB COD'**
  String foodCollectCod(Object amount);

  /// No description provided for @foodOrderBoard.
  ///
  /// In en, this message translates to:
  /// **'Order board ({count})'**
  String foodOrderBoard(int count);

  /// No description provided for @foodNoRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'No recent orders.'**
  String get foodNoRecentOrders;

  /// No description provided for @foodOnboardMerchant.
  ///
  /// In en, this message translates to:
  /// **'Onboard merchant'**
  String get foodOnboardMerchant;

  /// No description provided for @foodCreateMerchant.
  ///
  /// In en, this message translates to:
  /// **'Create merchant'**
  String get foodCreateMerchant;

  /// No description provided for @foodMerchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants ({count})'**
  String foodMerchants(int count);

  /// No description provided for @foodSupportCancel.
  ///
  /// In en, this message translates to:
  /// **'Support cancel'**
  String get foodSupportCancel;

  /// No description provided for @foodClearRider.
  ///
  /// In en, this message translates to:
  /// **'Clear rider'**
  String get foodClearRider;

  /// No description provided for @foodAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get foodAssign;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsOps.
  ///
  /// In en, this message translates to:
  /// **'Events ops'**
  String get eventsOps;

  /// No description provided for @eventsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventsCreate;

  /// No description provided for @eventsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events, venues…'**
  String get eventsSearchHint;

  /// No description provided for @eventsAnyArea.
  ///
  /// In en, this message translates to:
  /// **'Any area'**
  String get eventsAnyArea;

  /// No description provided for @eventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events yet. Host one from the + button.'**
  String get eventsEmpty;

  /// No description provided for @eventsRsvpConfirmed.
  ///
  /// In en, this message translates to:
  /// **'RSVP confirmed · {code}'**
  String eventsRsvpConfirmed(String code);

  /// No description provided for @eventsRsvpCancelled.
  ///
  /// In en, this message translates to:
  /// **'RSVP cancelled'**
  String get eventsRsvpCancelled;

  /// No description provided for @eventsYourTicket.
  ///
  /// In en, this message translates to:
  /// **'Your ticket'**
  String get eventsYourTicket;

  /// No description provided for @eventsCancelRsvp.
  ///
  /// In en, this message translates to:
  /// **'Cancel RSVP'**
  String get eventsCancelRsvp;

  /// No description provided for @eventsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review — Events ops must approve.'**
  String get eventsSubmitted;

  /// No description provided for @eventsStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventsStarts;

  /// No description provided for @eventsPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get eventsPick;

  /// No description provided for @eventsCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get eventsCheckedIn;

  /// No description provided for @eventsNotHosted.
  ///
  /// In en, this message translates to:
  /// **'You have not hosted an event yet.'**
  String get eventsNotHosted;

  /// No description provided for @eventsAttendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get eventsAttendees;

  /// No description provided for @eventsDoorCode.
  ///
  /// In en, this message translates to:
  /// **'Door code: {code}'**
  String eventsDoorCode(String code);

  /// No description provided for @eventsCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get eventsCheckIn;

  /// No description provided for @eventsNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet. RSVP from Browse.'**
  String get eventsNoTickets;

  /// No description provided for @eventsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String eventsPending(int count);

  /// No description provided for @eventsQueueClear.
  ///
  /// In en, this message translates to:
  /// **'Queue clear.'**
  String get eventsQueueClear;

  /// No description provided for @eventsLive.
  ///
  /// In en, this message translates to:
  /// **'Live ({count})'**
  String eventsLive(int count);

  /// No description provided for @eventsForceCancel.
  ///
  /// In en, this message translates to:
  /// **'Force cancel'**
  String get eventsForceCancel;

  /// No description provided for @eventsSuspendOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Suspend organizer'**
  String get eventsSuspendOrganizer;

  /// No description provided for @eventsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject event'**
  String get eventsReject;

  /// No description provided for @eventsMyEvents.
  ///
  /// In en, this message translates to:
  /// **'My events'**
  String get eventsMyEvents;

  /// No description provided for @eventsTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get eventsTickets;

  /// No description provided for @gamesQuickPlay.
  ///
  /// In en, this message translates to:
  /// **'Quick play'**
  String get gamesQuickPlay;

  /// No description provided for @gamesAddisTop3.
  ///
  /// In en, this message translates to:
  /// **'Addis top 3'**
  String get gamesAddisTop3;

  /// No description provided for @gamesLeaderboardOffline.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard offline — start backend games-service to see Addis top 3.'**
  String get gamesLeaderboardOffline;

  /// No description provided for @gamesTop3Title.
  ///
  /// In en, this message translates to:
  /// **'Top 3 · Addis · {game}'**
  String gamesTop3Title(String game);

  /// No description provided for @gamesNoScores.
  ///
  /// In en, this message translates to:
  /// **'No scores yet — be the first in Addis.'**
  String get gamesNoScores;

  /// No description provided for @gamesScoreNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Score not saved — username required.'**
  String get gamesScoreNotSaved;

  /// No description provided for @gamesSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sync score. Is the API running?'**
  String get gamesSyncFailed;

  /// No description provided for @gamesChooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get gamesChooseUsername;

  /// No description provided for @gamesUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the Addis Ababa top 3 leaderboard.'**
  String get gamesUsernameHint;

  /// No description provided for @gamesSaveScore.
  ///
  /// In en, this message translates to:
  /// **'Save score'**
  String get gamesSaveScore;

  /// No description provided for @gamesTapToLaunch.
  ///
  /// In en, this message translates to:
  /// **'Tap to launch'**
  String get gamesTapToLaunch;

  /// No description provided for @gamesBrickHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to move paddle · tap to launch'**
  String get gamesBrickHint;

  /// No description provided for @gamesCandyHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a candy onto a neighbor · or tap-tap to swap'**
  String get gamesCandyHint;

  /// No description provided for @gamesTetrisHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe · tap rotate · double-tap hard drop'**
  String get gamesTetrisHint;

  /// No description provided for @gamesRoadHint.
  ///
  /// In en, this message translates to:
  /// **'◀ ▶ dodge · purple-stripe cars change lanes · grab F for fuel'**
  String get gamesRoadHint;

  /// No description provided for @gamesFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get gamesFuel;

  /// No description provided for @gamesTetrisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stack · clear lines · level up'**
  String get gamesTetrisSubtitle;

  /// No description provided for @gamesBrickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bounce · smash bricks · survive'**
  String get gamesBrickSubtitle;

  /// No description provided for @gamesCandySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Swap · match 3 · cascade score'**
  String get gamesCandySubtitle;

  /// No description provided for @gamesRoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dodge · fuel up · drive farther'**
  String get gamesRoadSubtitle;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff & admins'**
  String get adminTitle;

  /// No description provided for @adminPlatformOnly.
  ///
  /// In en, this message translates to:
  /// **'Platform admin only'**
  String get adminPlatformOnly;

  /// No description provided for @adminGrantRole.
  ///
  /// In en, this message translates to:
  /// **'Grant role'**
  String get adminGrantRole;

  /// No description provided for @adminGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get adminGrant;

  /// No description provided for @adminStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff ({count})'**
  String adminStaff(int count);

  /// No description provided for @adminNoStaff.
  ///
  /// In en, this message translates to:
  /// **'No staff roles assigned yet.'**
  String get adminNoStaff;

  /// No description provided for @adminRoleGranted.
  ///
  /// In en, this message translates to:
  /// **'Role granted. They must sign out and OTP again to refresh the JWT.'**
  String get adminRoleGranted;

  /// No description provided for @adminMarketModerator.
  ///
  /// In en, this message translates to:
  /// **'Market moderator'**
  String get adminMarketModerator;

  /// No description provided for @adminPlatformAdmin.
  ///
  /// In en, this message translates to:
  /// **'Platform admin'**
  String get adminPlatformAdmin;

  /// No description provided for @adminMarketOps.
  ///
  /// In en, this message translates to:
  /// **'Market ops'**
  String get adminMarketOps;

  /// No description provided for @adminFoodOps.
  ///
  /// In en, this message translates to:
  /// **'Food ops'**
  String get adminFoodOps;

  /// No description provided for @adminFoodMerchant.
  ///
  /// In en, this message translates to:
  /// **'Food merchant'**
  String get adminFoodMerchant;

  /// No description provided for @adminFoodRider.
  ///
  /// In en, this message translates to:
  /// **'Food rider'**
  String get adminFoodRider;

  /// No description provided for @adminRideOps.
  ///
  /// In en, this message translates to:
  /// **'Ride ops'**
  String get adminRideOps;

  /// No description provided for @adminEventsOps.
  ///
  /// In en, this message translates to:
  /// **'Events ops'**
  String get adminEventsOps;

  /// No description provided for @rideStatusQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get rideStatusQuote;

  /// No description provided for @rideStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get rideStatusRequested;

  /// No description provided for @rideStatusMatching.
  ///
  /// In en, this message translates to:
  /// **'Finding driver'**
  String get rideStatusMatching;

  /// No description provided for @rideStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get rideStatusAssigned;

  /// No description provided for @rideStatusArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver arriving'**
  String get rideStatusArriving;

  /// No description provided for @rideStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived'**
  String get rideStatusArrived;

  /// No description provided for @rideStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get rideStatusInProgress;

  /// No description provided for @rideStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get rideStatusCompleted;

  /// No description provided for @rideStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get rideStatusCancelled;

  /// No description provided for @rideNavRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get rideNavRide;

  /// No description provided for @rideNavTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get rideNavTrips;

  /// No description provided for @rideNavDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get rideNavDrive;

  /// No description provided for @rideStartArriving.
  ///
  /// In en, this message translates to:
  /// **'Start arriving'**
  String get rideStartArriving;

  /// No description provided for @rideMarkArrived.
  ///
  /// In en, this message translates to:
  /// **'Mark arrived'**
  String get rideMarkArrived;

  /// No description provided for @rideStartTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get rideStartTrip;

  /// No description provided for @rideAdvance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get rideAdvance;

  /// No description provided for @rideExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get rideExpired;

  /// No description provided for @rideRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get rideRefreshing;

  /// No description provided for @rideCompletedTripsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} completed trip(s) today'**
  String rideCompletedTripsToday(int count);

  /// No description provided for @rideRouteArrow.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String rideRouteArrow(String from, String to);

  /// No description provided for @rideFareStatusCountdown.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB · {status} · {countdown}'**
  String rideFareStatusCountdown(
    Object amount,
    String status,
    String countdown,
  );

  /// No description provided for @rideReported.
  ///
  /// In en, this message translates to:
  /// **'Reported: {reason}'**
  String rideReported(String reason);

  /// No description provided for @rideActiveTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Active trip · {status}'**
  String rideActiveTripStatus(String status);

  /// No description provided for @rideVehicleFare.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB · {vehicle}'**
  String rideVehicleFare(Object amount, String vehicle);

  /// No description provided for @rideDriverMeta.
  ///
  /// In en, this message translates to:
  /// **'{car} · {plate} · ★ {rating}'**
  String rideDriverMeta(String car, String plate, Object rating);

  /// No description provided for @marketConditionNew.
  ///
  /// In en, this message translates to:
  /// **'Brand new'**
  String get marketConditionNew;

  /// No description provided for @marketConditionUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get marketConditionUsed;

  /// No description provided for @marketConditionRefurbished.
  ///
  /// In en, this message translates to:
  /// **'Refurbished'**
  String get marketConditionRefurbished;

  /// No description provided for @marketStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get marketStatusPending;

  /// No description provided for @marketStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get marketStatusActive;

  /// No description provided for @marketStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get marketStatusDeclined;

  /// No description provided for @marketStatusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get marketStatusSold;

  /// No description provided for @marketNavBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get marketNavBrowse;

  /// No description provided for @marketNavMyAds.
  ///
  /// In en, this message translates to:
  /// **'My ads'**
  String get marketNavMyAds;

  /// No description provided for @marketNavSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get marketNavSaved;

  /// No description provided for @marketNavChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get marketNavChats;

  /// No description provided for @marketSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Meet in a public place. Inspect before you pay. Never send deposits to strangers. Maekel staff never ask for fees in chat.'**
  String get marketSafetyBody;

  /// No description provided for @marketSafetyShort.
  ///
  /// In en, this message translates to:
  /// **'Safety: Meet in public. Inspect before paying. Never send deposits to strangers.'**
  String get marketSafetyShort;

  /// No description provided for @marketPriceEtb.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB'**
  String marketPriceEtb(String amount);

  /// No description provided for @marketSubcityCondition.
  ///
  /// In en, this message translates to:
  /// **'{subcity} · {condition}'**
  String marketSubcityCondition(String subcity, String condition);

  /// No description provided for @marketPriceSubcity.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB · {subcity}'**
  String marketPriceSubcity(Object amount, String subcity);

  /// No description provided for @marketCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get marketCategoryTitle;

  /// No description provided for @marketChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get marketChatTitle;

  /// No description provided for @marketFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get marketFavoritesTitle;

  /// No description provided for @foodStatusPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get foodStatusPlaced;

  /// No description provided for @foodStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get foodStatusConfirmed;

  /// No description provided for @foodStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get foodStatusPreparing;

  /// No description provided for @foodStatusReadyPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get foodStatusReadyPickup;

  /// No description provided for @foodStatusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get foodStatusPickedUp;

  /// No description provided for @foodStatusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get foodStatusOnTheWay;

  /// No description provided for @foodStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get foodStatusDelivered;

  /// No description provided for @foodStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get foodStatusCancelled;

  /// No description provided for @foodClosedHours.
  ///
  /// In en, this message translates to:
  /// **'Closed · {hours}'**
  String foodClosedHours(String hours);

  /// No description provided for @foodOrderLine.
  ///
  /// In en, this message translates to:
  /// **'{qty}× {name} — {amount} ETB'**
  String foodOrderLine(Object qty, String name, Object amount);

  /// No description provided for @foodOrderSummary.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB · {count} item(s)'**
  String foodOrderSummary(Object amount, int count);

  /// No description provided for @foodTotalCod.
  ///
  /// In en, this message translates to:
  /// **'Total {amount} ETB · COD'**
  String foodTotalCod(Object amount);

  /// No description provided for @foodOrderBoardLine.
  ///
  /// In en, this message translates to:
  /// **'{merchant} → {subcity} · {amount} ETB'**
  String foodOrderBoardLine(String merchant, String subcity, Object amount);

  /// No description provided for @foodUnitPriceEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB each'**
  String foodUnitPriceEach(Object amount);

  /// No description provided for @foodNoDeliverPin.
  ///
  /// In en, this message translates to:
  /// **'No merchants deliver to {pin}'**
  String foodNoDeliverPin(String pin);

  /// No description provided for @foodMerchantTitle.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get foodMerchantTitle;

  /// No description provided for @foodOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get foodOrderTitle;

  /// No description provided for @foodCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get foodCartTitle;

  /// No description provided for @eventsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventsEditTitle;

  /// No description provided for @eventsFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get eventsFieldTitle;

  /// No description provided for @eventsFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventsFieldDescription;

  /// No description provided for @eventsFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get eventsFieldCategory;

  /// No description provided for @eventsFieldSubcity.
  ///
  /// In en, this message translates to:
  /// **'Subcity'**
  String get eventsFieldSubcity;

  /// No description provided for @eventsFieldVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get eventsFieldVenue;

  /// No description provided for @eventsFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get eventsFieldAddress;

  /// No description provided for @eventsFieldCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get eventsFieldCapacity;

  /// No description provided for @eventsFieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price ETB (0 = free)'**
  String get eventsFieldPrice;

  /// No description provided for @eventsPayAtDoor.
  ///
  /// In en, this message translates to:
  /// **'Guests pay at the door (COD-style).'**
  String get eventsPayAtDoor;

  /// No description provided for @eventsFreeRsvp.
  ///
  /// In en, this message translates to:
  /// **'Free RSVP.'**
  String get eventsFreeRsvp;

  /// No description provided for @eventsSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get eventsSubmitReview;

  /// No description provided for @eventsWhenSubcity.
  ///
  /// In en, this message translates to:
  /// **'{when} · {subcity}'**
  String eventsWhenSubcity(String when, String subcity);

  /// No description provided for @eventsVenueCategory.
  ///
  /// In en, this message translates to:
  /// **'{venue} · {category}'**
  String eventsVenueCategory(String venue, String category);

  /// No description provided for @eventsTicketQtyStatus.
  ///
  /// In en, this message translates to:
  /// **'Qty {qty} · {status}'**
  String eventsTicketQtyStatus(Object qty, String status);

  /// No description provided for @eventsHostMeta.
  ///
  /// In en, this message translates to:
  /// **'{status} · {sold}/{capacity} · {subcity}'**
  String eventsHostMeta(
    String status,
    Object sold,
    Object capacity,
    String subcity,
  );

  /// No description provided for @gamesScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gamesScore;

  /// No description provided for @gamesLives.
  ///
  /// In en, this message translates to:
  /// **'Lives'**
  String get gamesLives;

  /// No description provided for @gamesMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get gamesMoves;

  /// No description provided for @gamesCombo.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get gamesCombo;

  /// No description provided for @gamesRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get gamesRestart;

  /// No description provided for @gamesPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gamesPause;

  /// No description provided for @gamesResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get gamesResume;

  /// No description provided for @gamesMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get gamesMute;

  /// No description provided for @gamesUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get gamesUnmute;

  /// No description provided for @gamesRefreshBoard.
  ///
  /// In en, this message translates to:
  /// **'Refresh leaderboard'**
  String get gamesRefreshBoard;

  /// No description provided for @gamesPersonalBest.
  ///
  /// In en, this message translates to:
  /// **'New personal best: {score}'**
  String gamesPersonalBest(Object score);

  /// No description provided for @gamesScoreSavedBest.
  ///
  /// In en, this message translates to:
  /// **'Score saved. Best remains {score}'**
  String gamesScoreSavedBest(Object score);

  /// No description provided for @gamesUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get gamesUsernameLabel;

  /// No description provided for @gamesUsernameHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. BoleAce'**
  String get gamesUsernameHintExample;

  /// No description provided for @adminPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter a {count}-digit local number.'**
  String adminPhoneDigits(int count);

  /// No description provided for @adminRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked {role} from {phone}'**
  String adminRevoked(String role, String phone);

  /// No description provided for @adminNoAdminPhones.
  ///
  /// In en, this message translates to:
  /// **'No ADMIN_PHONES configured on the API. Set that env var to bootstrap the first platform admin.'**
  String get adminNoAdminPhones;

  /// No description provided for @adminBootstrapPhones.
  ///
  /// In en, this message translates to:
  /// **'Bootstrap phones (env): {phones}'**
  String adminBootstrapPhones(String phones);

  /// No description provided for @gamesGameOver.
  ///
  /// In en, this message translates to:
  /// **'GAME OVER'**
  String get gamesGameOver;

  /// No description provided for @gamesPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get gamesPaused;

  /// No description provided for @gamesOutOfMoves.
  ///
  /// In en, this message translates to:
  /// **'OUT OF MOVES'**
  String get gamesOutOfMoves;

  /// No description provided for @gamesOutOfFuel.
  ///
  /// In en, this message translates to:
  /// **'OUT OF FUEL'**
  String get gamesOutOfFuel;

  /// No description provided for @gamesCrash.
  ///
  /// In en, this message translates to:
  /// **'CRASH!'**
  String get gamesCrash;

  /// No description provided for @gamesLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get gamesLines;

  /// No description provided for @gamesLevel.
  ///
  /// In en, this message translates to:
  /// **'Lvl'**
  String get gamesLevel;

  /// No description provided for @gamesKm.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get gamesKm;

  /// No description provided for @gamesSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPD'**
  String get gamesSpeed;

  /// No description provided for @gamesTapRefreshPlay.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to play again'**
  String get gamesTapRefreshPlay;

  /// No description provided for @gamesTapRefreshTry.
  ///
  /// In en, this message translates to:
  /// **'Tap refresh to try again'**
  String get gamesTapRefreshTry;

  /// No description provided for @gamesTapPauseResume.
  ///
  /// In en, this message translates to:
  /// **'Tap pause to resume'**
  String get gamesTapPauseResume;

  /// No description provided for @gamesScoreTapRefresh.
  ///
  /// In en, this message translates to:
  /// **'Score {score} · tap refresh'**
  String gamesScoreTapRefresh(Object score);

  /// No description provided for @gamesScoreTapRetry.
  ///
  /// In en, this message translates to:
  /// **'Score {score} · tap to retry'**
  String gamesScoreTapRetry(Object score);

  /// No description provided for @gamesTapDragDrive.
  ///
  /// In en, this message translates to:
  /// **'Tap / drag to drive'**
  String get gamesTapDragDrive;

  /// No description provided for @rideCallDriver.
  ///
  /// In en, this message translates to:
  /// **'Call driver'**
  String get rideCallDriver;

  /// No description provided for @ridePayCashLocked.
  ///
  /// In en, this message translates to:
  /// **'Pay cash at complete — fare locked at request.'**
  String get ridePayCashLocked;

  /// No description provided for @rideNoDriverAvailable.
  ///
  /// In en, this message translates to:
  /// **'No driver was available. Go back and try again.'**
  String get rideNoDriverAvailable;

  /// No description provided for @rideAcceptSoon.
  ///
  /// In en, this message translates to:
  /// **'Accept soon'**
  String get rideAcceptSoon;

  /// No description provided for @rideSecsLeft.
  ///
  /// In en, this message translates to:
  /// **'{secs}s left'**
  String rideSecsLeft(int secs);

  /// No description provided for @foodPlaceOrderEtb.
  ///
  /// In en, this message translates to:
  /// **'PLACE ORDER · {amount} ETB'**
  String foodPlaceOrderEtb(Object amount);

  /// No description provided for @marketDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get marketDetails;

  /// No description provided for @marketAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get marketAdd;

  /// No description provided for @marketOpsQueueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ops queue'**
  String get marketOpsQueueTooltip;

  /// No description provided for @foodAssignOwner.
  ///
  /// In en, this message translates to:
  /// **'Assign owner · {name}'**
  String foodAssignOwner(String name);

  /// No description provided for @foodRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get foodRestaurant;

  /// No description provided for @foodGrocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get foodGrocery;

  /// No description provided for @foodAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get foodAddOption;

  /// No description provided for @marketNameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get marketNameMinChars;

  /// No description provided for @marketAddedName.
  ///
  /// In en, this message translates to:
  /// **'Added “{name}”.'**
  String marketAddedName(String name);

  /// No description provided for @marketUpdatedName.
  ///
  /// In en, this message translates to:
  /// **'Updated “{name}”.'**
  String marketUpdatedName(String name);

  /// No description provided for @marketEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit {id}'**
  String marketEditCategory(String id);

  /// No description provided for @marketEnterMaxAds.
  ///
  /// In en, this message translates to:
  /// **'Enter a number between 1 and 50.'**
  String get marketEnterMaxAds;

  /// No description provided for @marketMaxActiveSet.
  ///
  /// In en, this message translates to:
  /// **'Max active ads set to {value}.'**
  String marketMaxActiveSet(Object value);

  /// No description provided for @foodAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get foodAvailableLabel;

  /// No description provided for @foodOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get foodOptions;

  /// No description provided for @marketSortPriceUpChip.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get marketSortPriceUpChip;

  /// No description provided for @marketSortPriceDownChip.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get marketSortPriceDownChip;

  /// No description provided for @marketPriceRangeMinMax.
  ///
  /// In en, this message translates to:
  /// **'ETB {min}–{max}'**
  String marketPriceRangeMinMax(Object min, Object max);

  /// No description provided for @marketPriceRangeMinPlus.
  ///
  /// In en, this message translates to:
  /// **'ETB {min}+'**
  String marketPriceRangeMinPlus(Object min);

  /// No description provided for @marketPriceRangeUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to ETB {max}'**
  String marketPriceRangeUpTo(Object max);

  /// No description provided for @marketAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get marketAny;

  /// No description provided for @marketCatPhones.
  ///
  /// In en, this message translates to:
  /// **'Phones & Tablets'**
  String get marketCatPhones;

  /// No description provided for @marketCatElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get marketCatElectronics;

  /// No description provided for @marketCatVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get marketCatVehicles;

  /// No description provided for @marketCatProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get marketCatProperty;

  /// No description provided for @marketCatFurniture.
  ///
  /// In en, this message translates to:
  /// **'Home & Furniture'**
  String get marketCatFurniture;

  /// No description provided for @marketCatFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get marketCatFashion;

  /// No description provided for @marketEditAd.
  ///
  /// In en, this message translates to:
  /// **'Edit ad'**
  String get marketEditAd;

  /// No description provided for @marketCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get marketCover;

  /// No description provided for @marketFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get marketFieldTitle;

  /// No description provided for @marketFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get marketFieldDescription;

  /// No description provided for @marketFieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (ETB)'**
  String get marketFieldPrice;

  /// No description provided for @marketFieldBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get marketFieldBrand;

  /// No description provided for @marketBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apple, Toyota'**
  String get marketBrandHint;

  /// No description provided for @marketRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get marketRequired;

  /// No description provided for @marketMinChars.
  ///
  /// In en, this message translates to:
  /// **'Min {count} characters'**
  String marketMinChars(int count);

  /// No description provided for @marketValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get marketValidPrice;

  /// No description provided for @marketSpecStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get marketSpecStorage;

  /// No description provided for @marketSpecYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get marketSpecYear;

  /// No description provided for @marketSpecType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get marketSpecType;

  /// No description provided for @marketSpecSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get marketSpecSize;

  /// No description provided for @marketSpecGeneric.
  ///
  /// In en, this message translates to:
  /// **'Spec'**
  String get marketSpecGeneric;

  /// No description provided for @marketSpecHintPhones.
  ///
  /// In en, this message translates to:
  /// **'e.g. 128GB'**
  String get marketSpecHintPhones;

  /// No description provided for @marketSpecHintVehicles.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2019'**
  String get marketSpecHintVehicles;

  /// No description provided for @marketSpecHintProperty.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent / Sale'**
  String get marketSpecHintProperty;

  /// No description provided for @marketSpecHintElectronics.
  ///
  /// In en, this message translates to:
  /// **'e.g. 55 inch'**
  String get marketSpecHintElectronics;

  /// No description provided for @marketSpecHintGeneric.
  ///
  /// In en, this message translates to:
  /// **'Main spec'**
  String get marketSpecHintGeneric;

  /// No description provided for @marketExtraDetailName.
  ///
  /// In en, this message translates to:
  /// **'Extra detail name'**
  String get marketExtraDetailName;

  /// No description provided for @marketExtraDetailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Color'**
  String get marketExtraDetailHint;

  /// No description provided for @marketExtraValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get marketExtraValue;

  /// No description provided for @marketExtraValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Black'**
  String get marketExtraValueHint;

  /// No description provided for @marketFieldSubcity.
  ///
  /// In en, this message translates to:
  /// **'Subcity'**
  String get marketFieldSubcity;

  /// No description provided for @marketUploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos…'**
  String get marketUploadingPhotos;

  /// No description provided for @marketSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get marketSubmitting;

  /// No description provided for @marketSaveResubmit.
  ///
  /// In en, this message translates to:
  /// **'Save & re-submit'**
  String get marketSaveResubmit;

  /// No description provided for @marketSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get marketSubmitReview;

  /// No description provided for @marketUpdatedPending.
  ///
  /// In en, this message translates to:
  /// **'Updated — pending review again.'**
  String get marketUpdatedPending;

  /// No description provided for @marketSubmittedModeration.
  ///
  /// In en, this message translates to:
  /// **'Submitted for moderation. You’ll be notified when reviewed.'**
  String get marketSubmittedModeration;

  /// No description provided for @marketListing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get marketListing;

  /// No description provided for @marketPhoneVisible.
  ///
  /// In en, this message translates to:
  /// **'Phone visible on your ads (rate-limited).'**
  String get marketPhoneVisible;

  /// No description provided for @marketPhoneHidden.
  ///
  /// In en, this message translates to:
  /// **'Phone hidden — buyers use chat only.'**
  String get marketPhoneHidden;

  /// No description provided for @marketCallCtaBuyers.
  ///
  /// In en, this message translates to:
  /// **'Call CTA for buyers (daily limit applies)'**
  String get marketCallCtaBuyers;

  /// No description provided for @marketYourNumber.
  ///
  /// In en, this message translates to:
  /// **'Number: {phone}'**
  String marketYourNumber(String phone);

  /// No description provided for @marketUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get marketUpdates;

  /// No description provided for @marketUpdatesUnread.
  ///
  /// In en, this message translates to:
  /// **'Updates ({count} new)'**
  String marketUpdatesUnread(int count);

  /// No description provided for @marketRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String marketRejectReason(String reason);

  /// No description provided for @marketReportHint.
  ///
  /// In en, this message translates to:
  /// **'Spam, scam, prohibited item…'**
  String get marketReportHint;

  /// No description provided for @marketMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get marketMessageHint;

  /// No description provided for @marketStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Start chatting'**
  String get marketStartChatting;

  /// No description provided for @marketMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get marketMessages;

  /// No description provided for @marketDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get marketDisplayName;

  /// No description provided for @marketDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Babies & Kids'**
  String get marketDisplayNameHint;

  /// No description provided for @marketIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Id (optional)'**
  String get marketIdOptional;

  /// No description provided for @marketIdAutoHint.
  ///
  /// In en, this message translates to:
  /// **'auto from name if empty'**
  String get marketIdAutoHint;

  /// No description provided for @marketIconKey.
  ///
  /// In en, this message translates to:
  /// **'Icon key'**
  String get marketIconKey;

  /// No description provided for @marketRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason shown to seller…'**
  String get marketRejectReasonHint;

  /// No description provided for @marketLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit (1–50)'**
  String get marketLimitLabel;

  /// No description provided for @marketLimitHelper.
  ///
  /// In en, this message translates to:
  /// **'Per seller: approved + pending count'**
  String get marketLimitHelper;

  /// No description provided for @marketCurrentPerSeller.
  ///
  /// In en, this message translates to:
  /// **'Current: {value} per seller'**
  String marketCurrentPerSeller(Object value);

  /// No description provided for @marketOpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ops'**
  String get marketOpsTitle;

  /// No description provided for @marketDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get marketDismissed;

  /// No description provided for @marketSuspendedFromOps.
  ///
  /// In en, this message translates to:
  /// **'Suspended from ops queue'**
  String get marketSuspendedFromOps;

  /// No description provided for @marketCategoryMeta.
  ///
  /// In en, this message translates to:
  /// **'id: {id} · icon: {icon}'**
  String marketCategoryMeta(String id, String icon);

  /// No description provided for @foodNavBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get foodNavBrowse;

  /// No description provided for @foodNavOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get foodNavOrders;

  /// No description provided for @foodSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get foodSubtotal;

  /// No description provided for @foodDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get foodDeliveryFee;

  /// No description provided for @foodTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get foodTotal;

  /// No description provided for @foodCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get foodCheckout;

  /// No description provided for @foodLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get foodLabel;

  /// No description provided for @foodSubcity.
  ///
  /// In en, this message translates to:
  /// **'Subcity'**
  String get foodSubcity;

  /// No description provided for @foodAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get foodAddressDetails;

  /// No description provided for @foodNotesRider.
  ///
  /// In en, this message translates to:
  /// **'Notes for rider / kitchen'**
  String get foodNotesRider;

  /// No description provided for @foodSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get foodSaving;

  /// No description provided for @foodSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save this address'**
  String get foodSaveAddress;

  /// No description provided for @foodPaymentCod.
  ///
  /// In en, this message translates to:
  /// **'Payment: Cash on delivery (COD)'**
  String get foodPaymentCod;

  /// No description provided for @foodCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize {name}'**
  String foodCustomize(String name);

  /// No description provided for @foodAskOtp.
  ///
  /// In en, this message translates to:
  /// **'Ask customer for OTP'**
  String get foodAskOtp;

  /// No description provided for @foodKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get foodKind;

  /// No description provided for @foodStoreOpen.
  ///
  /// In en, this message translates to:
  /// **'Store open'**
  String get foodStoreOpen;

  /// No description provided for @foodStorePaused.
  ///
  /// In en, this message translates to:
  /// **'Store paused'**
  String get foodStorePaused;

  /// No description provided for @foodMarkAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark available'**
  String get foodMarkAvailable;

  /// No description provided for @foodMarkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Mark unavailable'**
  String get foodMarkUnavailable;

  /// No description provided for @foodOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner: {name}'**
  String foodOwner(String name);

  /// No description provided for @foodCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers {areas}'**
  String foodCovers(String areas);

  /// No description provided for @foodReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get foodReassign;

  /// No description provided for @foodStaffPhone.
  ///
  /// In en, this message translates to:
  /// **'Staff phone'**
  String get foodStaffPhone;

  /// No description provided for @foodStaffPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Local 9 digits or +251…'**
  String get foodStaffPhoneHelper;

  /// No description provided for @foodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get foodUnavailable;

  /// No description provided for @foodSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get foodSoldOut;

  /// No description provided for @foodRsvpFree.
  ///
  /// In en, this message translates to:
  /// **'RSVP free'**
  String get foodRsvpFree;

  /// No description provided for @foodRsvpPayDoor.
  ///
  /// In en, this message translates to:
  /// **'RSVP · pay at door'**
  String get foodRsvpPayDoor;

  /// No description provided for @rideGoAcross.
  ///
  /// In en, this message translates to:
  /// **'Go across Addis'**
  String get rideGoAcross;

  /// No description provided for @rideMapPickPickup.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set pickup'**
  String get rideMapPickPickup;

  /// No description provided for @rideMapPickDropoff.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set drop-off'**
  String get rideMapPickDropoff;

  /// No description provided for @rideMapActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress — map is for reference'**
  String get rideMapActiveTrip;

  /// No description provided for @rideSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Bole, Piassa, Airport…'**
  String get rideSearchHint;

  /// No description provided for @ridePickupYou.
  ///
  /// In en, this message translates to:
  /// **'Pickup · you'**
  String get ridePickupYou;

  /// No description provided for @ridePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get ridePickup;

  /// No description provided for @rideWaitingLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for location…'**
  String get rideWaitingLocation;

  /// No description provided for @rideTapMapOnce.
  ///
  /// In en, this message translates to:
  /// **'Tap the map once to set'**
  String get rideTapMapOnce;

  /// No description provided for @rideMapPinWaiting.
  ///
  /// In en, this message translates to:
  /// **'Map pin set — waiting for places from API'**
  String get rideMapPinWaiting;

  /// No description provided for @rideOutsideNote.
  ///
  /// In en, this message translates to:
  /// **'That pin is outside Addis. Move it into the service area.'**
  String get rideOutsideNote;

  /// No description provided for @rideBaseEtb.
  ///
  /// In en, this message translates to:
  /// **'Base ETB'**
  String get rideBaseEtb;

  /// No description provided for @ridePerKmEtb.
  ///
  /// In en, this message translates to:
  /// **'Per km ETB'**
  String get ridePerKmEtb;

  /// No description provided for @rideMinFareEtb.
  ///
  /// In en, this message translates to:
  /// **'Min fare ETB'**
  String get rideMinFareEtb;

  /// No description provided for @rideOfferRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'Offer radius km'**
  String get rideOfferRadiusKm;

  /// No description provided for @rideOpsApiOnly.
  ///
  /// In en, this message translates to:
  /// **'Ride ops requires API mode.'**
  String get rideOpsApiOnly;

  /// No description provided for @rideCancelledByOps.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Ride ops'**
  String get rideCancelledByOps;

  /// No description provided for @rideApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get rideApprove;

  /// No description provided for @rideSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get rideSuspend;

  /// No description provided for @rideCashVehicle.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB cash · {vehicle}'**
  String rideCashVehicle(Object amount, String vehicle);

  /// No description provided for @rideDriverMode.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get rideDriverMode;

  /// No description provided for @rideGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get rideGoOnline;

  /// No description provided for @eventsNavBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get eventsNavBrowse;

  /// No description provided for @eventsNavHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get eventsNavHost;

  /// No description provided for @eventsSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get eventsSoldOut;

  /// No description provided for @eventsSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} seats left'**
  String eventsSeatsLeft(int count);

  /// No description provided for @eventsOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventsOrganizer;

  /// No description provided for @eventsRsvpFree.
  ///
  /// In en, this message translates to:
  /// **'RSVP free'**
  String get eventsRsvpFree;

  /// No description provided for @eventsRsvpPayDoor.
  ///
  /// In en, this message translates to:
  /// **'RSVP · pay at door'**
  String get eventsRsvpPayDoor;

  /// No description provided for @eventsFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get eventsFree;

  /// No description provided for @eventsPricePayDoor.
  ///
  /// In en, this message translates to:
  /// **'ETB {amount} · pay at door'**
  String eventsPricePayDoor(Object amount);

  /// No description provided for @eventsTicketCode.
  ///
  /// In en, this message translates to:
  /// **'Ticket code'**
  String get eventsTicketCode;

  /// No description provided for @eventsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get eventsReason;

  /// No description provided for @eventsMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get eventsMonthJan;

  /// No description provided for @eventsMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get eventsMonthFeb;

  /// No description provided for @eventsMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get eventsMonthMar;

  /// No description provided for @eventsMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get eventsMonthApr;

  /// No description provided for @eventsMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get eventsMonthMay;

  /// No description provided for @eventsMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get eventsMonthJun;

  /// No description provided for @eventsMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get eventsMonthJul;

  /// No description provided for @eventsMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get eventsMonthAug;

  /// No description provided for @eventsMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get eventsMonthSep;

  /// No description provided for @eventsMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get eventsMonthOct;

  /// No description provided for @eventsMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get eventsMonthNov;

  /// No description provided for @eventsMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get eventsMonthDec;

  /// No description provided for @adminLocalPhone.
  ///
  /// In en, this message translates to:
  /// **'Local phone (9 digits)'**
  String get adminLocalPhone;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminRole;

  /// No description provided for @homeAddisOs.
  ///
  /// In en, this message translates to:
  /// **'Addis OS'**
  String get homeAddisOs;

  /// No description provided for @homeStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get homeStaff;

  /// No description provided for @authSignalEthiopia.
  ///
  /// In en, this message translates to:
  /// **'Signal · Ethiopia'**
  String get authSignalEthiopia;

  /// No description provided for @authVerifyChannel.
  ///
  /// In en, this message translates to:
  /// **'Verify channel'**
  String get authVerifyChannel;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Ethiopian mobile number'**
  String get authPhoneInvalid;

  /// No description provided for @authOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authOtpInvalid;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @moduleOnlineSoon.
  ///
  /// In en, this message translates to:
  /// **'Module · online soon'**
  String get moduleOnlineSoon;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @foodExtraCheeseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Extra cheese'**
  String get foodExtraCheeseHint;

  /// No description provided for @foodOpsMenuExplain.
  ///
  /// In en, this message translates to:
  /// **'Food ops does not edit restaurant menus here. Open Food ops to create a merchant and Assign owner phone to the restaurant staff. Only that owner can add dishes.'**
  String get foodOpsMenuExplain;

  /// No description provided for @foodMerchantAssignExplain.
  ///
  /// In en, this message translates to:
  /// **'Ask Food ops to assign your phone as the owner of one restaurant. You can only edit that restaurant’s menu — never another store’s.'**
  String get foodMerchantAssignExplain;

  /// No description provided for @foodRiderLabel.
  ///
  /// In en, this message translates to:
  /// **'Rider: {id}'**
  String foodRiderLabel(String id);

  /// No description provided for @foodCoverageLabel.
  ///
  /// In en, this message translates to:
  /// **'Coverage (comma-separated)'**
  String get foodCoverageLabel;

  /// No description provided for @foodUnassigned.
  ///
  /// In en, this message translates to:
  /// **'unassigned'**
  String get foodUnassigned;

  /// No description provided for @foodOpsMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Ops: mark delivered (no OTP)'**
  String get foodOpsMarkDelivered;

  /// No description provided for @foodOpsForceAdvance.
  ///
  /// In en, this message translates to:
  /// **'Ops: force advance status'**
  String get foodOpsForceAdvance;

  /// No description provided for @foodHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get foodHomeLabel;

  /// No description provided for @eventsTicketHint.
  ///
  /// In en, this message translates to:
  /// **'MK-…'**
  String get eventsTicketHint;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **','**
  String get listSeparator;

  /// No description provided for @placeAddisAbaba.
  ///
  /// In en, this message translates to:
  /// **'Addis Ababa'**
  String get placeAddisAbaba;

  /// No description provided for @placeAddisKetema.
  ///
  /// In en, this message translates to:
  /// **'Addis Ketema'**
  String get placeAddisKetema;

  /// No description provided for @placeArada.
  ///
  /// In en, this message translates to:
  /// **'Arada'**
  String get placeArada;

  /// No description provided for @placeBole.
  ///
  /// In en, this message translates to:
  /// **'Bole'**
  String get placeBole;

  /// No description provided for @placeBoleAirport.
  ///
  /// In en, this message translates to:
  /// **'Bole Airport'**
  String get placeBoleAirport;

  /// No description provided for @placeBoleAtlas.
  ///
  /// In en, this message translates to:
  /// **'Bole Atlas'**
  String get placeBoleAtlas;

  /// No description provided for @placeCmc.
  ///
  /// In en, this message translates to:
  /// **'CMC'**
  String get placeCmc;

  /// No description provided for @placeCmcMichael.
  ///
  /// In en, this message translates to:
  /// **'CMC Michael'**
  String get placeCmcMichael;

  /// No description provided for @placeGulele.
  ///
  /// In en, this message translates to:
  /// **'Gulele'**
  String get placeGulele;

  /// No description provided for @placeKazanchis.
  ///
  /// In en, this message translates to:
  /// **'Kazanchis'**
  String get placeKazanchis;

  /// No description provided for @placeKirkos.
  ///
  /// In en, this message translates to:
  /// **'Kirkos'**
  String get placeKirkos;

  /// No description provided for @placeLideta.
  ///
  /// In en, this message translates to:
  /// **'Lideta'**
  String get placeLideta;

  /// No description provided for @placeMexicoSquare.
  ///
  /// In en, this message translates to:
  /// **'Mexico Square'**
  String get placeMexicoSquare;

  /// No description provided for @placeNifasSilk.
  ///
  /// In en, this message translates to:
  /// **'Nifas Silk'**
  String get placeNifasSilk;

  /// No description provided for @placePiassa.
  ///
  /// In en, this message translates to:
  /// **'Piassa'**
  String get placePiassa;

  /// No description provided for @placeSarbet.
  ///
  /// In en, this message translates to:
  /// **'Sarbet'**
  String get placeSarbet;

  /// No description provided for @placeYeka.
  ///
  /// In en, this message translates to:
  /// **'Yeka'**
  String get placeYeka;

  /// No description provided for @locationTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use pickup.'**
  String get locationTurnOn;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationDenied;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Enable it in system settings.'**
  String get locationBlocked;

  /// No description provided for @locationNoPickupPlaces.
  ///
  /// In en, this message translates to:
  /// **'No pickup places available.'**
  String get locationNoPickupPlaces;

  /// No description provided for @authStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again with your phone number.'**
  String get authStartAgain;

  /// No description provided for @authApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Maekel API at {url}'**
  String authApiUnreachable(String url);

  /// No description provided for @authOtpGateway.
  ///
  /// In en, this message translates to:
  /// **'Could not verify OTP. Is the gateway running?'**
  String get authOtpGateway;

  /// No description provided for @eventsCategoriesNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Categories/areas not loaded yet.'**
  String get eventsCategoriesNotLoaded;

  /// No description provided for @eventsTitleVenueRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and venue are required.'**
  String get eventsTitleVenueRequired;

  /// No description provided for @eventsCapacityMin.
  ///
  /// In en, this message translates to:
  /// **'Capacity must be at least 1.'**
  String get eventsCapacityMin;

  /// No description provided for @eventsRejectDefault.
  ///
  /// In en, this message translates to:
  /// **'Does not meet guidelines'**
  String get eventsRejectDefault;

  /// No description provided for @foodSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get foodSavedLabel;

  /// No description provided for @foodEtaFee.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · {fee} ETB fee'**
  String foodEtaFee(Object minutes, Object fee);

  /// No description provided for @foodCheckoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Subtotal {subtotal} ETB + delivery {fee} ETB = {total} ETB'**
  String foodCheckoutSummary(Object subtotal, Object fee, Object total);

  /// No description provided for @foodModifierPrice.
  ///
  /// In en, this message translates to:
  /// **'(+{amount} ETB)'**
  String foodModifierPrice(Object amount);

  /// No description provided for @foodOptionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} option(s)'**
  String foodOptionsCount(int count);

  /// No description provided for @foodPriceEtb.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB'**
  String foodPriceEtb(Object amount);

  /// No description provided for @foodPriceEtbCod.
  ///
  /// In en, this message translates to:
  /// **'{amount} ETB COD'**
  String foodPriceEtbCod(Object amount);

  /// No description provided for @rideVehicleEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get rideVehicleEconomy;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({code})'**
  String requestFailed(Object code);

  /// No description provided for @sellerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get sellerYou;

  /// No description provided for @marketLocationAddis.
  ///
  /// In en, this message translates to:
  /// **'{subcity}, Addis Ababa'**
  String marketLocationAddis(String subcity);

  /// No description provided for @eventStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get eventStatusDraft;

  /// No description provided for @eventStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get eventStatusRejected;

  /// No description provided for @eventStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get eventStatusEnded;

  /// No description provided for @ticketStatusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get ticketStatusReserved;

  /// No description provided for @ticketStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get ticketStatusCheckedIn;

  /// No description provided for @eventsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get eventsPhotos;

  /// No description provided for @eventsAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo.'**
  String get eventsAddPhoto;

  /// No description provided for @eventsMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Max 8 photos.'**
  String get eventsMaxPhotos;

  /// No description provided for @eventsPhotosOptional.
  ///
  /// In en, this message translates to:
  /// **'Photos (optional, up to 8)'**
  String get eventsPhotosOptional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'aa',
    'am',
    'ar',
    'en',
    'om',
    'so',
    'sw',
    'ti',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'aa':
      return AppLocalizationsAa();
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'so':
      return AppLocalizationsSo();
    case 'sw':
      return AppLocalizationsSw();
    case 'ti':
      return AppLocalizationsTi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
