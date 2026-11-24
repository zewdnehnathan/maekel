# -*- coding: utf-8 -*-
"""Place names + remaining gap UI strings for all locales."""
from __future__ import annotations

import json
from pathlib import Path

L10N = Path("lib/l10n")

# (en, am, ti, om, aa, so)
PACK = {
    "listSeparator": (",", "፣", "፣", ",", ",", ","),
    "placeAddisAbaba": (
        "Addis Ababa",
        "አዲስ አበባ",
        "ኣዲስ ኣበባ",
        "Finfinnee",
        "Addis Ababa",
        "Addis Ababa",
    ),
    "placeAddisKetema": (
        "Addis Ketema",
        "አዲስ ከተማ",
        "ኣዲስ ከተማ",
        "Addis Ketema",
        "Addis Ketema",
        "Addis Ketema",
    ),
    "placeArada": ("Arada", "አራዳ", "ኣራዳ", "Arada", "Arada", "Arada"),
    "placeBole": ("Bole", "ቦሌ", "ቦሌ", "Bole", "Bole", "Bole"),
    "placeBoleAirport": (
        "Bole Airport",
        "የቦሌ አውሮፕላን ማረፊያ",
        "ናይ ቦሌ ኣውሮፕላን ማረፊያ",
        "Airpoortii Bole",
        "Bole Airport",
        "Garoonka Bole",
    ),
    "placeBoleAtlas": (
        "Bole Atlas",
        "ቦሌ አትላስ",
        "ቦሌ ኣትላስ",
        "Bole Atlas",
        "Bole Atlas",
        "Bole Atlas",
    ),
    "placeCmc": ("CMC", "ሲኤምሲ", "ሲኤምሲ", "CMC", "CMC", "CMC"),
    "placeCmcMichael": (
        "CMC Michael",
        "ሲኤምሲ ሚካኤል",
        "ሲኤምሲ ሚካኤል",
        "CMC Michael",
        "CMC Michael",
        "CMC Michael",
    ),
    "placeGulele": ("Gulele", "ጉለሌ", "ጉለሌ", "Gulele", "Gulele", "Gulele"),
    "placeKazanchis": (
        "Kazanchis",
        "ካዛንቺስ",
        "ካዛንቺስ",
        "Kazanchis",
        "Kazanchis",
        "Kazanchis",
    ),
    "placeKirkos": ("Kirkos", "ቂርቆስ", "ቂርቆስ", "Kirkos", "Kirkos", "Kirkos"),
    "placeLideta": ("Lideta", "ልደታ", "ልደታ", "Lideta", "Lideta", "Lideta"),
    "placeMexicoSquare": (
        "Mexico Square",
        "ሜክሲኮ አደባባይ",
        "ሜክሲኮ ኣደባባይ",
        "Mexico Square",
        "Mexico Square",
        "Mexico Square",
    ),
    "placeNifasSilk": (
        "Nifas Silk",
        "ንፋስ ስልክ",
        "ንፋስ ስልክ",
        "Nifas Silk",
        "Nifas Silk",
        "Nifas Silk",
    ),
    "placePiassa": ("Piassa", "ፒያሳ", "ፒያሳ", "Piassa", "Piassa", "Piassa"),
    "placeSarbet": ("Sarbet", "ሳር ቤት", "ሳር ቤት", "Sarbet", "Sarbet", "Sarbet"),
    "placeYeka": ("Yeka", "የካ", "የካ", "Yeka", "Yeka", "Yeka"),
    # search / examples
    "rideSearchHint": (
        "Bole, Piassa, Airport…",
        "ቦሌ፣ ፒያሳ፣ አውሮፕላን ማረፊያ…",
        "ቦሌ፣ ፒያሳ፣ ኣውሮፕላን ማረፊያ…",
        "Bole, Piassa, Airpoortii…",
        "Bole, Piassa, Airport…",
        "Bole, Piassa, Garoonka…",
    ),
    "gamesUsernameHintExample": (
        "e.g. BoleAce",
        "ለምሳሌ BoleAce",
        "ኣብነት BoleAce",
        "fkn. BoleAce",
        "e.g. BoleAce",
        "tusaale BoleAce",
    ),
    # remaining UI gaps
    "locationTurnOn": (
        "Turn on location services to use pickup.",
        "መነሻ ለመጠቀም አካባቢን ያብሩ።",
        "ንመበገሲ ንምጥቃም ኣካባቢ ኣብርህ።",
        "Pickup fayyadamuuf tajaajila bakka bani.",
        "Turn on location services to use pickup.",
        "Fur adeegyada goobta si aad u isticmaasho qaadista.",
    ),
    "locationDenied": (
        "Location permission denied.",
        "የአካባቢ ፍቃድ ተከልክሏል።",
        "ፍቓድ ኣካባቢ ተኸልኪሉ።",
        "Hayyama bakka didameera.",
        "Location permission denied.",
        "Ogolaanshaha goobta waa la diiday.",
    ),
    "locationBlocked": (
        "Location permission is blocked. Enable it in system settings.",
        "የአካባቢ ፍቃድ ታግዷል። ከስርዓት ቅንብሮች ያንቁት።",
        "ፍቓድ ኣካባቢ ተኣጊዱ። ካብ ስርዓት ቅንብሮች ኣብርህ።",
        "Hayyama bakka cufameera. Qindaa'ina sirna irraa bani.",
        "Location permission is blocked. Enable it in system settings.",
        "Ogolaanshaha goobta waa xiran. Ka fur settings-ka.",
    ),
    "locationNoPickupPlaces": (
        "No pickup places available.",
        "ምንም የመነሻ ቦታ የለም።",
        "ዝኾነ ቦታ መበገሲ የለን።",
        "Bakka pickup hin jiru.",
        "No pickup places available.",
        "Meelaha qaadista ma jiraan.",
    ),
    "authStartAgain": (
        "Start again with your phone number.",
        "በስልክ ቁጥርዎ እንደገና ይጀምሩ።",
        "ብቁጽሪ ስልክኻ ዳግም ጀምር።",
        "Lakkoofsa bilbilaa keetiin irra deebi'ii eegali.",
        "Start again with your phone number.",
        "Ku bilow mar kale lambarkaaga.",
    ),
    "authApiUnreachable": (
        "Could not reach Maekel API at {url}",
        "የመአከል API በ{url} ማግኘት አልተቻለም",
        "ናይ Maekel API ኣብ {url} ምርካብ ኣይተኻእለን",
        "API Maekel {url} irratti argachuu hin dandeenye",
        "Could not reach Maekel API at {url}",
        "Maheli karo Maekel API ee {url}",
    ),
    "authOtpGateway": (
        "Could not verify OTP. Is the gateway running?",
        "OTP ማረጋገጥ አልተቻለም። ጌትዌይ እየሰራ ነው?",
        "OTP ምርግጋጽ ኣይተኻእለን። ጌትዌይ ይሰርሕ ድዩ?",
        "OTP mirkaneessuu hin dandeenye. Gateway ni hojjataa?",
        "Could not verify OTP. Is the gateway running?",
        "Lama xaqiijin karo OTP. Gateway ma shaqaynayaa?",
    ),
    "eventsCategoriesNotLoaded": (
        "Categories/areas not loaded yet.",
        "ምድቦች/አካባቢዎች ገና አልተጫኑም።",
        "ምድባት/ቦታታት ገና ኣይተጻዕኑን።",
        "Ramaddiiwwan/naannoon amma hin fe'amne.",
        "Categories/areas not loaded yet.",
        "Qaybaha/meelaha weli uma soo dejin.",
    ),
    "eventsTitleVenueRequired": (
        "Title and venue are required.",
        "ርዕስ እና ቦታ ያስፈልጋሉ።",
        "ኣርእስቲን ቦታን የድለዩ።",
        "Mata duree fi bakki ni barbaachisu.",
        "Title and venue are required.",
        "Cinwaanka iyo goobta ayaa loo baahan yahay.",
    ),
    "eventsCapacityMin": (
        "Capacity must be at least 1.",
        "አቅም ቢያንስ 1 መሆን አለበት።",
        "ኣቅሚ እንተወሓደ 1 ክኸውን ኣለዎ።",
        "Dandeettiin yoo xiqqaate 1 ta'uu qaba.",
        "Capacity must be at least 1.",
        "Awooddu waa inay ugu yaraan tahay 1.",
    ),
    "eventsRejectDefault": (
        "Does not meet guidelines",
        "መመሪያዎችን አያሟላም",
        "መምርሒታት ኣይምልእን",
        "Qajeelfama hin guutin",
        "Does not meet guidelines",
        "Ma buuxinayo tilmaamaha",
    ),
    "foodSavedLabel": ("Saved", "ተቀምጧል", "ተቐሚጡ", "Olkaa'ame", "Saved", "La keydiyay"),
    "foodEtaFee": (
        "{minutes} min · {fee} ETB fee",
        "{minutes} ደቂቃ · {fee} ብር ክፍያ",
        "{minutes} ደቂቓ · {fee} ብር ክፍሊት",
        "{minutes} daqiiqaa · kaffaltii {fee} ETB",
        "{minutes} min · {fee} ETB fee",
        "{minutes} daq · {fee} ETB kharash",
    ),
    "foodCheckoutSummary": (
        "Subtotal {subtotal} ETB + delivery {fee} ETB = {total} ETB",
        "ንዑስ ድምር {subtotal} ብር + መላኪያ {fee} ብር = {total} ብር",
        "ንኡስ ድምር {subtotal} ብር + ምብጻሕ {fee} ብር = {total} ብር",
        "Subtotal {subtotal} ETB + geessuu {fee} ETB = {total} ETB",
        "Subtotal {subtotal} ETB + delivery {fee} ETB = {total} ETB",
        "Subtotal {subtotal} ETB + delivery {fee} ETB = {total} ETB",
    ),
    "foodModifierPrice": (
        "(+{amount} ETB)",
        "(+{amount} ብር)",
        "(+{amount} ብር)",
        "(+{amount} ETB)",
        "(+{amount} ETB)",
        "(+{amount} ETB)",
    ),
    "foodOptionsCount": (
        "{count} option(s)",
        "{count} አማራጭ(ዎች)",
        "{count} ኣማራጺ(ታት)",
        "{count} filannoo",
        "{count} option(s)",
        "{count} doorasho",
    ),
    "foodPriceEtb": (
        "{amount} ETB",
        "{amount} ብር",
        "{amount} ብር",
        "{amount} ETB",
        "{amount} ETB",
        "{amount} ETB",
    ),
    "foodPriceEtbCod": (
        "{amount} ETB COD",
        "{amount} ብር ኮድ",
        "{amount} ብር COD",
        "{amount} ETB COD",
        "{amount} ETB COD",
        "{amount} ETB COD",
    ),
    "rideVehicleEconomy": (
        "Economy",
        "ኢኮኖሚ",
        "ኢኮኖሚ",
        "Economy",
        "Economy",
        "Economy",
    ),
    "requestFailed": (
        "Request failed ({code})",
        "ጥያቄ አልተሳካም ({code})",
        "ሕቶ ኣይተዓወተን ({code})",
        "Gaaffiin kufe ({code})",
        "Request failed ({code})",
        "Codsiga wuu fashilmay ({code})",
    ),
    "sellerYou": ("You", "እርስዎ", "ንስኻ", "Ati", "You", "Adiga"),
    "marketLocationAddis": (
        "{subcity}, Addis Ababa",
        "{subcity}፣ አዲስ አበባ",
        "{subcity}፣ ኣዲስ ኣበባ",
        "{subcity}, Finfinnee",
        "{subcity}, Addis Ababa",
        "{subcity}, Addis Ababa",
    ),
}

