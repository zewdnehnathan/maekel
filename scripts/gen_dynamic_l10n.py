# -*- coding: utf-8 -*-
"""Append dynamic/enum/nav keys to ARBs and regenerate."""
from __future__ import annotations

import json
from pathlib import Path

L10N = Path("lib/l10n")

NEW_EN = {
    # ride status
    "rideStatusQuote": "Quote",
    "rideStatusRequested": "Requested",
    "rideStatusMatching": "Finding driver",
    "rideStatusAssigned": "Driver assigned",
    "rideStatusArriving": "Driver arriving",
    "rideStatusArrived": "Driver arrived",
    "rideStatusInProgress": "On trip",
    "rideStatusCompleted": "Completed",
    "rideStatusCancelled": "Cancelled",
    "rideNavRide": "Ride",
    "rideNavTrips": "Trips",
    "rideNavDrive": "Drive",
    "rideStartArriving": "Start arriving",
    "rideMarkArrived": "Mark arrived",
    "rideStartTrip": "Start trip",
    "rideAdvance": "Advance",
    "rideExpired": "Expired",
    "rideRefreshing": "Refreshing…",
    "rideCompletedTripsToday": "{count} completed trip(s) today",
    "rideRouteArrow": "{from} → {to}",
    "rideFareStatusCountdown": "{amount} ETB · {status} · {countdown}",
    "rideReported": "Reported: {reason}",
    "rideActiveTripStatus": "Active trip · {status}",
    "rideVehicleFare": "{amount} ETB · {vehicle}",
    "rideDriverMeta": "{car} · {plate} · ★ {rating}",
    # market
    "marketConditionNew": "Brand new",
    "marketConditionUsed": "Used",
    "marketConditionRefurbished": "Refurbished",
    "marketStatusPending": "Pending",
    "marketStatusActive": "Active",
    "marketStatusDeclined": "Declined",
    "marketStatusSold": "Sold",
    "marketNavBrowse": "Browse",
    "marketNavMyAds": "My ads",
    "marketNavSaved": "Saved",
    "marketNavChats": "Chats",
    "marketSafetyBody": "Meet in a public place. Inspect before you pay. Never send deposits to strangers. Maekel staff never ask for fees in chat.",
    "marketSafetyShort": "Safety: Meet in public. Inspect before paying. Never send deposits to strangers.",
    "marketPriceEtb": "{amount} ETB",
    "marketSubcityCondition": "{subcity} · {condition}",
    "marketPriceSubcity": "{amount} ETB · {subcity}",
    "marketCategoryTitle": "Category",
    "marketChatTitle": "Chat",
    "marketFavoritesTitle": "Favorites",
    # food
    "foodStatusPlaced": "Placed",
    "foodStatusConfirmed": "Confirmed",
    "foodStatusPreparing": "Preparing",
    "foodStatusReadyPickup": "Ready for pickup",
    "foodStatusPickedUp": "Picked up",
    "foodStatusOnTheWay": "On the way",
    "foodStatusDelivered": "Delivered",
    "foodStatusCancelled": "Cancelled",
    "foodClosedHours": "Closed · {hours}",
    "foodOrderLine": "{qty}× {name} — {amount} ETB",
    "foodOrderSummary": "{amount} ETB · {count} item(s)",
    "foodTotalCod": "Total {amount} ETB · COD",
    "foodOrderBoardLine": "{merchant} → {subcity} · {amount} ETB",
    "foodUnitPriceEach": "{amount} ETB each",
    "foodNoDeliverPin": "No merchants deliver to {pin}",
    "foodMerchantTitle": "Merchant",
    "foodOrderTitle": "Order",
    "foodCartTitle": "Cart",
    # events
    "eventsEditTitle": "Edit event",
    "eventsFieldTitle": "Title",
    "eventsFieldDescription": "Description",
    "eventsFieldCategory": "Category",
    "eventsFieldSubcity": "Subcity",
    "eventsFieldVenue": "Venue name",
    "eventsFieldAddress": "Address (optional)",
    "eventsFieldCapacity": "Capacity",
    "eventsFieldPrice": "Price ETB (0 = free)",
    "eventsPayAtDoor": "Guests pay at the door (COD-style).",
    "eventsFreeRsvp": "Free RSVP.",
    "eventsSubmitReview": "Submit for review",
    "eventsWhenSubcity": "{when} · {subcity}",
    "eventsVenueCategory": "{venue} · {category}",
    "eventsTicketQtyStatus": "Qty {qty} · {status}",
    "eventsHostMeta": "{status} · {sold}/{capacity} · {subcity}",
    # games
    "gamesScore": "Score",
    "gamesLives": "Lives",
    "gamesMoves": "Moves",
    "gamesCombo": "Combo",
    "gamesRestart": "Restart",
    "gamesPause": "Pause",
    "gamesResume": "Resume",
    "gamesMute": "Mute",
    "gamesUnmute": "Unmute",
    "gamesRefreshBoard": "Refresh leaderboard",
    "gamesPersonalBest": "New personal best: {score}",
    "gamesScoreSavedBest": "Score saved. Best remains {score}",
    "gamesUsernameLabel": "Username",
    "gamesUsernameHintExample": "e.g. BoleAce",
    # admin
    "adminPhoneDigits": "Enter a {count}-digit local number.",
    "adminRevoked": "Revoked {role} from {phone}",
    "adminNoAdminPhones": "No ADMIN_PHONES configured on the API. Set that env var to bootstrap the first platform admin.",
    "adminBootstrapPhones": "Bootstrap phones (env): {phones}",
}

