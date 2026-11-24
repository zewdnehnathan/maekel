# -*- coding: utf-8 -*-
"""Mechanically wire common hardcoded UI strings to AppLocalizations."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ROOT / "lib" / "features"

IMPORT = "import '../../../l10n/app_localizations.dart';"
IMPORT_DEPTH = {
    3: "import '../../../l10n/app_localizations.dart';",
    4: "import '../../../../l10n/app_localizations.dart';",
}

# Exact string literal -> l10n getter (without l10n. prefix in map value)
# Applied inside Text('...'), title: '...', tooltip: '...', hintText: '...', label: '...', child: Text('...')
SIMPLE = {
    "Cancel": "cancel",
    "Save": "save",
    "Edit": "edit",
    "Delete": "delete",
    "Open": "open",
    "Submit": "submit",
    "Approve": "approve",
    "Reject": "reject",
    "Clear": "clear",
    "Apply": "apply",
    "Add": "add",
    "Dismiss": "dismiss",
    "Keep": "keep",
    "Skip": "skip",
    "Accept": "accept",
    "Retry": "retry",
    "All": "all",
    "Online": "online",
    "Offline": "offline",
    "Sold out": "soldOut",
    "Unavailable": "unavailable",
    "Preparing": "preparing",
    "Ready": "ready",
    "Gallery": "gallery",
    "Camera": "camera",
    "Details": "details",
    "PHOTOS": "photos",
    "COVER": "cover",
    "DETAILS": "details",
    "SELLER": "marketSeller",
    "MENU": "foodMenu",
    "ITEMS": "foodItems",
    "Qty": "qty",
    "PICKUP": "foodPickup",
    "DROPOFF": "foodDropoff",
    "Sign in required": "signInRequired",
    "Not found": "notFound",
    "Ad not found": "marketAdNotFound",
    "Trip not found": "rideTripNotFound",
    "Order not found": "foodOrderNotFound",
    "No trips yet.": "rideNoTripsYet",
    "No active trips.": "rideNoActiveTrips",
    "Force cancel": "rideForceCancel",
    "Fare config saved": "rideFareConfigSaved",
    "FARE CONFIG": "rideFareConfig",
    "SAVE FARE PARAMS": "rideSaveFareParams",
    "ACTIVE JOB": "rideActiveJob",
    "COMPLETE + CONFIRM CASH": "rideCompleteCash",
    "REPORT A PROBLEM": "rideReportProblem",
    "Passenger no-show": "ridePassengerNoShow",
    "Wrong pin": "rideWrongPin",
    "OFFERS": "rideOffers",
    "ACCEPT": "accept",
    "TODAY'S EARNINGS": "rideTodaysEarnings",
    "CANCEL TRIP": "rideCancelTrip",
    "Rate your driver": "rideRateDriver",
    "SUBMIT RATING": "rideSubmitRating",
    "Go across Addis": "rideSubtitle",
    "Set pickup": "rideSetPickup",
    "Set dropoff": "rideSetDropoff",
    "Use my location": "rideUseMyLocation",
    "GET UPFRONT QUOTE": "rideGetQuote",
    "ECONOMY": "rideEconomy",
    "REQUEST RIDE": "rideRequest",
    "Pickup or drop-off is outside the Addis Ababa service area.": "rideOutsideServiceArea",
    "Pending Ride ops approval before you can go online.": "ridePendingApproval",
    "Go online to see matching requests.": "rideGoOnlineHint",
    "No open offers right now. When a passenger requests nearby, the offer appears here with a time limit.": "rideNoOffers",
    "No online drivers nearby. Ask a test driver to go Online on Drive, then Request again.": "rideNoDrivers",
    "+/− zoom · click to pin · drag to pan": "rideMapHint",
    "Buy & sell in Addis": "marketSubtitle",
    "Classifieds with chat. Inspect before you pay.": "marketBlurb",
    "Search phones, cars, furniture…": "marketSearchHint",
    "CATEGORIES": "marketCategories",
    "NEAR YOU": "marketNearYou",
    "No listings match. Try another area or clear filters.": "marketNoMatch",
    "All areas": "marketAllAreas",
    "Price range (ETB)": "marketPriceRangeEtb",
    "Minimum": "marketMinimum",
    "Maximum": "marketMaximum",
    "Minimum cannot be higher than maximum.": "marketMinMaxError",
    "Any condition": "marketAnyCondition",
    "Newest": "marketSortNewest",
    "Price: low to high": "marketSortPriceLow",
    "Price: high to low": "marketSortPriceHigh",
    "CHAT WITH SELLER": "marketChatSeller",
    "CALL SELLER": "marketCallSeller",
    "Seller hid their phone. Use chat.": "marketSellerHidPhone",
    "This is your listing.": "marketYourListing",
    "EDIT LISTING": "marketEditListing",
    "Report listing": "marketReportListing",
    "Report sent to ops.": "marketReportSent",
    "No ads in this category yet.": "marketNoAdsInCategory",
    "No saved ads yet.": "marketNoFavorites",
    "No chats yet. Open an ad and tap Chat.": "marketNoChats",
    "Show phone on ads": "marketShowPhone",
    "No ads yet": "marketNoAdsYet",
    "Post something to sell in Addis.": "marketPostSomething",
    "SELL NOW": "marketSellNow",
    "Mark sold": "marketMarkSold",
    "Before you contact": "marketBeforeContact",
    "I understand": "marketIUnderstand",
    "Max 8 photos.": "marketMaxPhotos",
    "Pick a category and area.": "marketPickCategoryArea",
    "Add at least one photo.": "marketAddPhoto",
    "KEY DETAILS": "marketKeyDetails",
    "Queue empty — nothing to moderate.": "marketOpsQueueEmpty",
    "No open reports.": "marketOpsNoReports",
    "Suspend seller": "marketOpsSuspendSeller",
    "Unpublish": "marketOpsUnpublish",
    "Suspend": "marketOpsSuspend",
    "Open ad": "marketOpsOpenAd",
    "Reject ad": "marketOpsRejectAd",
    "Add category": "marketOpsAddCategory",
    "Max active free ads": "marketOpsMaxFreeAds",
    "LIMITS": "marketOpsLimits",
    "SELL": "marketSellAction",
    "Deliver in Addis": "foodSubtitle",
    "Restaurants & groceries · COD · OTP handover": "foodBlurb",
    "DELIVERY PIN": "foodDeliveryPin",
    "Search merchants or dishes…": "foodSearchHint",
    "Restaurants": "foodRestaurants",
    "Groceries": "foodGroceries",
    "Try another delivery pin nearby.": "foodTryOtherPin",
    "Merchant console": "foodMerchantConsole",
    "Rider": "foodRider",
    "Food ops": "foodOps",
    "Your cart is empty.": "foodCartEmpty",
    "CHECKOUT · COD": "foodCheckoutCod",
    "Address saved": "foodAddressSaved",
    "Pay cash on delivery. Delivery fee shown before you confirm — no surprises.": "foodCodBlurb",
    "SAVED PLACES": "foodSavedPlaces",
    "No saved places yet — fill address below and tap Save.": "foodNoSavedPlaces",
    "ADD TO CART": "foodAddToCart",
    "Replace cart?": "foodReplaceCart",
    "Clear & add": "foodClearAndAdd",
    "No orders yet.": "foodNoOrders",
    "Delivery OTP": "foodDeliveryOtp",
    "Show this code to the rider. They collect COD and enter OTP in the rider app.": "foodDeliveryOtpHint",
    "CANCEL ORDER": "foodCancelOrder",
    "You can no longer cancel. The shop has already started preparing this order. Contact support if you need help.": "foodCannotCancel",
    "NO RESTAURANT LINKED": "foodNoRestaurant",
    "Open Food ops": "foodOpenOps",
    "Add dish": "foodAddDish",
    "No dishes yet. Add name + price so customers can order.": "foodNoDishes",
    "No open kitchen orders.": "foodNoKitchenOrders",
    "Claim job": "foodClaimJob",
    "Picked up": "foodPickedUp",
    "On the way": "foodOnTheWay",
    "Complete + COD": "foodCompleteCod",
    "No active delivery.": "foodNoActiveDelivery",
    "No ready orders waiting for a rider.": "foodNoReadyOrders",
    "Confirm COD": "foodConfirmCod",
    "No recent orders.": "foodNoRecentOrders",
    "ONBOARD MERCHANT": "foodOnboardMerchant",
    "Create merchant": "foodCreateMerchant",
    "Support cancel": "foodSupportCancel",
    "Clear rider": "foodClearRider",
    "Assign": "foodAssign",
    "Search events, venues…": "eventsSearchHint",
    "Any area": "eventsAnyArea",
    "No upcoming events yet. Host one from the + button.": "eventsEmpty",
    "RSVP cancelled": "eventsRsvpCancelled",
    "Your ticket": "eventsYourTicket",
    "Cancel RSVP": "eventsCancelRsvp",
    "Submitted for review — Events ops must approve.": "eventsSubmitted",
    "Starts": "eventsStarts",
    "Pick": "eventsPick",
    "Checked in": "eventsCheckedIn",
    "You have not hosted an event yet.": "eventsNotHosted",
    "Attendees": "eventsAttendees",
    "Check in": "eventsCheckIn",
    "No tickets yet. RSVP from Browse.": "eventsNoTickets",
    "Queue clear.": "eventsQueueClear",
    "Suspend organizer": "eventsSuspendOrganizer",
    "Reject event": "eventsReject",
    "Events ops": "eventsOps",
    "Create event": "eventsCreate",
    "QUICK PLAY": "gamesQuickPlay",
    "Play offline, sync your best scores to the Addis board.": "gamesHubBody",
    "ADDIS TOP 3": "gamesAddisTop3",
    "Leaderboard offline — start backend games-service to see Addis top 3.": "gamesLeaderboardOffline",
    "No scores yet — be the first in Addis.": "gamesNoScores",
    "Score not saved — username required.": "gamesScoreNotSaved",
    "Could not sync score. Is the API running?": "gamesSyncFailed",
    "Choose a username": "gamesChooseUsername",
    "Shown on the Addis Ababa top 3 leaderboard.": "gamesUsernameHint",
    "Save score": "gamesSaveScore",
    "TAP TO LAUNCH": "gamesTapToLaunch",
    "Drag to move paddle · tap to launch": "gamesBrickHint",
    "Drag a candy onto a neighbor · or tap-tap to swap": "gamesCandyHint",
    "Swipe · tap rotate · double-tap hard drop": "gamesTetrisHint",
    "◀ ▶ dodge · purple-stripe cars change lanes · grab F for fuel": "gamesRoadHint",
    "FUEL": "gamesFuel",
    "Stack · clear lines · level up": "gamesTetrisSubtitle",
    "Bounce · smash bricks · survive": "gamesBrickSubtitle",
    "Swap · match 3 · cascade score": "gamesCandySubtitle",
    "Dodge · fuel up · drive farther": "gamesRoadSubtitle",
    "Platform admin only": "adminPlatformOnly",
    "Staff & admins": "adminTitle",
    "GRANT ROLE": "adminGrantRole",
    "GRANT": "adminGrant",
    "No staff roles assigned yet.": "adminNoStaff",
    "Role granted. They must sign out and OTP again to refresh the JWT.": "adminRoleGranted",
    "Market moderator": "adminMarketModerator",
    "Platform admin": "adminPlatformAdmin",
    "Market ops": "adminMarketOps",
    "Food merchant": "adminFoodMerchant",
    "Food rider": "adminFoodRider",
    "Ride ops": "adminRideOps",
}

TITLE_MAP = {
    "Ride": "rideTitle",
    "Drive": "rideDriveTitle",
    "Trip": "rideTripTitle",
    "Trips": "rideTripsTitle",
    "Ride ops": "rideOpsTitle",
    "Market": "marketTitle",
    "Food": "foodTitle",
    "Events": "eventsTitle",
    "Games": "gamesTitle",
}


def depth_for(path: Path) -> int:
    # lib/features/x/screens/file.dart -> 3
    # lib/features/x/components/file.dart -> 3
    rel = path.relative_to(FEATURES)
    return len(rel.parts)  # e.g. ride/screens/foo.dart = 3


def ensure_import(text: str, path: Path) -> str:
    if "app_localizations.dart" in text:
        return text
    d = depth_for(path)
    # from features/mod/screens -> ../../../l10n
    # from features/mod/components -> ../../../l10n
    imp = "import '../../../l10n/app_localizations.dart';\n"
    # insert after last import
    lines = text.splitlines(keepends=True)
    last_import = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            last_import = i
    lines.insert(last_import + 1, imp)
    return "".join(lines)


def ensure_l10n_local(text: str) -> str:
    if "AppLocalizations.of(context)" in text:
        return text
    # Insert at start of build methods that use context
    pattern = re.compile(
        r"(Widget build\(BuildContext context(?:, WidgetRef ref)?\) \{)"
    )

    def repl(m: re.Match) -> str:
        return (
            m.group(1)
            + "\n    final l10n = AppLocalizations.of(context)!;"
        )

    new, n = pattern.subn(repl, text, count=3)
    return new if n else text


def replace_literals(text: str) -> tuple[str, int]:
    count = 0

    # title: 'Ride' style for app bars
    for lit, key in TITLE_MAP.items():
        for quote in ("'", '"'):
            old = f"title: {quote}{lit}{quote}"
            new = f"title: l10n.{key}"
            if old in text:
                text = text.replace(old, new)
                count += 1

    # tooltip: '...'
    for lit, key in SIMPLE.items():
        for quote in ("'", '"'):
            for prefix in ("tooltip: ", "hintText: ", "labelText: ", "label: "):
                old = f"{prefix}{quote}{lit}{quote}"
                new = f"{prefix}l10n.{key}"
                c = text.count(old)
                if c:
                    text = text.replace(old, new)
                    count += c

    # Text('...') and const Text('...')
    # Prefer longer literals first
    for lit in sorted(SIMPLE.keys(), key=len, reverse=True):
        key = SIMPLE[lit]
        for quote in ("'", '"'):
            for const in ("const Text(", "Text("):
                old = f"{const}{quote}{lit}{quote})"
                new = f"Text(l10n.{key})"
                c = text.count(old)
                if c:
                    text = text.replace(old, new)
                    count += c
            # child: Text('X') already covered
            # title: Text('X')
            old = f"title: Text({quote}{lit}{quote})"
            new = f"title: Text(l10n.{key})"
            c = text.count(old)
            if c:
                text = text.replace(old, new)
                count += c
            old = f"title: const Text({quote}{lit}{quote})"
            new = f"title: Text(l10n.{key})"
            c = text.count(old)
            if c:
                text = text.replace(old, new)
                count += c

    return text, count


def process(path: Path) -> int:
    original = path.read_text(encoding="utf-8")
    text, count = replace_literals(original)
    if count == 0:
        return 0
    text = ensure_import(text, path)
    text = ensure_l10n_local(text)
    # Remove invalid const before Text(l10n...)
    text = text.replace("const Text(l10n.", "Text(l10n.")
    text = text.replace("child: const Text(l10n.", "child: Text(l10n.")
    path.write_text(text, encoding="utf-8")
    return count


def main() -> None:
    total = 0
    files = 0
    for path in sorted(FEATURES.rglob("*.dart")):
        n = process(path)
        if n:
            files += 1
            total += n
            print(f"{path.relative_to(ROOT)}: {n} replacements")
    print(f"done: {total} replacements in {files} files")


if __name__ == "__main__":
    main()
