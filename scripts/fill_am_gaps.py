# -*- coding: utf-8 -*-
"""Fill remaining English-identical keys in am/ti (and key om/so/aa)."""
from __future__ import annotations

import json
from pathlib import Path

L10N = Path("lib/l10n")

AM = {
    "phoneHint": "9XXXXXXXX",
    "phonePrefix": "+251",
    "rideStubBody": "የጉዞ ማጣመር እና ካርታ በኋላ ይመጣሉ።",
    "rideDriverStubBody": "የሹፌር ሁነታ — ተገኝነት፣ ስራዎች እና ገቢ።",
    "marketStubBody": "ለአዲስ አበባ የተመደበ ገበያ።",
    "marketSellStubBody": "በፎቶ እና በብር ዋጋ ማስታወቂያ ይፍጠሩ።",
    "foodStubBody": "ሬስቶራንቶችን ያስሱ እና ለአዲስ መላኪያ ጋሪ ይጠቀሙ።",
    "brickBreakerStub": "ፓድል ለማንቀሳቀስ ይጎትቱ · ለመጀመር ነካ",
    "tetrisStub": "ስዋይፕ · ለማሽከርከር ነካ · ሁለቴ ነካ ለማውረድ",
    "yes": "አዎ",
    "no": "አይ",
    "rideMapHint": "+/− ዙም · ለፒን ጠቅ · ለማንቀሳቀስ ይጎትቱ",
    "marketOpsPending": "በመጠባበቅ ላይ ({count})",
    "marketOpsQueueEmpty": "ወረፋ ባዶ — የሚገመገም የለም።",
    "marketOpsReports": "ክፍት ሪፖርቶች ({count})",
    "marketOpsNoReports": "ክፍት ሪፖርት የለም።",
    "marketOpsCategories": "የምድብ ቅንብር ({count})",
    "marketOpsNoCategories": "ምድብ የለም። ለመሸጥ የመጀመሪያውን ያክሉ።",
    "marketOpsLimits": "ገደቦች",
    "marketOpsSuspendSeller": "ሻጭ አንሳ",
    "marketOpsUnpublish": "ከሕትመት አውጣ",
    "marketOpsSuspend": "አንሳ",
    "marketOpsOpenAd": "ማስታወቂያ ክፈት",
    "marketOpsRejectAd": "ማስታወቂያ ውድቅ",
    "marketOpsAddCategory": "ምድብ አክል",
    "marketOpsMaxFreeAds": "ከፍተኛ ነፃ ንቁ ማስታወቂያዎች",
    "foodOpenOps": "የምግብ ኦፕስ ክፈት",
    "foodNoDishes": "ምግብ የለም። ደንበኞች እንዲያዙ ስም + ዋጋ ያክሉ።",
    "foodOrderQueue": "የትዕዛዝ ወረፋ ({count})",
    "foodNoKitchenOrders": "ክፍት የኩሽና ትዕዛዝ የለም።",
    "foodClaimJob": "ስራ ይያዙ",
    "foodPickedUp": "ተወስዷል",
    "foodOnTheWay": "በመንገድ ላይ",
    "foodCompleteCod": "ጨርስ + ኮድ",
    "foodMyJobs": "የእኔ ስራዎች ({count})",
    "foodNoActiveDelivery": "ንቁ መላኪያ የለም።",
    "foodAvailable": "ይገኛል ({count})",
    "foodNoReadyOrders": "ለራይደር ዝግጁ ትዕዛዝ የለም።",
    "foodConfirmCod": "ኮድ አረጋግጥ",
    "foodCollectCod": "{amount} ብር ኮድ ሰብስብ",
    "foodOrderBoard": "የትዕዛዝ ሰሌዳ ({count})",
    "foodNoRecentOrders": "የቅርብ ጊዜ ትዕዛዝ የለም።",
    "foodCreateMerchant": "ነጋዴ ፍጠር",
    "foodMerchants": "ነጋዴዎች ({count})",
    "foodSupportCancel": "ድጋፍ ሰርዝ",
    "foodClearRider": "ራይደር አጽዳ",
    "eventsPending": "በመጠባበቅ ({count})",
    "eventsQueueClear": "ወረፋ ባዶ።",
    "eventsLive": "ቀጥታ ({count})",
    "eventsForceCancel": "በግድ ሰርዝ",
    "eventsSuspendOrganizer": "አደራጅ አንሳ",
    "eventsReject": "ዝግጅት ውድቅ",
    "gamesBrickHint": "ፓድል ለማንቀሳቀስ ይጎትቱ · ለመጀመር ነካ",
    "gamesCandyHint": "ከረሜላ ወደ ጎረቤት ይጎትቱ · ወይም ሁለቴ ነካ ለመለዋወጥ",
    "gamesTetrisHint": "ስዋይፕ · ለማሽከርከር ነካ · ሁለቴ ነካ ለማውረድ",
    "gamesRoadHint": "◀ ▶ አስወግድ · ሐምራዊ መኪኖች መስመር ይቀይራሉ · ነዳጅ F ይያዙ",
    "adminMarketModerator": "የገበያ አስተባባሪ",
    "adminPlatformAdmin": "የመድረክ አስተዳዳሪ",
    "adminMarketOps": "የገበያ ኦፕስ",
    "adminFoodOps": "የምግብ ኦፕስ",
    "adminFoodMerchant": "የምግብ ነጋዴ",
    "adminFoodRider": "የምግብ ራይደር",
    "adminRideOps": "የጉዞ ኦፕስ",
    "adminEventsOps": "የዝግጅት ኦፕስ",
    "rideRouteArrow": "{from} → {to}",
    "rideDriverMeta": "{car} · {plate} · ★ {rating}",
    "marketSubcityCondition": "{subcity} · {condition}",
    "foodOrderBoardLine": "{merchant} → {subcity} · {amount} ብር",
    "foodNoDeliverPin": "ወደ {pin} የሚያደርሱ ነጋዴዎች የሉም",
    "eventsWhenSubcity": "{when} · {subcity}",
    "eventsVenueCategory": "{venue} · {category}",
    "eventsTicketQtyStatus": "ብዛት {qty} · {status}",
    "eventsHostMeta": "{status} · {sold}/{capacity} · {subcity}",
    "adminNoAdminPhones": "ADMIN_PHONES በኤፒአይ ላይ አልተዋቀረም። የመጀመሪያውን አስተዳዳሪ ለማስጀመር ያዋቅሩ።",
    "adminBootstrapPhones": "የማስጀመሪያ ስልኮች (env)፡ {phones}",
    "marketSpecHintPhones": "ለምሳሌ 128GB",
    "marketSpecHintVehicles": "ለምሳሌ 2019",
    "marketSpecHintProperty": "ለምሳሌ ኪራይ / ሽያጭ",
    "marketSpecHintElectronics": "ለምሳሌ 55 ኢንች",
    "marketSpecHintGeneric": "ዋና መግለጫ",
    "marketExtraDetailName": "ተጨማሪ ዝርዝር ስም",
    "marketExtraDetailHint": "ለምሳሌ ቀለም",
    "marketExtraValue": "ዋጋ/እሴት",
    "marketExtraValueHint": "ለምሳሌ ጥቁር",
    "marketDisplayNameHint": "ለምሳሌ ሕፃናት እና ልጆች",
    "marketIdOptional": "መታወቂያ (አማራጭ)",
    "marketIdAutoHint": "ባዶ ከሆነ ከስም በራሱ",
    "marketRejectReasonHint": "ለሻጭ የሚታይ ምክንያት…",
    "marketLimitLabel": "ገደብ (1–50)",
    "marketLimitHelper": "በሻጭ፡ የጸደቁ + በመጠባበቅ ብዛት",
    "marketDismissed": "ተሰናብቷል",
    "marketSuspendedFromOps": "ከኦፕስ ወረፋ ታግዷል",
    "marketCategoryMeta": "መታወቂያ፡ {id} · አዶ፡ {icon}",
    "foodStaffPhoneHelper": "የአካባቢ 9 አሃዝ ወይም +251…",
    "foodSoldOut": "ተሽጦ አልቋል",
    "foodRsvpFree": "ነፃ RSVP",
    "foodRsvpPayDoor": "RSVP · በበሩ ይክፈሉ",
    "rideGoAcross": "በአዲስ አበባ ይጓዙ",
    "rideMapPickPickup": "መነሻ ለመመደብ ካርታውን ነካ",
    "rideMapPickDropoff": "መድረሻ ለመመደብ ካርታውን ነካ",
    "rideMapActiveTrip": "ጉዞ በሂደት ላይ — ካርታ ለማጣቀሻ ነው",
    "rideMapPinWaiting": "ፒን ተቀምጧል — ቦታዎች ከኤፒአይ በመጠባበቅ ላይ",
    "rideOutsideNote": "ያ ፒን ከአዲስ አበባ ውጭ ነው። ወደ አገልግሎት አካባቢ ያንቀሳቅሱት።",
    "rideOpsApiOnly": "የጉዞ ኦፕስ የኤፒአይ ሁነታ ይፈልጋል።",
    "rideCancelledByOps": "በጉዞ ኦፕስ ተሰርዟል",
    "rideCashVehicle": "{amount} ብር ጥሬ · {vehicle}",
    "eventsTicketHint": "MK-…",
}