PLACEHOLDERS = {
    "rideCompletedTripsToday": {"count": {"type": "int"}},
    "rideRouteArrow": {"from": {"type": "String"}, "to": {"type": "String"}},
    "rideFareStatusCountdown": {
        "amount": {"type": "Object"},
        "status": {"type": "String"},
        "countdown": {"type": "String"},
    },
    "rideReported": {"reason": {"type": "String"}},
    "rideActiveTripStatus": {"status": {"type": "String"}},
    "rideVehicleFare": {"amount": {"type": "Object"}, "vehicle": {"type": "String"}},
    "rideDriverMeta": {
        "car": {"type": "String"},
        "plate": {"type": "String"},
        "rating": {"type": "Object"},
    },
    "marketPriceEtb": {"amount": {"type": "String"}},
    "marketSubcityCondition": {
        "subcity": {"type": "String"},
        "condition": {"type": "String"},
    },
    "marketPriceSubcity": {
        "amount": {"type": "Object"},
        "subcity": {"type": "String"},
    },
    "foodClosedHours": {"hours": {"type": "String"}},
    "foodOrderLine": {
        "qty": {"type": "Object"},
        "name": {"type": "String"},
        "amount": {"type": "Object"},
    },
    "foodOrderSummary": {"amount": {"type": "Object"}, "count": {"type": "int"}},
    "foodTotalCod": {"amount": {"type": "Object"}},
    "foodOrderBoardLine": {
        "merchant": {"type": "String"},
        "subcity": {"type": "String"},
        "amount": {"type": "Object"},
    },
    "foodUnitPriceEach": {"amount": {"type": "Object"}},
    "foodNoDeliverPin": {"pin": {"type": "String"}},
    "eventsWhenSubcity": {"when": {"type": "String"}, "subcity": {"type": "String"}},
    "eventsVenueCategory": {
        "venue": {"type": "String"},
        "category": {"type": "String"},
    },
    "eventsTicketQtyStatus": {
        "qty": {"type": "Object"},
        "status": {"type": "String"},
    },
    "eventsHostMeta": {
        "status": {"type": "String"},
        "sold": {"type": "Object"},
        "capacity": {"type": "Object"},
        "subcity": {"type": "String"},
    },
    "gamesPersonalBest": {"score": {"type": "Object"}},
    "gamesScoreSavedBest": {"score": {"type": "Object"}},
    "adminPhoneDigits": {"count": {"type": "int"}},
    "adminRevoked": {"role": {"type": "String"}, "phone": {"type": "String"}},
    "adminBootstrapPhones": {"phones": {"type": "String"}},
}