PLACEHOLDERS = {
    "authApiUnreachable": {"url": {"type": "String"}},
    "foodEtaFee": {"minutes": {"type": "Object"}, "fee": {"type": "Object"}},
    "foodCheckoutSummary": {
        "subtotal": {"type": "Object"},
        "fee": {"type": "Object"},
        "total": {"type": "Object"},
    },
    "foodModifierPrice": {"amount": {"type": "Object"}},
    "foodOptionsCount": {"count": {"type": "int"}},
    "foodPriceEtb": {"amount": {"type": "Object"}},
    "foodPriceEtbCod": {"amount": {"type": "Object"}},
    "requestFailed": {"code": {"type": "Object"}},
    "marketLocationAddis": {"subcity": {"type": "String"}},
}

LOC_IDX = {"en": 0, "am": 1, "ti": 2, "om": 3, "aa": 4, "so": 5}


def main() -> None:
    for loc, i in LOC_IDX.items():
        path = L10N / f"app_{loc}.arb"
        data = json.loads(path.read_text(encoding="utf-8"))
        data["@@locale"] = loc
        for key, vals in PACK.items():
            data[key] = vals[i]
            if loc == "en" and key in PLACEHOLDERS:
                data[f"@{key}"] = {"placeholders": PLACEHOLDERS[key]}
            elif loc != "en" and f"@{key}" in data:
                del data[f"@{key}"]
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        n = sum(1 for k in data if not str(k).startswith("@"))
        print(f"{path.name}: {n} keys")


if __name__ == "__main__":
    main()
