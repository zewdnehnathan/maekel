# -*- coding: utf-8 -*-
"""Append remaining static + dynamic UI keys to ARBs."""
from __future__ import annotations

import json
from pathlib import Path

L10N = Path("lib/l10n")

NEW_EN = {
    "gamesGameOver": "GAME OVER",
    "gamesPaused": "PAUSED",
    "gamesOutOfMoves": "OUT OF MOVES",
    "gamesOutOfFuel": "OUT OF FUEL",
    "gamesCrash": "CRASH!",
    "gamesLines": "Lines",
    "gamesLevel": "Lvl",
    "gamesKm": "KM",
    "gamesSpeed": "SPD",
    "gamesTapRefreshPlay": "Tap refresh to play again",
    "gamesTapRefreshTry": "Tap refresh to try again",
    "gamesTapPauseResume": "Tap pause to resume",
    "gamesScoreTapRefresh": "Score {score} · tap refresh",
    "gamesScoreTapRetry": "Score {score} · tap to retry",
    "gamesTapDragDrive": "Tap / drag to drive",
    "rideCallDriver": "Call driver",
    "ridePayCashLocked": "Pay cash at complete — fare locked at request.",
    "rideNoDriverAvailable": "No driver was available. Go back and try again.",
    "rideAcceptSoon": "Accept soon",
    "rideSecsLeft": "{secs}s left",
    "foodPlaceOrderEtb": "PLACE ORDER · {amount} ETB",
    "marketDetails": "Details",
    "marketAdd": "Add",
    "marketOpsQueueTooltip": "Ops queue",
    "foodAssignOwner": "Assign owner · {name}",
    "foodRestaurant": "Restaurant",
    "foodGrocery": "Grocery",
    "foodAddOption": "Add option",
    "marketNameMinChars": "Name must be at least 2 characters.",
    "marketAddedName": "Added “{name}”.",
    "marketUpdatedName": "Updated “{name}”.",
    "marketEditCategory": "Edit {id}",
    "marketEnterMaxAds": "Enter a number between 1 and 50.",
    "marketMaxActiveSet": "Max active ads set to {value}.",
}

PLACEHOLDERS = {
    "gamesScoreTapRefresh": {"score": {"type": "Object"}},
    "gamesScoreTapRetry": {"score": {"type": "Object"}},
    "rideSecsLeft": {"secs": {"type": "int"}},
    "foodPlaceOrderEtb": {"amount": {"type": "Object"}},
    "foodAssignOwner": {"name": {"type": "String"}},
    "marketAddedName": {"name": {"type": "String"}},
    "marketUpdatedName": {"name": {"type": "String"}},
    "marketEditCategory": {"id": {"type": "String"}},
    "marketMaxActiveSet": {"value": {"type": "Object"}},
}

AM = {
    "gamesGameOver": "ጨዋታ አለቀ",
    "gamesPaused": "ቆሟል",
    "gamesOutOfMoves": "እንቅስቃሴ አልቋል",
    "gamesOutOfFuel": "ነዳጅ አልቋል",
    "gamesCrash": "አደጋ!",
    "gamesLines": "መስመሮች",
    "gamesLevel": "ደረጃ",
    "gamesKm": "ኪሜ",
    "gamesSpeed": "ፍጥነት",
    "gamesTapRefreshPlay": "እንደገና ለመጫወት አድስን ነካ",
    "gamesTapRefreshTry": "እንደገና ለመሞከር አድስን ነካ",
    "gamesTapPauseResume": "ለመቀጠል አቁምን ነካ",
    "gamesScoreTapRefresh": "ነጥብ {score} · አድስን ነካ",
    "gamesScoreTapRetry": "ነጥብ {score} · እንደገና ለመሞከር ነካ",
    "gamesTapDragDrive": "ነካ / ጎትት ለመንዳት",
    "rideCallDriver": "ሹፌርን ደውል",
    "ridePayCashLocked": "በማጠናቀቅ ጊዜ በጥሬ ይክፈሉ — ዋጋ በጥያቄ ጊዜ ተቆልፏል።",
    "rideNoDriverAvailable": "ሹፌር አልተገኘም። ተመልሰው እንደገና ይሞክሩ።",
    "rideAcceptSoon": "በቅርብ ተቀበል",
    "rideSecsLeft": "{secs} ሰከንድ ቀርቷል",
    "foodPlaceOrderEtb": "ትዕዛዝ አስገባ · {amount} ብር",
    "marketDetails": "ዝርዝሮች",
    "marketAdd": "አክል",
    "marketOpsQueueTooltip": "የኦፕስ ወረፋ",
    "foodAssignOwner": "ባለቤት መድብ · {name}",
    "foodRestaurant": "ሬስቶራንት",
    "foodGrocery": "ግሮሰሪ",
    "foodAddOption": "አማራጭ አክል",
    "marketNameMinChars": "ስም ቢያንስ 2 ቁምፊ መሆን አለበት።",
    "marketAddedName": "“{name}” ተጨምሯል።",
    "marketUpdatedName": "“{name}” ተዘምኗል።",
    "marketEditCategory": "{id} አርትዕ",
    "marketEnterMaxAds": "ከ1 እስከ 50 ያለ ቁጥር ያስገቡ።",
    "marketMaxActiveSet": "ከፍተኛ ንቁ ማስታወቂያዎች ወደ {value} ተቀምጧል።",
}