# Compact translations for high-traffic keys; others fall back to EN.
AM = {
    "rideStatusQuote": "ዋጋ",
    "rideStatusRequested": "ተጠይቋል",
    "rideStatusMatching": "ሹፌር በመፈለግ ላይ",
    "rideStatusAssigned": "ሹፌር ተመድቧል",
    "rideStatusArriving": "ሹፌር እየመጣ ነው",
    "rideStatusArrived": "ሹፌር ደርሷል",
    "rideStatusInProgress": "በጉዞ ላይ",
    "rideStatusCompleted": "ተጠናቋል",
    "rideStatusCancelled": "ተሰርዟል",
    "rideNavRide": "ጉዞ",
    "rideNavTrips": "ጉዞዎች",
    "rideNavDrive": "መንዳት",
    "rideStartArriving": "መድረስ ጀምር",
    "rideMarkArrived": "ደርሷል ምልክት",
    "rideStartTrip": "ጉዞ ጀምር",
    "rideAdvance": "ቀጥል",
    "rideExpired": "ጊዜው አልፏል",
    "rideRefreshing": "በማደስ ላይ…",
    "rideCompletedTripsToday": "ዛሬ {count} የተጠናቀቁ ጉዞ(ዎች)",
    "rideRouteArrow": "{from} → {to}",
    "rideFareStatusCountdown": "{amount} ብር · {status} · {countdown}",
    "rideReported": "ተዘግቧል፡ {reason}",
    "rideActiveTripStatus": "ንቁ ጉዞ · {status}",
    "rideVehicleFare": "{amount} ብር · {vehicle}",
    "rideDriverMeta": "{car} · {plate} · ★ {rating}",
    "marketConditionNew": "አዲስ",
    "marketConditionUsed": "ያገለገለ",
    "marketConditionRefurbished": "ታድሷል",
    "marketStatusPending": "በመጠባበቅ ላይ",
    "marketStatusActive": "ንቁ",
    "marketStatusDeclined": "ውድቅ",
    "marketStatusSold": "ተሽጧል",
    "marketNavBrowse": "አስስ",
    "marketNavMyAds": "የእኔ ማስታወቂያዎች",
    "marketNavSaved": "የተቀመጡ",
    "marketNavChats": "ቻቶች",
    "marketSafetyBody": "በሕዝብ ቦታ ይገናኙ። ከመክፈልዎ በፊት ይመልከቱ። ለማያውቁ ሰዎች ተቀማጭ አይላኩ። የመአከል ሰራተኞች በቻት ክፍያ አይጠይቁም።",
    "marketSafetyShort": "ደህንነት፡ በሕዝብ ይገናኙ። ከመክፈል በፊት ይመልከቱ። ተቀማጭ አይላኩ።",
    "marketPriceEtb": "{amount} ብር",
    "marketSubcityCondition": "{subcity} · {condition}",
    "marketPriceSubcity": "{amount} ብር · {subcity}",
    "marketCategoryTitle": "ምድብ",
    "marketChatTitle": "ቻት",
    "marketFavoritesTitle": "ተወዳጆች",
    "foodStatusPlaced": "ተልኳል",
    "foodStatusConfirmed": "ተረጋግጧል",
    "foodStatusPreparing": "በዝግጅት ላይ",
    "foodStatusReadyPickup": "ለመውሰድ ዝግጁ",
    "foodStatusPickedUp": "ተወስዷል",
    "foodStatusOnTheWay": "በመንገድ ላይ",
    "foodStatusDelivered": "ደርሷል",
    "foodStatusCancelled": "ተሰርዟል",
    "foodClosedHours": "ዝግ · {hours}",
    "foodOrderLine": "{qty}× {name} — {amount} ብር",
    "foodOrderSummary": "{amount} ብር · {count} እቃ(ዎች)",
    "foodTotalCod": "ድምር {amount} ብር · ኮድ",
    "foodUnitPriceEach": "{amount} ብር እያንዳንዱ",
    "foodMerchantTitle": "ነጋዴ",
    "foodOrderTitle": "ትዕዛዝ",
    "foodCartTitle": "ጋሪ",
    "eventsEditTitle": "ዝግጅት አርትዕ",
    "eventsFieldTitle": "ርዕስ",
    "eventsFieldDescription": "መግለጫ",
    "eventsFieldCategory": "ምድብ",
    "eventsFieldSubcity": "ክፍለ ከተማ",
    "eventsFieldVenue": "የቦታ ስም",
    "eventsFieldAddress": "አድራሻ (አማራጭ)",
    "eventsFieldCapacity": "አቅም",
    "eventsFieldPrice": "ዋጋ ብር (0 = ነፃ)",
    "eventsPayAtDoor": "እንግዶች በበሩ ይከፍላሉ።",
    "eventsFreeRsvp": "ነፃ RSVP።",
    "eventsSubmitReview": "ለግምገማ ላክ",
    "gamesScore": "ነጥብ",
    "gamesLives": "ሕይወት",
    "gamesMoves": "እንቅስቃሴዎች",
    "gamesCombo": "ኮምቦ",
    "gamesRestart": "እንደገና ጀምር",
    "gamesPause": "አቁም",
    "gamesResume": "ቀጥል",
    "gamesMute": "ድምጽ አጥፋ",
    "gamesUnmute": "ድምጽ ክፈት",
    "gamesRefreshBoard": "ሰሌዳ አድስ",
    "gamesPersonalBest": "አዲስ የግል ምርጥ፡ {score}",
    "gamesScoreSavedBest": "ነጥብ ተቀምጧል። ምርጡ {score} ነው",
    "gamesUsernameLabel": "የተጠቃሚ ስም",
    "adminPhoneDigits": "{count}-አሃዝ የአካባቢ ቁጥር ያስገቡ።",
    "adminRevoked": "{role} ከ{phone} ተነስቷል",
}

