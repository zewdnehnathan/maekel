# -*- coding: utf-8 -*-
"""Create app_ar.arb from English with machine translation + manual fixes."""
from __future__ import annotations

import json
import re
import time
import urllib.request
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
L10N = ROOT / "lib" / "l10n"
CACHE = Path(__file__).resolve().parent / ".l10n_translate_cache.json"

SKIP_KEYS = frozenset(
    {
        "phoneHint",
        "phonePrefix",
        "eventsTicketHint",
        "listSeparator",
        "@@locale",
        "appName",
        "homeAddisOs",
        "rideRouteArrow",
        "gamesSpeed",
    }
)
SKIP_VALUES = frozenset({"9XXXXXXXX", "+251", "MK-…", ",", "Maekel", "Addis OS", "SPD"})
PH_RE = re.compile(r"(\{[^{}]+\})")
BRAND_RE = re.compile(r"\bMaekel\b", re.I)

MANUAL = {
    "@@locale": "ar",
    "appName": "Maekel",
    "currencyEtb": "بر",
    "homeAddisOs": "Addis OS",
    "listSeparator": "،",
    "yes": "نعم",
    "no": "لا",
    "cancel": "إلغاء",
    "save": "حفظ",
    "delete": "حذف",
    "back": "رجوع",
    "clear": "مسح",
    "apply": "تطبيق",
    "continueLabel": "متابعة",
    "verifyLabel": "تحقق",
    "online": "متصل",
    "offline": "غير متصل",
    "approve": "موافقة",
    "reject": "رفض",
    "suspend": "تعليق",
    "edit": "تعديل",
    "qty": "الكمية",
    "moduleRide": "التنقل",
    "moduleRideDesc": "تنقّل في المدينة",
    "moduleMarket": "السوق",
    "moduleMarketDesc": "اشترِ وبِع بالقرب منك",
    "moduleFood": "الطعام",
    "moduleFoodDesc": "اطلب من المطابخ المحلية",
    "moduleEvents": "الفعاليات",
    "moduleEventsDesc": "اكتشف واستضف في أديس أبابا",
    "moduleGames": "الألعاب",
    "moduleGamesDesc": "استراحات لعب سريعة",
    "marketTitle": "السوق",
    "foodTitle": "الطعام",
    "rideTitle": "التنقل",
    "rideConsumer": "اطلب رحلة",
    "rideDriver": "قد مع Maekel",
    "eventsTitle": "الفعاليات",
    "gamesTitle": "الألعاب",
    "placeAddisAbaba": "أديس أبابا",
    "placeBole": "بوليه",
    "placeCmc": "سي إم سي",
    "placeKirkos": "كيركوس",
    "placeYeka": "يكا",
    "placeArada": "أрада",
    "placeKazanchis": "كازانشيس",
    "placePiassa": "بياسا",
    "placeLideta": "ليدتا",
    "placeGulele": "غوليلي",
    "placeNifasSilk": "نفاس سيلك",
    "placeAddisKetema": "أديس كتيما",
    "placeSarbet": "ساربيت",
    "placeMexicoSquare": "ساحة المكسيك",
    "placeBoleAirport": "مطار بوليه",
    "placeBoleAtlas": "بوليه أطلس",
    "placeCmcMichael": "سي إم سي مايكل",
    "tagline": "نظام تشغيل أديس",
    "phoneTitle": "أهلاً بك في Maekel",
    "otpTitle": "أدخل الرمز",
    "language": "اللغة",
    "photos": "صور",
    "gallery": "المعرض",
    "camera": "الكاميرا",
    "cover": "الغلاف",
    "rideRouteArrow": "{from} ← {to}",
    "rideFareStatusCountdown": "{amount} بر · {status} · {countdown}",
    "rideVehicleFare": "{vehicle} · {fare} بر",
    "rideDriverMeta": "{vehicle} · {plate}",
    "marketSubcityCondition": "{subcity} · {condition}",
    "marketPriceSubcity": "{price} · {subcity}",
    "foodOrderLine": "{qty}× {name} — {amount} بر",
    "foodOrderBoardLine": "#{id} · {status} · {total} بر",
    "eventsWhenSubcity": "{when} · {subcity}",
    "eventsVenueCategory": "{venue} · {category}",
    "eventsHostMeta": "{status} · {sold}/{capacity} · {subcity}",
    "foodModifierPrice": "(+{amount} بر)",
    "gamesSpeed": "SPD",
}