TI = {
    "gamesGameOver": "ጸወታ ተወዲኡ",
    "gamesPaused": "ተኣቊሩ",
    "gamesOutOfMoves": "ምንቅስቓስ ተወዲኡ",
    "gamesOutOfFuel": "ነዳዲ ተወዲኡ",
    "gamesCrash": "ሓደጋ!",
    "gamesLines": "መስመራት",
    "gamesLevel": "ደረጃ",
    "gamesKm": "ኪሜ",
    "gamesSpeed": "ፍጥነት",
    "rideCallDriver": "ንሹፌር ደውል",
    "marketDetails": "ዝርዝራት",
    "marketAdd": "ውስኽ",
    "foodRestaurant": "ቤት ብልዒ",
    "foodGrocery": "ግሮሰሪ",
}

OM = {
    "gamesGameOver": "Taphaan xumurame",
    "gamesPaused": "Dhaabbate",
    "gamesOutOfMoves": "Sochiin dhume",
    "gamesOutOfFuel": "Boba'aan dhume",
    "gamesCrash": "Balaa!",
    "gamesLines": "Sarara",
    "gamesLevel": "Sadarkaa",
    "gamesKm": "KM",
    "gamesSpeed": "Saffisa",
    "rideCallDriver": "Konkolaachisaa bilbilii",
    "marketDetails": "Ibsa",
    "marketAdd": "Ida'i",
    "foodRestaurant": "Mana nyaataa",
    "foodGrocery": "Suuqii",
}

AA = {
    "gamesGameOver": "Ciyaar tekkek",
    "gamesPaused": "Gexxe",
    "gamesOutOfMoves": "Moxxite gufte",
    "gamesOutOfFuel": "Boba'a gufte",
    "gamesCrash": "Balaa!",
    "gamesLines": "Sarara",
    "gamesLevel": "Daraja",
    "rideCallDriver": "Driver bilbil",
    "marketDetails": "Faahfaahin",
    "marketAdd": "Kadar",
}

SO = {
    "gamesGameOver": "Ciyaartii wayday",
    "gamesPaused": "Hakad",
    "gamesOutOfMoves": "Dhaqdhaqaaq ma arna",
    "gamesOutOfFuel": "Shidaalku dhamaaday",
    "gamesCrash": "Shil!",
    "gamesLines": "Xariiqyo",
    "gamesLevel": "Heer",
    "gamesKm": "KM",
    "gamesSpeed": "Xawaare",
    "rideCallDriver": "Wac darawalka",
    "marketDetails": "Faahfaahin",
    "marketAdd": "Kudar",
    "foodRestaurant": "Makhaayad",
    "foodGrocery": "Dukaanka cuntada",
}


def load(name: str) -> dict:
    return json.loads((L10N / name).read_text(encoding="utf-8"))


def save(name: str, data: dict) -> None:
    (L10N / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    n = sum(1 for k in data if not str(k).startswith("@"))
    print(f"{name}: {n} keys")


def merge(data: dict, locale: str, overrides: dict, with_meta: bool) -> dict:
    data["@@locale"] = locale
    for k, v in NEW_EN.items():
        data[k] = overrides.get(k, v)
        if with_meta and k in PLACEHOLDERS:
            data[f"@{k}"] = {"placeholders": PLACEHOLDERS[k]}
    return data


def main() -> None:
    en = load("app_en.arb")
    for k in list(en):
        if k.startswith("@") and k[1:] in NEW_EN:
            del en[k]
    save("app_en.arb", merge(en, "en", {}, True))

    for name, locale, ov in [
        ("app_am.arb", "am", AM),
        ("app_ti.arb", "ti", TI),
        ("app_om.arb", "om", OM),
        ("app_aa.arb", "aa", AA),
        ("app_so.arb", "so", SO),
    ]:
        data = load(name)
        data = merge(data, locale, ov, False)
        for k in list(data):
            if k.startswith("@") and k != "@@locale":
                del data[k]
        save(name, data)


if __name__ == "__main__":
    main()
