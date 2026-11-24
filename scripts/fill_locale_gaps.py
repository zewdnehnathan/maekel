# -*- coding: utf-8 -*-
"""Fill English-identical keys in ti/om/aa/so ARB files."""
from __future__ import annotations

import importlib.util
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
    }
)

# Keep brand / tickers when identical in English (optional skips).
SKIP_IDENTICAL_VALUES = frozenset(
    {
        "9XXXXXXXX",
        "+251",
        "MK-…",
        ",",
    }
)

# Keys that must be translated even when the English value is a “universal” token.
FORCE_TRANSLATE_KEYS = frozenset({"appName", "currencyEtb"})

# Hand-tuned fixes for keys where MT/cache stayed English or garbled.
MANUAL_TAIL: dict[str, dict[str, str]] = {
    "OM": {
        "currencyEtb": "Birrii",
        "qty": "Baay'ina",
        "rideOpsTitle": "Bulchiinsa imalaa",
        "marketMaximum": "Ol'aanaa",
        "foodMenu": "Menuu",
        "eventsCheckIn": "Galmaa'i",
        "foodOrderLine": "{qty}× {name} — {amount} Birrii",
        "foodOrderBoardLine": "{merchant} → {subcity} · {amount} Birrii",
        "gamesKm": "Kiiloomeetira",
        "marketSpecGeneric": "Ibsa",
        "marketSpecHintGeneric": "Ibsa ijoo",
        "marketUpdates": "Odeeffannoo",
        "marketOpsTitle": "Bulchiinsa",
        "foodCheckout": "Kaffaltii",
        "eventsMonthJan": "Ama",
        "eventsMonthMar": "Bito",
        "eventsMonthJun": "Wax",
        "eventsMonthJul": "Ado",
        "eventsMonthSep": "Ful",
        "eventsMonthNov": "Sada",
        "homeAddisOs": "Sirna Addis",
        "placeCmc": "Si'emii-Sii'emii",
        "placeGulele": "Gulale",
        "placeKazanchis": "Kaazaanchis",
        "placeKirkos": "Qirqos",
        "placeSarbet": "Sarbeet",
        "rideFareEtb": "{amount} Birrii",
        "marketPriceEtb": "{amount} Birrii",
        "foodPriceEtb": "{amount} Birrii",
        "foodPriceEtbCod": "{amount} Birrii COD",
        "marketLocationAddis": "{subcity}, Finfinnee",
    },
    "AA": {
        "currencyEtb": "Bir",
        "rideFareEtb": "{amount} Bir",
        "marketPriceEtb": "{amount} Bir",
        "gamesKm": "Kiloomeetira",
        "gamesSpeed": "Saffisa",
        "marketOpsTitle": "Bulchita",
        "homeAddisOs": "Sirna Addis",
        "foodPriceEtb": "{amount} Bir",
        "foodPriceEtbCod": "{amount} Bir COD",
        "marketLocationAddis": "{subcity}, Addis Abaaba",
        "placeArada": "Araada",
        "placeBole": "Bolee",
        "placeBoleAtlas": "Bole Atlaas",
        "placeCmc": "CMC (Si'emii)",
        "placeGulele": "Guleelee",
        "placeLideta": "Lideeta",
        "placeSarbet": "Sarbeet",
        "placeYeka": "Yekka",
    },
    "SO": {
        "currencyEtb": "Birr",
        "otpHint": "Koodh 6-god ah",
        "tetris": "Tiriis",
        "qty": "Tirada",
        "gallery": "Sawirro",
        "rideFareEtb": "{amount} Birr",
        "foodMenu": "Liiska",
        "rideFareStatusCountdown": "{amount} Birr · {status} · {countdown}",
        "rideVehicleFare": "{amount} Birr · {vehicle}",
        "marketPriceEtb": "{amount} Birr",
        "marketPriceSubcity": "{amount} Birr · {subcity}",
        "foodOrderBoardLine": "{merchant} → {subcity} · {amount} Birr",
        "eventsTicketQtyStatus": "Tirada {qty} · {status}",
        "gamesCombo": "Isku-darka",
        "gamesKm": "Kilomitir",
        "marketPriceRangeMinMax": "Birr {min}–{max}",
        "marketPriceRangeMinPlus": "Birr {min}+",
        "marketCatFashion": "Moodada",
        "marketSpecGeneric": "Sharaxaad",
        "marketOpsTitle": "Hawl-gelinta",
        "eventsMonthJan": "Jana",
        "eventsMonthFeb": "Fee",
        "eventsMonthMar": "Maar",
        "eventsMonthMay": "Maajo",
        "eventsMonthJun": "Juun",
        "eventsMonthJul": "Luul",
        "eventsMonthSep": "Sebt",
        "eventsMonthOct": "Okt",
        "eventsMonthNov": "Nof",
        "eventsMonthDec": "Dib",
        "homeAddisOs": "Nidaamka Addis",
        "authSignalEthiopia": "Signal · Itoobiya",
        "placeAddisAbaba": "Magaalada Addis Ababa",
        "placeAddisKetema": "Ketema Addis",
        "placeArada": "Araada",
        "placeBole": "Boole",
        "placeBoleAtlas": "Boole Atlas",
        "placeCmc": "Ci-Em-Ci",
        "placeCmcMichael": "Ci-Em-Ci Michael",
        "placeGulele": "Guleele",
        "placeKazanchis": "Kaazaanchis",
        "placeKirkos": "Qirkos",
        "placeLideta": "Lideeta",
        "placeNifasSilk": "Nifaas Silk",
        "placePiassa": "Biyaasa",
        "placeSarbet": "Sarbeet",
        "placeYeka": "Yekka",
        "foodModifierPrice": "(+{amount} Birr)",
        "foodPriceEtb": "{amount} Birr",
        "marketLocationAddis": "{subcity}, Magaalada Addis Ababa",
    },
    "TI": {
        "rideMinFareEtb": "ዝቅተኛ ክፍሊት ብር",
        "eventsTicketQtyStatus": "ብዛት {qty} · {status}",
    },
}