def mask_placeholders(text: str) -> tuple[str, dict[str, str]]:
    parts = PH_RE.split(text)
    mapping: dict[str, str] = {}
    out: list[str] = []
    i = 0
    for part in parts:
        if PH_RE.fullmatch(part):
            token = f"__PH{i}__"
            mapping[token] = part
            out.append(token)
            i += 1
        else:
            out.append(part)
    return "".join(out), mapping


def unmask(text: str, mapping: dict[str, str]) -> str:
    for token, ph in mapping.items():
        text = text.replace(token, ph)
    return text


def gtx_translate(text: str, target: str = "ar", retries: int = 5) -> str:
    if not text.strip():
        return text
    # Protect brand name from becoming «مايكل» / Michael.
    brand_token = "__BRAND_MAEKEL__"
    protected = BRAND_RE.sub(brand_token, text)
    masked, mapping = mask_placeholders(protected)
    url = (
        "https://translate.googleapis.com/translate_a/single"
        f"?client=gtx&sl=en&tl={target}&dt=t&q={quote(masked, safe='')}"
    )
    last: Exception | None = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "MaekelL10n/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode())
            translated = "".join(chunk[0] for chunk in data[0] if chunk[0])
            translated = unmask(translated, mapping)
            translated = translated.replace(brand_token, "Maekel")
            translated = translated.replace("مايكل", "Maekel")
            return translated
        except Exception as exc:
            last = exc
            time.sleep(1.2 * (attempt + 1))
    raise last if last else RuntimeError("translate failed")


def load_cache() -> dict:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def usable(en_val: str, tr: str | None) -> bool:
    if not tr or not tr.strip():
        return False
    # Arabic must include Arabic letters (allow mixed brand/ETB).
    if not re.search(r"[\u0600-\u06FF]", tr) and en_val.strip() not in {
        "Maekel",
        "ETB",
        "Addis OS",
        "OK",
        "ID",
        "OTP",
        "COD",
        "GPS",
        "CMC",
    }:
        # Still accept if clearly different non-English short token
        if tr.strip() == en_val.strip():
            return False
        if re.fullmatch(r"[A-Za-z0-9 ._\-+/&]+", tr.strip()) and len(tr) < 40:
            return False
    if len(tr) > max(400, len(en_val) * 6 + 80):
        return False
    return True


def main() -> None:
    en = json.loads((L10N / "app_en.arb").read_text(encoding="utf-8"))
    out: dict = {"@@locale": "ar"}
    for k, v in en.items():
        if k.startswith("@"):
            continue
        out[k] = v

    cache = load_cache()
    loc_cache = cache.setdefault("ar", {})
    keys = [
        k
        for k, v in out.items()
        if not k.startswith("@")
        and k not in SKIP_KEYS
        and isinstance(v, str)
        and (v not in SKIP_VALUES or k in {"currencyEtb"})
    ]

    print(f"==> ar: translating {len(keys)} keys")
    for i, key in enumerate(keys, 1):
        en_val = en[key]
        tr = None
        cached = loc_cache.get(key)
        if usable(en_val, cached):
            tr = cached
        else:
            if key in loc_cache:
                del loc_cache[key]
            try:
                tr = gtx_translate(en_val)
            except Exception as exc:
                print(f"  fail {key}: {exc}")
                continue
            if usable(en_val, tr):
                loc_cache[key] = tr
            else:
                tr = None
        if tr:
            out[key] = tr
        if i % 40 == 0:
            save_cache(cache)
            print(f"  {i}/{len(keys)}")
            time.sleep(0.12)

    for k, v in MANUAL.items():
        if k != "@@locale":
            out[k] = v

    # Force locale code last (never machine-translate this).
    ordered = {"@@locale": "ar"}
    for k, v in out.items():
        if k == "@@locale":
            continue
        if isinstance(v, str):
            v = v.replace("مايكل", "Maekel")
        ordered[k] = v
    out = ordered

    path = L10N / "app_ar.arb"
    path.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    save_cache(cache)
    n = sum(1 for k in out if not k.startswith("@"))
    same = sum(
        1
        for k, v in en.items()
        if not k.startswith("@")
        and isinstance(v, str)
        and out.get(k) == v
        and k not in SKIP_KEYS
        and v not in SKIP_VALUES
    )
    print(f"wrote {path.name}: {n} keys, {same} still English (excl skips)")


if __name__ == "__main__":
    main()