# Tigrinya: reuse Amharic script where close, override a few
TI = {
    **AM,
    "yes": "እወ",
    "no": "ኣይኮነን",
    "rideGoAcross": "ኣብ ኣዲስ ኣበባ ተጓዓዝ",
    "foodNoDeliverPin": "ናብ {pin} ዝብጽሑ ነጋዶታት የለዉን",
    "adminMarketModerator": "ኣስተባባሪ ገበያ",
    "adminPlatformAdmin": "ኣስተዳደሪ መድረኽ",
}

OM = {
    "yes": "Eeyyee",
    "no": "Lakki",
    "rideGoAcross": "Addis keessa imali",
    "foodNoDeliverPin": "Gara {pin} geessan daldaltoonni hin jiran",
    "foodSoldOut": "Gurguramee dhume",
    "marketOpsSuspend": "Dhaabi",
    "marketOpsUnpublish": "Maxxansa haqi",
    "foodClaimJob": "Hojii fudhadhu",
    "foodPickedUp": "Fudhatame",
    "foodOnTheWay": "Karaa irratti",
    "adminMarketOps": "Ops gabaa",
    "adminFoodOps": "Ops nyaataa",
    "adminRideOps": "Ops imalaa",
    "adminEventsOps": "Ops taatee",
}

SO = {
    "yes": "Haa",
    "no": "Maya",
    "rideGoAcross": "Ku soco Addis",
    "foodNoDeliverPin": "Ganacsatada u gudbiya {pin} ma jiraan",
    "foodSoldOut": "Waa la iibiyay",
    "marketOpsSuspend": "Jooji",
    "foodClaimJob": "Qabo shaqada",
    "foodPickedUp": "La qaaday",
    "foodOnTheWay": "Waddada ku jira",
}


def load(name: str) -> dict:
    return json.loads((L10N / name).read_text(encoding="utf-8"))


def save(name: str, data: dict) -> None:
    (L10N / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def apply(name: str, overrides: dict) -> None:
    data = load(name)
    n = 0
    for k, v in overrides.items():
        if k in data:
            data[k] = v
            n += 1
    save(name, data)
    print(f"{name}: updated {n}")


def main() -> None:
    apply("app_am.arb", AM)
    apply("app_ti.arb", TI)
    apply("app_om.arb", OM)
    apply("app_so.arb", SO)


if __name__ == "__main__":
    main()
