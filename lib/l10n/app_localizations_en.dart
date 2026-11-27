// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get otpSubtitle => 'Mock OTP — use 828694 for now.';

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
  String get moduleEvents => 'Events';

  @override
  String get moduleEventsDesc => 'Discover and host in Addis';

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
  String get rideStubBody => 'Ride matching and maps come in a later pass.';

  @override
  String get rideDriverStubBody =>
      'Driver mode — availability, jobs, and earnings.';

  @override
  String get marketTitle => 'Market';

  @override
  String get marketBrowse => 'Browse listings';

  @override
  String get marketSell => 'Sell something';

  @override
  String get marketStubBody => 'Classifieds for Addis.';

  @override
  String get marketSellStubBody =>
      'Create a listing with photos and price in ETB.';

  @override
  String get foodTitle => 'Food';

  @override
  String get foodStubBody => 'Restaurant browse and cart for Addis delivery.';

  @override
  String get gamesTitle => 'Games';

  @override
  String get gamesHubBody =>
      'Play offline, sync your best scores to the Addis board.';

  @override
  String get brickBreaker => 'Brick Breaker';

  @override
  String get brickBreakerStub => 'Drag to move paddle · tap to launch';

  @override
  String get tetris => 'Tetris';

  @override
  String get tetrisStub => 'Swipe · tap rotate · double-tap hard drop';

  @override
  String get candyCrush => 'Match 3';

  @override
  String get roadFighter => 'Road Fighter';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get backHome => 'Back to home';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'Choose how Maekel speaks to you';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get open => 'Open';

  @override
  String get submit => 'Submit';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get clear => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get add => 'Add';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get keep => 'Keep';

  @override
  String get search => 'Search';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get closed => 'Closed';

  @override
  String get accept => 'Accept';

  @override
  String get skip => 'Skip';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String get notFound => 'Not found';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get all => 'All';

  @override
  String get qty => 'Qty';

  @override
  String get details => 'Details';

  @override
  String get photos => 'Photos';

  @override
  String get cover => 'Cover';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get soldOut => 'Sold out';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get preparing => 'Preparing';

  @override
  String get ready => 'Ready';

  @override
  String get rideSubtitle => 'Go across Addis';

  @override
  String get rideDriveTitle => 'Drive';

  @override
  String get rideTripTitle => 'Trip';

  @override
  String get rideTripsTitle => 'Trips';

  @override
  String get rideOpsTitle => 'Ride ops';

  @override
  String get rideSetPickup => 'Set pickup';

  @override
  String get rideSetDropoff => 'Set dropoff';

  @override
  String get rideUseMyLocation => 'Use my location';

  @override
  String get rideGetQuote => 'Get upfront quote';

  @override
  String get rideRequest => 'Request ride';

  @override
  String get rideEconomy => 'Economy';

  @override
  String get rideActiveTrip => 'Active trip';

  @override
  String get rideOutsideServiceArea =>
      'Pickup or drop-off is outside the Addis Ababa service area.';

  @override
  String get rideNoTripsYet => 'No trips yet.';

  @override
  String get rideCancelTrip => 'Cancel trip';

  @override
  String get rideRateDriver => 'Rate your driver';

  @override
  String get rideSubmitRating => 'Submit rating';

  @override
  String get rideTripNotFound => 'Trip not found';

  @override
  String get rideNoDrivers =>
      'No online drivers nearby. Ask a test driver to go Online on Drive, then Request again.';

  @override
  String rideDriverEta(Object minutes) {
    return 'Driver ETA about $minutes min';
  }

  @override
  String rideArrivingIn(Object minutes) {
    return 'Arriving in about $minutes min';
  }

  @override
  String rideYouRated(Object rating) {
    return 'You rated $rating★';
  }

  @override
  String rideFrom(String place) {
    return 'From: $place';
  }

  @override
  String rideTo(String place) {
    return 'To: $place';
  }

  @override
  String rideFareEtb(Object amount) {
    return '$amount ETB';
  }

  @override
  String get ridePendingApproval =>
      'Pending Ride ops approval before you can go online.';

  @override
  String get rideActiveJob => 'Active job';

  @override
  String get rideCompleteCash => 'Complete + confirm cash';

  @override
  String get rideReportProblem => 'Report a problem';

  @override
  String get ridePassengerNoShow => 'Passenger no-show';

  @override
  String get rideWrongPin => 'Wrong pin';

  @override
  String get rideOffers => 'Offers';

  @override
  String get rideGoOnlineHint => 'Go online to see matching requests.';

  @override
  String get rideNoOffers =>
      'No open offers right now. When a passenger requests nearby, the offer appears here with a time limit.';

  @override
  String get rideTodaysEarnings => 'Today\'s earnings';

  @override
  String get rideFareConfig => 'Fare config';

  @override
  String get rideSaveFareParams => 'Save fare params';

  @override
  String rideDrivers(int count) {
    return 'Drivers ($count)';
  }

  @override
  String rideActiveTrips(int count) {
    return 'Active trips ($count)';
  }

  @override
  String get rideNoActiveTrips => 'No active trips.';

  @override
  String get rideForceCancel => 'Force cancel';

  @override
  String get rideFareConfigSaved => 'Fare config saved';

  @override
  String get rideMapHint => '+/− zoom · click to pin · drag to pan';

  @override
  String rideFareDueCash(Object amount) {
    return 'Fare due: $amount ETB cash';
  }

  @override
  String get marketSellAction => 'Sell';

  @override
  String get marketSubtitle => 'Buy & sell in Addis';

  @override
  String get marketBlurb => 'Classifieds with chat. Inspect before you pay.';

  @override
  String get marketSearchHint => 'Search phones, cars, furniture…';

  @override
  String get marketCategories => 'Categories';

  @override
  String get marketNearYou => 'Near you';

  @override
  String marketAdsCount(int count) {
    return '$count ads';
  }

  @override
  String get marketNoMatch =>
      'No listings match. Try another area or clear filters.';

  @override
  String get marketAllAreas => 'All areas';

  @override
  String get marketCondition => 'Condition';

  @override
  String get marketAnyCondition => 'Any condition';

  @override
  String get marketPriceRange => 'Price range';

  @override
  String get marketPriceRangeEtb => 'Price range (ETB)';

  @override
  String get marketMinimum => 'Minimum';

  @override
  String get marketMaximum => 'Maximum';

  @override
  String get marketMinMaxError => 'Minimum cannot be higher than maximum.';

  @override
  String get marketSortNewest => 'Newest';

  @override
  String get marketSortPriceLow => 'Price: low to high';

  @override
  String get marketSortPriceHigh => 'Price: high to low';

  @override
  String get marketAdNotFound => 'Ad not found';

  @override
  String get marketSeller => 'Seller';

  @override
  String get marketChatSeller => 'Chat with seller';

  @override
  String get marketCallSeller => 'Call seller';

  @override
  String get marketSellerHidPhone => 'Seller hid their phone. Use chat.';

  @override
  String get marketYourListing => 'This is your listing.';

  @override
  String get marketEditListing => 'Edit listing';

  @override
  String get marketReportListing => 'Report listing';

  @override
  String get marketReportSent => 'Report sent to ops.';

  @override
  String get marketNoAdsInCategory => 'No ads in this category yet.';

  @override
  String get marketNoFavorites => 'No saved ads yet.';

  @override
  String get marketNoChats => 'No chats yet. Open an ad and tap Chat.';

  @override
  String get marketShowPhone => 'Show phone on ads';

  @override
  String get marketNoAdsYet => 'No ads yet';

  @override
  String get marketPostSomething => 'Post something to sell in Addis.';

  @override
  String get marketSellNow => 'Sell now';

  @override
  String get marketMarkSold => 'Mark sold';

  @override
  String get marketBeforeContact => 'Before you contact';

  @override
  String get marketIUnderstand => 'I understand';

  @override
  String get marketMaxPhotos => 'Max 8 photos.';

  @override
  String get marketPickCategoryArea => 'Pick a category and area.';

  @override
  String get marketAddPhoto => 'Add at least one photo.';

  @override
  String get marketKeyDetails => 'Key details';

  @override
  String marketOpsPending(int count) {
    return 'Pending ads ($count)';
  }

  @override
  String get marketOpsQueueEmpty => 'Queue empty — nothing to moderate.';

  @override
  String marketOpsReports(int count) {
    return 'Open reports ($count)';
  }

  @override
  String get marketOpsNoReports => 'No open reports.';

  @override
  String marketOpsCategories(int count) {
    return 'Category config ($count)';
  }

  @override
  String get marketOpsNoCategories =>
      'No categories yet. Add the first one to unlock Sell.';

  @override
  String get marketOpsLimits => 'Limits';

  @override
  String get marketOpsSuspendSeller => 'Suspend seller';

  @override
  String get marketOpsUnpublish => 'Unpublish';

  @override
  String get marketOpsSuspend => 'Suspend';

  @override
  String get marketOpsOpenAd => 'Open ad';

  @override
  String get marketOpsRejectAd => 'Reject ad';

  @override
  String get marketOpsAddCategory => 'Add category';

  @override
  String get marketOpsMaxFreeAds => 'Max active free ads';

  @override
  String marketOpsSuspendedSellers(int count) {
    return 'Suspended sellers ($count)';
  }

  @override
  String get marketOpsNoSuspended => 'No suspended sellers.';

  @override
  String get marketOpsReinstateSeller => 'Reinstate';

  @override
  String get marketAllCategories => 'All';

  @override
  String get marketShowPhoneNumber => 'Show number';

  @override
  String marketSellerPhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get eventsOpsViewDetails => 'View details';

  @override
  String get foodSubtitle => 'Deliver in Addis';

  @override
  String get foodBlurb => 'Restaurants & groceries · COD · OTP handover';

  @override
  String get foodDeliveryPin => 'Delivery pin';

  @override
  String get foodSearchHint => 'Search merchants or dishes…';

  @override
  String get foodRestaurants => 'Restaurants';

  @override
  String get foodGroceries => 'Groceries';

  @override
  String foodNoMerchants(String pin) {
    return 'No merchants deliver to $pin';
  }

  @override
  String get foodTryOtherPin => 'Try another delivery pin nearby.';

  @override
  String get foodMerchantConsole => 'Merchant console';

  @override
  String get foodRider => 'Rider';

  @override
  String get foodOps => 'Food ops';

  @override
  String get foodCartEmpty => 'Your cart is empty.';

  @override
  String get foodCheckoutCod => 'Checkout · COD';

  @override
  String foodMinOrder(Object amount) {
    return 'Min order $amount ETB';
  }

  @override
  String get foodAddressSaved => 'Address saved';

  @override
  String get foodCodBlurb =>
      'Pay cash on delivery. Delivery fee shown before you confirm — no surprises.';

  @override
  String get foodSavedPlaces => 'Saved places';

  @override
  String get foodNoSavedPlaces =>
      'No saved places yet — fill address below and tap Save.';

  @override
  String get foodMenu => 'Menu';

  @override
  String get foodAddToCart => 'Add to cart';

  @override
  String foodAdded(String name) {
    return '$name added';
  }

  @override
  String get foodReplaceCart => 'Replace cart?';

  @override
  String get foodClearAndAdd => 'Clear & add';

  @override
  String foodCartTotal(Object amount) {
    return 'Cart · $amount ETB';
  }

  @override
  String get foodOrdersTitle => 'Orders';

  @override
  String get foodNoOrders => 'No orders yet.';

  @override
  String get foodOrderNotFound => 'Order not found';

  @override
  String get foodItems => 'Items';

  @override
  String get foodDeliveryOtp => 'Delivery OTP';

  @override
  String get foodDeliveryOtpHint =>
      'Show this code to the rider. They collect COD and enter OTP in the rider app.';

  @override
  String get foodCancelOrder => 'Cancel order';

  @override
  String get foodCannotCancel =>
      'You can no longer cancel. The shop has already started preparing this order.';

  @override
  String get foodNoRestaurant => 'No restaurant linked yet';

  @override
  String get foodOpenOps => 'Open Food ops';

  @override
  String get foodAddDish => 'Add dish';

  @override
  String get foodNoDishes =>
      'No dishes yet. Add name + price so customers can order.';

  @override
  String foodOrderQueue(int count) {
    return 'Order queue ($count)';
  }

  @override
  String get foodNoKitchenOrders => 'No open kitchen orders.';

  @override
  String get foodPickup => 'Pickup';

  @override
  String get foodDropoff => 'Dropoff';

  @override
  String get foodClaimJob => 'Claim job';

  @override
  String get foodPickedUp => 'Picked up';

  @override
  String get foodOnTheWay => 'On the way';

  @override
  String get foodCompleteCod => 'Complete + COD';

  @override
  String foodMyJobs(int count) {
    return 'My jobs ($count)';
  }

  @override
  String get foodNoActiveDelivery => 'No active delivery.';

  @override
  String foodAvailable(int count) {
    return 'Available ($count)';
  }

  @override
  String get foodNoReadyOrders => 'No ready orders waiting for a rider.';

  @override
  String get foodConfirmCod => 'Confirm COD';

  @override
  String foodCollectCod(Object amount) {
    return 'Collect $amount ETB COD';
  }

  @override
  String foodOrderBoard(int count) {
    return 'Order board ($count)';
  }

  @override
  String get foodNoRecentOrders => 'No recent orders.';

  @override
  String get foodOnboardMerchant => 'Onboard merchant';

  @override
  String get foodCreateMerchant => 'Create merchant';

  @override
  String foodMerchants(int count) {
    return 'Merchants ($count)';
  }

  @override
  String get foodSupportCancel => 'Support cancel';

  @override
  String get foodClearRider => 'Clear rider';

  @override
  String get foodAssign => 'Assign';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsOps => 'Events ops';

  @override
  String get eventsCreate => 'Create event';

  @override
  String get eventsSearchHint => 'Search events, venues…';

  @override
  String get eventsAnyArea => 'Any area';

  @override
  String get eventsEmpty =>
      'No upcoming events yet. Host one from the + button.';

  @override
  String eventsRsvpConfirmed(String code) {
    return 'RSVP confirmed · $code';
  }

  @override
  String get eventsRsvpCancelled => 'RSVP cancelled';

  @override
  String get eventsYourTicket => 'Your ticket';

  @override
  String get eventsCancelRsvp => 'Cancel RSVP';

  @override
  String get eventsSubmitted =>
      'Submitted for review — Events ops must approve.';

  @override
  String get eventsStarts => 'Starts';

  @override
  String get eventsPick => 'Pick';

  @override
  String get eventsCheckedIn => 'Checked in';

  @override
  String get eventsNotHosted => 'You have not hosted an event yet.';

  @override
  String get eventsAttendees => 'Attendees';

  @override
  String eventsDoorCode(String code) {
    return 'Event PIN: $code';
  }

  @override
  String get eventsDoorIdLabel => 'Door ID';

  @override
  String get eventsDoorIdHint => 'e.g. Gate A / Door 2';

  @override
  String get eventsDoorIdRequired => 'Enter your Door ID before check-in';

  @override
  String get eventsDoorIdHelp =>
      'Each checker uses a different Door ID. It is saved on every check-in.';

  @override
  String eventsCheckedInAtDoor(String door) {
    return 'Door $door';
  }

  @override
  String get eventsCheckIn => 'Check in';

  @override
  String get eventsComplete => 'Complete event';

  @override
  String get eventsCompleteConfirm =>
      'Mark this event as ended? It will leave the public browse list.';

  @override
  String get eventsCompleted => 'Event marked as ended';

  @override
  String get eventsNoTickets => 'No tickets yet. RSVP from Browse.';

  @override
  String eventsPending(int count) {
    return 'Pending ($count)';
  }

  @override
  String get eventsQueueClear => 'Queue clear.';

  @override
  String eventsLive(int count) {
    return 'Live ($count)';
  }

  @override
  String get eventsForceCancel => 'Force cancel';

  @override
  String get eventsSuspendOrganizer => 'Suspend organizer';

  @override
  String get eventsReject => 'Reject event';

  @override
  String get eventsMyEvents => 'My events';

  @override
  String get eventsTickets => 'Tickets';

  @override
  String get gamesQuickPlay => 'Quick play';

  @override
  String get gamesAddisTop3 => 'Addis top 3';

  @override
  String get gamesLeaderboardOffline =>
      'Leaderboard offline — start backend games-service to see Addis top 3.';

  @override
  String gamesTop3Title(String game) {
    return 'Top 3 · Addis · $game';
  }

  @override
  String get gamesNoScores => 'No scores yet — be the first in Addis.';

  @override
  String get gamesScoreNotSaved => 'Score not saved — username required.';

  @override
  String get gamesSyncFailed => 'Could not sync score. Is the API running?';

  @override
  String get gamesChooseUsername => 'Choose a username';

  @override
  String get gamesUsernameHint => 'Shown on the Addis Ababa top 3 leaderboard.';

  @override
  String get gamesSaveScore => 'Save score';

  @override
  String get gamesTapToLaunch => 'Tap to launch';

  @override
  String get gamesBrickHint => 'Drag to move paddle · tap to launch';

  @override
  String get gamesCandyHint =>
      'Drag a candy onto a neighbor · or tap-tap to swap';

  @override
  String get gamesTetrisHint => 'Swipe · tap rotate · double-tap hard drop';

  @override
  String get gamesRoadHint =>
      '◀ ▶ dodge · purple-stripe cars change lanes · grab F for fuel';

  @override
  String get gamesFuel => 'Fuel';

  @override
  String get gamesTetrisSubtitle => 'Stack · clear lines · level up';

  @override
  String get gamesBrickSubtitle => 'Bounce · smash bricks · survive';

  @override
  String get gamesCandySubtitle => 'Swap · match 3 · cascade score';

  @override
  String get gamesRoadSubtitle => 'Dodge · fuel up · drive farther';

  @override
  String get adminTitle => 'Staff & admins';

  @override
  String get adminPlatformOnly => 'Platform admin only';

  @override
  String get adminGrantRole => 'Grant role';

  @override
  String get adminGrant => 'Grant';

  @override
  String adminStaff(int count) {
    return 'Staff ($count)';
  }

  @override
  String get adminNoStaff => 'No staff roles assigned yet.';

  @override
  String get adminRoleGranted =>
      'Role granted. They must sign out and OTP again to refresh the JWT.';

  @override
  String get adminMarketModerator => 'Market moderator';

  @override
  String get adminPlatformAdmin => 'Platform admin';

  @override
  String get adminMarketOps => 'Market ops';

  @override
  String get adminFoodOps => 'Food ops';

  @override
  String get adminFoodMerchant => 'Food merchant';

  @override
  String get adminFoodRider => 'Food rider';

  @override
  String get adminRideOps => 'Ride ops';

  @override
  String get adminEventsOps => 'Events ops';

  @override
  String get rideStatusQuote => 'Quote';

  @override
  String get rideStatusRequested => 'Requested';

  @override
  String get rideStatusMatching => 'Finding driver';

  @override
  String get rideStatusAssigned => 'Driver assigned';

  @override
  String get rideStatusArriving => 'Driver arriving';

  @override
  String get rideStatusArrived => 'Driver arrived';

  @override
  String get rideStatusInProgress => 'On trip';

  @override
  String get rideStatusCompleted => 'Completed';

  @override
  String get rideStatusCancelled => 'Cancelled';

  @override
  String get rideNavRide => 'Ride';

  @override
  String get rideNavTrips => 'Trips';

  @override
  String get rideNavDrive => 'Drive';

  @override
  String get rideStartArriving => 'Start arriving';

  @override
  String get rideMarkArrived => 'Mark arrived';

  @override
  String get rideStartTrip => 'Start trip';

  @override
  String get rideAdvance => 'Advance';

  @override
  String get rideExpired => 'Expired';

  @override
  String get rideRefreshing => 'Refreshing…';

  @override
  String rideCompletedTripsToday(int count) {
    return '$count completed trip(s) today';
  }

  @override
  String rideRouteArrow(String from, String to) {
    return '$from → $to';
  }

  @override
  String rideFareStatusCountdown(
    Object amount,
    String status,
    String countdown,
  ) {
    return '$amount ETB · $status · $countdown';
  }

  @override
  String rideReported(String reason) {
    return 'Reported: $reason';
  }

  @override
  String rideActiveTripStatus(String status) {
    return 'Active trip · $status';
  }

  @override
  String rideVehicleFare(Object amount, String vehicle) {
    return '$amount ETB · $vehicle';
  }

  @override
  String rideDriverMeta(String car, String plate, Object rating) {
    return '$car · $plate · ★ $rating';
  }

  @override
  String get marketConditionNew => 'Brand new';

  @override
  String get marketConditionUsed => 'Used';

  @override
  String get marketConditionRefurbished => 'Refurbished';

  @override
  String get marketStatusPending => 'Pending';

  @override
  String get marketStatusActive => 'Active';

  @override
  String get marketStatusDeclined => 'Declined';

  @override
  String get marketStatusSold => 'Sold';

  @override
  String get marketNavBrowse => 'Browse';

  @override
  String get marketNavMyAds => 'My ads';

  @override
  String get marketNavSaved => 'Saved';

  @override
  String get marketNavChats => 'Chats';

  @override
  String get marketSafetyBody =>
      'Meet in a public place. Inspect before you pay. Never send deposits to strangers. Maekel staff never ask for fees in chat.';

  @override
  String get marketSafetyShort =>
      'Safety: Meet in public. Inspect before paying. Never send deposits to strangers.';

  @override
  String marketPriceEtb(String amount) {
    return '$amount ETB';
  }

  @override
  String marketSubcityCondition(String subcity, String condition) {
    return '$subcity · $condition';
  }

  @override
  String marketPriceSubcity(Object amount, String subcity) {
    return '$amount ETB · $subcity';
  }

  @override
  String get marketCategoryTitle => 'Category';

  @override
  String get marketChatTitle => 'Chat';

  @override
  String get marketFavoritesTitle => 'Favorites';

  @override
  String get foodStatusPlaced => 'Placed';

  @override
  String get foodStatusConfirmed => 'Confirmed';

  @override
  String get foodStatusPreparing => 'Preparing';

  @override
  String get foodStatusReadyPickup => 'Ready for pickup';

  @override
  String get foodStatusPickedUp => 'Picked up';

  @override
  String get foodStatusOnTheWay => 'On the way';

  @override
  String get foodStatusDelivered => 'Delivered';

  @override
  String get foodStatusCancelled => 'Cancelled';

  @override
  String foodClosedHours(String hours) {
    return 'Closed · $hours';
  }

  @override
  String foodOrderLine(Object qty, String name, Object amount) {
    return '$qty× $name — $amount ETB';
  }

  @override
  String foodOrderSummary(Object amount, int count) {
    return '$amount ETB · $count item(s)';
  }

  @override
  String foodTotalCod(Object amount) {
    return 'Total $amount ETB · COD';
  }

  @override
  String foodOrderBoardLine(String merchant, String subcity, Object amount) {
    return '$merchant → $subcity · $amount ETB';
  }

  @override
  String foodUnitPriceEach(Object amount) {
    return '$amount ETB each';
  }

  @override
  String foodNoDeliverPin(String pin) {
    return 'No merchants deliver to $pin';
  }

  @override
  String get foodMerchantTitle => 'Merchant';

  @override
  String get foodOrderTitle => 'Order';

  @override
  String get foodCartTitle => 'Cart';

  @override
  String get eventsEditTitle => 'Edit event';

  @override
  String get eventsFieldTitle => 'Title';

  @override
  String get eventsFieldDescription => 'Description';

  @override
  String get eventsFieldCategory => 'Category';

  @override
  String get eventsFieldSubcity => 'Subcity';

  @override
  String get eventsFieldVenue => 'Venue name';

  @override
  String get eventsFieldAddress => 'Address (optional)';

  @override
  String get eventsFieldCapacity => 'Capacity';

  @override
  String get eventsFieldPrice => 'Price ETB (0 = free)';

  @override
  String get eventsPayAtDoor => 'Guests pay at the door (COD-style).';

  @override
  String get eventsFreeRsvp => 'Free RSVP.';

  @override
  String get eventsSubmitReview => 'Submit for review';

  @override
  String eventsWhenSubcity(String when, String subcity) {
    return '$when · $subcity';
  }

  @override
  String eventsVenueCategory(String venue, String category) {
    return '$venue · $category';
  }

  @override
  String eventsTicketQtyStatus(Object qty, String status) {
    return 'Qty $qty · $status';
  }

  @override
  String eventsHostMeta(
    String status,
    Object sold,
    Object capacity,
    String subcity,
  ) {
    return '$status · $sold/$capacity · $subcity';
  }

  @override
  String get gamesScore => 'Score';

  @override
  String get gamesLives => 'Lives';

  @override
  String get gamesMoves => 'Moves';

  @override
  String get gamesCombo => 'Combo';

  @override
  String get gamesRestart => 'Restart';

  @override
  String get gamesPause => 'Pause';

  @override
  String get gamesResume => 'Resume';

  @override
  String get gamesMute => 'Mute';

  @override
  String get gamesUnmute => 'Unmute';

  @override
  String get gamesRefreshBoard => 'Refresh leaderboard';

  @override
  String gamesPersonalBest(Object score) {
    return 'New personal best: $score';
  }

  @override
  String gamesScoreSavedBest(Object score) {
    return 'Score saved. Best remains $score';
  }

  @override
  String get gamesUsernameLabel => 'Username';

  @override
  String get gamesUsernameHintExample => 'e.g. BoleAce';

  @override
  String adminPhoneDigits(int count) {
    return 'Enter a $count-digit local number.';
  }

  @override
  String adminRevoked(String role, String phone) {
    return 'Revoked $role from $phone';
  }

  @override
  String get adminNoAdminPhones =>
      'No ADMIN_PHONES configured on the API. Set that env var to bootstrap the first platform admin.';

  @override
  String adminBootstrapPhones(String phones) {
    return 'Bootstrap phones (env): $phones';
  }

  @override
  String get gamesGameOver => 'GAME OVER';

  @override
  String get gamesPaused => 'PAUSED';

  @override
  String get gamesOutOfMoves => 'OUT OF MOVES';

  @override
  String get gamesOutOfFuel => 'OUT OF FUEL';

  @override
  String get gamesCrash => 'CRASH!';

  @override
  String get gamesLines => 'Lines';

  @override
  String get gamesLevel => 'Lvl';

  @override
  String get gamesKm => 'KM';

  @override
  String get gamesSpeed => 'SPD';

  @override
  String get gamesTapRefreshPlay => 'Tap refresh to play again';

  @override
  String get gamesTapRefreshTry => 'Tap refresh to try again';

  @override
  String get gamesTapPauseResume => 'Tap pause to resume';

  @override
  String gamesScoreTapRefresh(Object score) {
    return 'Score $score · tap refresh';
  }

  @override
  String gamesScoreTapRetry(Object score) {
    return 'Score $score · tap to retry';
  }

  @override
  String get gamesTapDragDrive => 'Tap / drag to drive';

  @override
  String get rideCallDriver => 'Call driver';

  @override
  String get ridePayCashLocked =>
      'Pay cash at complete — fare locked at request.';

  @override
  String get rideNoDriverAvailable =>
      'No driver was available. Go back and try again.';

  @override
  String get rideAcceptSoon => 'Accept soon';

  @override
  String rideSecsLeft(int secs) {
    return '${secs}s left';
  }

  @override
  String foodPlaceOrderEtb(Object amount) {
    return 'PLACE ORDER · $amount ETB';
  }

  @override
  String get marketDetails => 'Details';

  @override
  String get marketAdd => 'Add';

  @override
  String get marketOpsQueueTooltip => 'Ops queue';

  @override
  String foodAssignOwner(String name) {
    return 'Assign owner · $name';
  }

  @override
  String get foodRestaurant => 'Restaurant';

  @override
  String get foodGrocery => 'Grocery';

  @override
  String get foodAddOption => 'Add option';

  @override
  String get marketNameMinChars => 'Name must be at least 2 characters.';

  @override
  String marketAddedName(String name) {
    return 'Added “$name”.';
  }

  @override
  String marketUpdatedName(String name) {
    return 'Updated “$name”.';
  }

  @override
  String marketEditCategory(String id) {
    return 'Edit $id';
  }

  @override
  String get marketEnterMaxAds => 'Enter a number between 1 and 50.';

  @override
  String marketMaxActiveSet(Object value) {
    return 'Max active ads set to $value.';
  }

  @override
  String get foodAvailableLabel => 'Available';

  @override
  String get foodOptions => 'Options';

  @override
  String get marketSortPriceUpChip => 'Price ↑';

  @override
  String get marketSortPriceDownChip => 'Price ↓';

  @override
  String marketPriceRangeMinMax(Object min, Object max) {
    return 'ETB $min–$max';
  }

  @override
  String marketPriceRangeMinPlus(Object min) {
    return 'ETB $min+';
  }

  @override
  String marketPriceRangeUpTo(Object max) {
    return 'Up to ETB $max';
  }

  @override
  String get marketAny => 'Any';

  @override
  String get marketCatPhones => 'Phones & Tablets';

  @override
  String get marketCatElectronics => 'Electronics';

  @override
  String get marketCatVehicles => 'Vehicles';

  @override
  String get marketCatProperty => 'Property';

  @override
  String get marketCatFurniture => 'Home & Furniture';

  @override
  String get marketCatFashion => 'Fashion';

  @override
  String get marketEditAd => 'Edit ad';

  @override
  String get marketCover => 'Cover';

  @override
  String get marketFieldTitle => 'Title';

  @override
  String get marketFieldDescription => 'Description';

  @override
  String get marketFieldPrice => 'Price (ETB)';

  @override
  String get marketFieldBrand => 'Brand';

  @override
  String get marketBrandHint => 'e.g. Apple, Toyota';

  @override
  String get marketRequired => 'Required';

  @override
  String marketMinChars(int count) {
    return 'Min $count characters';
  }

  @override
  String get marketValidPrice => 'Enter a valid price';

  @override
  String get marketSpecStorage => 'Storage';

  @override
  String get marketSpecYear => 'Year';

  @override
  String get marketSpecType => 'Type';

  @override
  String get marketSpecSize => 'Size';

  @override
  String get marketSpecGeneric => 'Spec';

  @override
  String get marketSpecHintPhones => 'e.g. 128GB';

  @override
  String get marketSpecHintVehicles => 'e.g. 2019';

  @override
  String get marketSpecHintProperty => 'e.g. Rent / Sale';

  @override
  String get marketSpecHintElectronics => 'e.g. 55 inch';

  @override
  String get marketSpecHintGeneric => 'Main spec';

  @override
  String get marketExtraDetailName => 'Extra detail name';

  @override
  String get marketExtraDetailHint => 'e.g. Color';

  @override
  String get marketExtraValue => 'Value';

  @override
  String get marketExtraValueHint => 'e.g. Black';

  @override
  String get marketFieldSubcity => 'Subcity';

  @override
  String get marketUploadingPhotos => 'Uploading photos…';

  @override
  String get marketSubmitting => 'Submitting…';

  @override
  String get marketSaveResubmit => 'Save & re-submit';

  @override
  String get marketSubmitReview => 'Submit for review';

  @override
  String get marketUpdatedPending => 'Updated — pending review again.';

  @override
  String get marketSubmittedModeration =>
      'Submitted for moderation. You’ll be notified when reviewed.';

  @override
  String get marketListing => 'Listing';

  @override
  String get marketPhoneVisible => 'Phone visible on your ads (rate-limited).';

  @override
  String get marketPhoneHidden => 'Phone hidden — buyers use chat only.';

  @override
  String get marketCallCtaBuyers => 'Call CTA for buyers (daily limit applies)';

  @override
  String marketYourNumber(String phone) {
    return 'Number: $phone';
  }

  @override
  String get marketUpdates => 'Updates';

  @override
  String marketUpdatesUnread(int count) {
    return 'Updates ($count new)';
  }

  @override
  String marketRejectReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get marketReportHint => 'Spam, scam, prohibited item…';

  @override
  String get marketMessageHint => 'Message…';

  @override
  String get marketStartChatting => 'Start chatting';

  @override
  String get marketMessages => 'Messages';

  @override
  String get marketDisplayName => 'Display name';

  @override
  String get marketDisplayNameHint => 'e.g. Babies & Kids';

  @override
  String get marketIdOptional => 'Id (optional)';

  @override
  String get marketIdAutoHint => 'auto from name if empty';

  @override
  String get marketIconKey => 'Icon key';

  @override
  String get marketRejectReasonHint => 'Reason shown to seller…';

  @override
  String get marketLimitLabel => 'Limit (1–50)';

  @override
  String get marketLimitHelper => 'Per seller: approved + pending count';

  @override
  String marketCurrentPerSeller(Object value) {
    return 'Current: $value per seller';
  }

  @override
  String get marketOpsTitle => 'Ops';

  @override
  String get marketDismissed => 'Dismissed';

  @override
  String get marketSuspendedFromOps => 'Suspended from ops queue';

  @override
  String marketCategoryMeta(String id, String icon) {
    return 'id: $id · icon: $icon';
  }

  @override
  String get foodNavBrowse => 'Browse';

  @override
  String get foodNavOrders => 'Orders';

  @override
  String get foodSubtotal => 'Subtotal';

  @override
  String get foodDeliveryFee => 'Delivery fee';

  @override
  String get foodTotal => 'Total';

  @override
  String get foodCheckout => 'Checkout';

  @override
  String get foodLabel => 'Label';

  @override
  String get foodSubcity => 'Subcity';

  @override
  String get foodAddressDetails => 'Address details';

  @override
  String get foodNotesRider => 'Notes for rider / kitchen';

  @override
  String get foodSaving => 'Saving…';

  @override
  String get foodSaveAddress => 'Save this address';

  @override
  String get foodPaymentCod => 'Payment: Cash on delivery (COD)';

  @override
  String foodCustomize(String name) {
    return 'Customize $name';
  }

  @override
  String get foodAskOtp => 'Ask customer for OTP';

  @override
  String get foodKind => 'Kind';

  @override
  String get foodStoreOpen => 'Store open';

  @override
  String get foodStorePaused => 'Store paused';

  @override
  String get foodMarkAvailable => 'Mark available';

  @override
  String get foodMarkUnavailable => 'Mark unavailable';

  @override
  String foodOwner(String name) {
    return 'Owner: $name';
  }

  @override
  String foodCovers(String areas) {
    return 'Covers $areas';
  }

  @override
  String get foodReassign => 'Reassign';

  @override
  String get foodStaffPhone => 'Staff phone';

  @override
  String get foodStaffPhoneHelper => 'Local 9 digits or +251…';

  @override
  String get foodUnavailable => 'Unavailable';

  @override
  String get foodSoldOut => 'Sold out';

  @override
  String get foodRsvpFree => 'RSVP free';

  @override
  String get foodRsvpPayDoor => 'RSVP · pay at door';

  @override
  String get rideGoAcross => 'Go across Addis';

  @override
  String get rideMapPickPickup => 'Tap the map to set pickup';

  @override
  String get rideMapPickDropoff => 'Tap the map to set drop-off';

  @override
  String get rideMapActiveTrip => 'Trip in progress — map is for reference';

  @override
  String get rideSearchHint => 'Bole, Piassa, Airport…';

  @override
  String get ridePickupYou => 'Pickup · you';

  @override
  String get ridePickup => 'Pickup';

  @override
  String get rideWaitingLocation => 'Waiting for location…';

  @override
  String get rideTapMapOnce => 'Tap the map once to set';

  @override
  String get rideMapPinWaiting => 'Map pin set — waiting for places from API';

  @override
  String get rideOutsideNote =>
      'That pin is outside Addis. Move it into the service area.';

  @override
  String get rideBaseEtb => 'Base ETB';

  @override
  String get ridePerKmEtb => 'Per km ETB';

  @override
  String get rideMinFareEtb => 'Min fare ETB';

  @override
  String get rideOfferRadiusKm => 'Offer radius km';

  @override
  String get rideOpsApiOnly => 'Ride ops requires API mode.';

  @override
  String get rideCancelledByOps => 'Cancelled by Ride ops';

  @override
  String get rideApprove => 'Approve';

  @override
  String get rideSuspend => 'Suspend';

  @override
  String rideCashVehicle(Object amount, String vehicle) {
    return '$amount ETB cash · $vehicle';
  }

  @override
  String get rideDriverMode => 'Driver mode';

  @override
  String get rideGoOnline => 'Go online';

  @override
  String get eventsNavBrowse => 'Browse';

  @override
  String get eventsNavHost => 'Host';

  @override
  String get eventsSoldOut => 'Sold out';

  @override
  String eventsSeatsLeft(int count) {
    return '$count seats left';
  }

  @override
  String get eventsOrganizer => 'Organizer';

  @override
  String get eventsRsvpFree => 'RSVP free';

  @override
  String get eventsRsvpPayDoor => 'RSVP · pay at door';

  @override
  String get eventsFree => 'Free';

  @override
  String eventsPricePayDoor(Object amount) {
    return 'ETB $amount · pay at door';
  }

  @override
  String get eventsTicketCode => 'Ticket code';

  @override
  String get eventsReason => 'Reason';

  @override
  String get eventsMonthJan => 'Jan';

  @override
  String get eventsMonthFeb => 'Feb';

  @override
  String get eventsMonthMar => 'Mar';

  @override
  String get eventsMonthApr => 'Apr';

  @override
  String get eventsMonthMay => 'May';

  @override
  String get eventsMonthJun => 'Jun';

  @override
  String get eventsMonthJul => 'Jul';

  @override
  String get eventsMonthAug => 'Aug';

  @override
  String get eventsMonthSep => 'Sep';

  @override
  String get eventsMonthOct => 'Oct';

  @override
  String get eventsMonthNov => 'Nov';

  @override
  String get eventsMonthDec => 'Dec';

  @override
  String get adminLocalPhone => 'Local phone (9 digits)';

  @override
  String get adminRole => 'Role';

  @override
  String get homeAddisOs => 'Addis OS';

  @override
  String get homeStaff => 'Staff';

  @override
  String get authSignalEthiopia => 'Signal · Ethiopia';

  @override
  String get authVerifyChannel => 'Verify channel';

  @override
  String get authPhoneInvalid => 'Enter a valid Ethiopian mobile number';

  @override
  String get authOtpInvalid => 'Enter the 6-digit code';

  @override
  String get back => 'Back';

  @override
  String get moduleOnlineSoon => 'Module · online soon';

  @override
  String get suspend => 'Suspend';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get foodExtraCheeseHint => 'e.g. Extra cheese';

  @override
  String get foodOpsMenuExplain =>
      'Food ops does not edit restaurant menus here. Open Food ops to create a merchant and Assign owner phone to the restaurant staff. Only that owner can add dishes.';

  @override
  String get foodMerchantAssignExplain =>
      'Ask Food ops to assign your phone as the owner of one restaurant. You can only edit that restaurant’s menu — never another store’s.';

  @override
  String foodRiderLabel(String id) {
    return 'Rider: $id';
  }

  @override
  String get foodCoverageLabel => 'Coverage (comma-separated)';

  @override
  String get foodUnassigned => 'unassigned';

  @override
  String get foodOpsMarkDelivered => 'Ops: mark delivered (no OTP)';

  @override
  String get foodOpsForceAdvance => 'Ops: force advance status';

  @override
  String get foodHomeLabel => 'Home';

  @override
  String get eventsTicketHint => 'MK-…';

  @override
  String get listSeparator => ',';

  @override
  String get placeAddisAbaba => 'Addis Ababa';

  @override
  String get placeAddisKetema => 'Addis Ketema';

  @override
  String get placeArada => 'Arada';

  @override
  String get placeBole => 'Bole';

  @override
  String get placeBoleAirport => 'Bole Airport';

  @override
  String get placeBoleAtlas => 'Bole Atlas';

  @override
  String get placeCmc => 'CMC';

  @override
  String get placeCmcMichael => 'CMC Michael';

  @override
  String get placeGulele => 'Gulele';

  @override
  String get placeKazanchis => 'Kazanchis';

  @override
  String get placeKirkos => 'Kirkos';

  @override
  String get placeLideta => 'Lideta';

  @override
  String get placeMexicoSquare => 'Mexico Square';

  @override
  String get placeNifasSilk => 'Nifas Silk';

  @override
  String get placePiassa => 'Piassa';

  @override
  String get placeSarbet => 'Sarbet';

  @override
  String get placeYeka => 'Yeka';

  @override
  String get locationTurnOn => 'Turn on location services to use pickup.';

  @override
  String get locationDenied => 'Location permission denied.';

  @override
  String get locationBlocked =>
      'Location permission is blocked. Enable it in system settings.';

  @override
  String get locationNoPickupPlaces => 'No pickup places available.';

  @override
  String get authStartAgain => 'Start again with your phone number.';

  @override
  String authApiUnreachable(String url) {
    return 'Could not reach Maekel API at $url';
  }

  @override
  String get authOtpGateway => 'Could not verify OTP. Is the gateway running?';

  @override
  String get eventsCategoriesNotLoaded => 'Categories/areas not loaded yet.';

  @override
  String get eventsTitleVenueRequired => 'Title and venue are required.';

  @override
  String get eventsCapacityMin => 'Capacity must be at least 1.';

  @override
  String get eventsRejectDefault => 'Does not meet guidelines';

  @override
  String get foodSavedLabel => 'Saved';

  @override
  String foodEtaFee(Object minutes, Object fee) {
    return '$minutes min · $fee ETB fee';
  }

  @override
  String foodCheckoutSummary(Object subtotal, Object fee, Object total) {
    return 'Subtotal $subtotal ETB + delivery $fee ETB = $total ETB';
  }

  @override
  String foodModifierPrice(Object amount) {
    return '(+$amount ETB)';
  }

  @override
  String foodOptionsCount(int count) {
    return '$count option(s)';
  }

  @override
  String foodPriceEtb(Object amount) {
    return '$amount ETB';
  }

  @override
  String foodPriceEtbCod(Object amount) {
    return '$amount ETB COD';
  }

  @override
  String get rideVehicleEconomy => 'Economy';

  @override
  String requestFailed(Object code) {
    return 'Request failed ($code)';
  }

  @override
  String get sellerYou => 'You';

  @override
  String marketLocationAddis(String subcity) {
    return '$subcity, Addis Ababa';
  }

  @override
  String get eventStatusDraft => 'Draft';

  @override
  String get eventStatusRejected => 'Rejected';

  @override
  String get eventStatusEnded => 'Ended';

  @override
  String get ticketStatusReserved => 'Reserved';

  @override
  String get ticketStatusCheckedIn => 'Checked in';

  @override
  String get eventsPhotos => 'Photos';

  @override
  String get eventsAddPhoto => 'Add at least one photo.';

  @override
  String get eventsMaxPhotos => 'Max 8 photos.';

  @override
  String get eventsPhotosOptional => 'Photos (optional, up to 8)';
}