def cache_translation_usable(en_val: str, tr: str | None) -> bool:
    if not tr or tr.strip() == en_val.strip():
        return False
    if len(tr) > max(400, len(en_val) * 5 + 80):
        return False
    return True

PH_RE = re.compile(r"(\{[^{}]+\})")

SCRIPT_MODULES = (
    "fill_am_gaps",
    "gen_remaining_l10n",
    "gen_full_ui_l10n",
    "gen_dynamic_l10n",
    "gen_module_l10n",
    "gen_places_and_gaps_l10n",
)


def load_module(name: str):
    path = ROOT / "scripts" / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def collect_script_overrides() -> dict[str, dict[str, str]]:
    merged = {loc: dict(MANUAL_TAIL.get(loc, {})) for loc in ("TI", "OM", "AA", "SO")}
    for modname in SCRIPT_MODULES:
        mod = load_module(modname)
        for loc in merged:
            d = getattr(mod, loc, None)
            if not isinstance(d, dict):
                continue
            # Several TI dicts spread Amharic; only apply Tigrinya deltas.
            if loc == "TI" and modname in (
                "fill_am_gaps",
                "gen_dynamic_l10n",
            ):
                continue
            if loc == "TI" and modname == "gen_module_l10n":
                am = getattr(mod, "AM", {})
                for k, v in d.items():
                    if am.get(k) != v:
                        merged[loc][k] = v
                continue
            merged[loc].update(d)
        if modname == "gen_places_and_gaps_l10n" and hasattr(mod, "PACK"):
            idx = {"TI": 2, "OM": 3, "AA": 4, "SO": 5}
            for key, vals in mod.PACK.items():
                for loc, i in idx.items():
                    merged[loc][key] = vals[i]
    for loc in merged:
        merged[loc].update(MANUAL_TAIL.get(loc, {}))
    return merged


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


def gtx_translate(text: str, target: str, retries: int = 4) -> str:
    if not text.strip():
        return text
    masked, mapping = mask_placeholders(text)
    q = quote(masked, safe="")
    url = (
        f"https://translate.googleapis.com/translate_a/single"
        f"?client=gtx&sl=en&tl={target}&dt=t&q={q}"
    )
    last_err: Exception | None = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "MaekelL10n/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode())
            translated = "".join(chunk[0] for chunk in data[0] if chunk[0])
            return unmask(translated, mapping)
        except Exception as exc:
            last_err = exc
            time.sleep(1.5 * (attempt + 1))
    raise last_err if last_err else RuntimeError("translate failed")