OM = {
    "rideStatusRequested": "Gaafatame",
    "rideStatusMatching": "Konkolaachisaa barbaadaa",
    "rideStatusAssigned": "Konkolaachisaa ramadame",
    "rideStatusArriving": "Konkolaachisaa dhufaa jira",
    "rideStatusArrived": "Konkolaachisaa gaheera",
    "rideStatusInProgress": "Imala irratti",
    "rideStatusCompleted": "Xumurame",
    "rideStatusCancelled": "Haalamte",
    "rideNavRide": "Imala",
    "rideNavTrips": "Imaloota",
    "rideNavDrive": "Oofii",
    "marketConditionNew": "Haaraa",
    "marketConditionUsed": "Fayyadame",
    "marketNavBrowse": "Daawwadhu",
    "marketNavMyAds": "Beeksisa koo",
    "marketNavSaved": "Olkaa’aman",
    "marketNavChats": "Haasawa",
    "foodStatusPlaced": "Ergame",
    "foodStatusConfirmed": "Mirkanaa’e",
    "foodStatusDelivered": "Geesse",
    "gamesScore": "Qabxii",
    "gamesRestart": "Irra deebi’i",
    "gamesPause": "Dhaabi",
    "gamesResume": "Itti fufi",
}

SO = {
    "rideStatusRequested": "La codsaday",
    "rideStatusMatching": "Raadinaya darawal",
    "rideStatusAssigned": "Darawal ayaa loo qoondeeyay",
    "rideStatusArriving": "Darawalku wuu imanayaa",
    "rideStatusArrived": "Darawalku wuu yimid",
    "rideStatusInProgress": "Socdaalka ku jira",
    "rideStatusCompleted": "La dhammeeyay",
    "rideStatusCancelled": "La joojiyay",
    "rideNavRide": "Raacitaan",
    "rideNavTrips": "Safarada",
    "rideNavDrive": "Wadid",
    "marketConditionNew": "Cusub",
    "marketConditionUsed": "La isticmaalay",
    "marketNavBrowse": "Daawo",
    "marketNavMyAds": "Xayeysiisyadayda",
    "marketNavSaved": "La kaydiyay",
    "marketNavChats": "Wadahadalka",
    "foodStatusPlaced": "La diray",
    "foodStatusConfirmed": "La xaqiijiyay",
    "foodStatusDelivered": "La keenay",
    "gamesScore": "Dhibcaha",
    "gamesRestart": "Dib u bilow",
    "gamesPause": "Hakad",
    "gamesResume": "Sii wad",
}

TI = {**AM}  # reuse Amharic where close; override a few
TI.update(
    {
        "rideNavRide": "ጉዕዞ",
        "rideNavTrips": "ጉዕዞታት",
        "rideNavDrive": "ምንዳይ",
        "marketNavBrowse": "ዳህስስ",
        "gamesScore": "ነጥቢ",
    }
)

AA = {
    "rideNavRide": "Gura",
    "rideNavTrips": "Guritte",
    "rideNavDrive": "Oofi",
    "marketNavBrowse": "Daawwad",
    "marketNavMyAds": "Beeksisa yi",
    "gamesScore": "Qabxii",
    "gamesRestart": "Irra deebi",
}


def load(name: str) -> dict:
    return json.loads((L10N / name).read_text(encoding="utf-8"))


def save(name: str, data: dict) -> None:
    (L10N / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    n = sum(1 for k in data if not str(k).startswith("@"))
    print(f"{name}: {n} keys")


def merge_into(data: dict, locale: str, overrides: dict, with_meta: bool) -> dict:
    data["@@locale"] = locale
    for k, v in NEW_EN.items():
        data[k] = overrides.get(k, v)
        if with_meta and k in PLACEHOLDERS:
            data[f"@{k}"] = {"placeholders": PLACEHOLDERS[k]}
        elif f"@{k}" in data and not with_meta:
            # keep template-only meta on en
            pass
    return data


def main() -> None:
    en = load("app_en.arb")
    # strip old @meta for keys we're rewriting then re-add
    for k in list(en):
        if k.startswith("@") and k[1:] in NEW_EN:
            del en[k]
    en = merge_into(en, "en", {}, with_meta=True)
    save("app_en.arb", en)

    for name, locale, ov in [
        ("app_am.arb", "am", AM),
        ("app_ti.arb", "ti", TI),
        ("app_om.arb", "om", OM),
        ("app_aa.arb", "aa", AA),
        ("app_so.arb", "so", SO),
    ]:
        data = load(name)
        data = merge_into(data, locale, ov, with_meta=False)
        # drop @meta from non-en if present
        for k in list(data):
            if k.startswith("@") and k != "@@locale":
                del data[k]
        save(name, data)


if __name__ == "__main__":
    main()