def load_cache() -> dict[str, dict[str, str]]:
    if CACHE.exists():
        return json.loads(CACHE.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict[str, dict[str, str]]) -> None:
    CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def load_arb(name: str) -> dict:
    return json.loads((L10N / name).read_text(encoding="utf-8"))


def save_arb(name: str, data: dict) -> None:
    (L10N / name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def message_keys(data: dict) -> dict[str, str]:
    return {k: v for k, v in data.items() if not k.startswith("@") and isinstance(v, str)}


def apply_overrides(
    en: dict[str, str],
    arb: dict,
    overrides: dict[str, str],
    *,
    skip_keys: frozenset[str],
) -> int:
    n = 0
    for key, en_val in en.items():
        if key in skip_keys:
            continue
        if arb.get(key) != en_val:
            continue
        tr = overrides.get(key)
        if tr and tr != en_val:
            arb[key] = tr
            n += 1
    return n


def auto_translate_gaps(
    en: dict[str, str],
    arb: dict,
    locale_code: str,
    cache: dict[str, dict[str, str]],
) -> int:
    loc_cache = cache.setdefault(locale_code, {})
    n = 0
    gaps = [
        k
        for k, v in en.items()
        if k not in SKIP_KEYS
        and arb.get(k) == v
        and (v not in SKIP_IDENTICAL_VALUES or k in FORCE_TRANSLATE_KEYS)
    ]
    for i, key in enumerate(gaps, 1):
        en_val = en[key]
        tr: str | None = None
        cached = loc_cache.get(key)
        if cache_translation_usable(en_val, cached):
            tr = cached
        else:
            try:
                tr = gtx_translate(en_val, locale_code)
            except Exception as exc:
                print(f"  [{locale_code}] {key}: translate failed ({exc})")
                continue
            if cache_translation_usable(en_val, tr):
                loc_cache[key] = tr
            elif key in loc_cache:
                del loc_cache[key]
            if i % 20 == 0:
                save_cache(cache)
            time.sleep(0.15)
        if tr and tr != en_val:
            arb[key] = tr
            n += 1
    save_cache(cache)
    return n


def count_identical(en: dict[str, str], arb: dict) -> int:
    return sum(1 for k, v in en.items() if arb.get(k) == v)


def apply_manual(en: dict[str, str], arb: dict, code: str) -> int:
    manual = MANUAL_TAIL.get(code.upper(), {})
    n = 0
    for key, tr in manual.items():
        if key in en and arb.get(key) == en[key] and tr != en[key]:
            arb[key] = tr
            n += 1
    return n


def process_locale(
    filename: str,
    code: str,
    overrides: dict[str, str],
    en: dict[str, str],
    cache: dict[str, dict[str, str]],
) -> None:
    arb = load_arb(filename)
    before = count_identical(en, arb)
    n0 = apply_manual(en, arb, code)
    n1 = apply_overrides(en, arb, overrides, skip_keys=SKIP_KEYS)
    n2 = auto_translate_gaps(en, arb, code, cache)
    for k in list(arb):
        if k.startswith("@") and k != "@@locale":
            del arb[k]
    save_arb(filename, arb)
    after = count_identical(en, arb)
    print(
        f"{filename}: manual={n0} overrides={n1} auto={n2} identical {before} -> {after}",
        flush=True,
    )


def main() -> None:
    import sys

    only = sys.argv[1:] if len(sys.argv) > 1 else None
    en_data = load_arb("app_en.arb")
    en = message_keys(en_data)
    overrides_by_loc = collect_script_overrides()
    cache = load_cache()

    locales = [
        ("app_ti.arb", "ti", overrides_by_loc["TI"]),
        ("app_om.arb", "om", overrides_by_loc["OM"]),
        ("app_aa.arb", "aa", overrides_by_loc["AA"]),
        ("app_so.arb", "so", overrides_by_loc["SO"]),
    ]

    for filename, code, overrides in locales:
        if only and code not in only:
            continue
        process_locale(filename, code, overrides, en, cache)

    print("\nFinal identical counts (allowed skips: phoneHint/phonePrefix/listSeparator/eventsTicketHint):", flush=True)
    for filename, code, _ in locales:
        arb = load_arb(filename)
        same = [k for k, v in en.items() if arb.get(k) == v]
        print(f"  {code}: {len(same)} {same[:12]}{'...' if len(same) > 12 else ''}")


if __name__ == "__main__":
    main()