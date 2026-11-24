# -*- coding: utf-8 -*-
"""Create app_sw.arb / app_zh.arb from English and auto-translate gaps."""
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

SKIP_KEYS = frozenset({"phoneHint", "phonePrefix", "eventsTicketHint", "listSeparator"})
SKIP_VALUES = frozenset({"9XXXXXXXX", "+251", "MK-…", ","})
PH_RE = re.compile(r"(\{[^{}]+\})")

# Hand fixes after MT
MANUAL = {
    "sw": {
        "appName": "Maekel",
        "currencyEtb": "ETB",
        "homeAddisOs": "Addis OS",
        "placeBole": "Bole",
        "placeCmc": "CMC",
        "listSeparator": ",",
    },
    "zh": {
        "appName": "Maekel",
        "currencyEtb": "ETB",
        "homeAddisOs": "Addis OS",
        "listSeparator": "、",
        "yes": "是",
        "no": "否",
        "cancel": "取消",
        "save": "保存",
        "delete": "删除",
        "back": "返回",
        "clear": "清除",
        "apply": "应用",
        "online": "在线",
        "offline": "离线",
        "approve": "批准",
        "reject": "拒绝",
        "suspend": "暂停",
        "qty": "数量",
        "marketTitle": "市场",
        "foodTitle": "外卖",
        "rideTitle": "出行",
        "eventsTitle": "活动",
        "gamesTitle": "游戏",
        "placeAddisAbaba": "亚的斯亚贝巴",
        "placeBole": "博莱",
        "placeCmc": "CMC",
        "placeKirkos": "基尔科斯",
        "placeYeka": "耶卡",
        "placeArada": "阿拉达",
        "placeKazanchis": "卡赞奇斯",
        "placePiassa": "皮亚萨",
        "placeLideta": "利德塔",
        "placeGulele": "古莱莱",
        "placeNifasSilk": "尼法斯西尔克",
        "placeAddisKetema": "亚的斯克特马",
        "placeSarbet": "萨贝特",
        "placeMexicoSquare": "墨西哥广场",
        "placeBoleAirport": "博莱机场",
        "placeBoleAtlas": "博莱阿特拉斯",
        "placeCmcMichael": "CMC 迈克尔",
    },
}

GTX = {"sw": "sw", "zh": "zh-CN"}


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


def gtx_translate(text: str, target: str, retries: int = 5) -> str:
    if not text.strip():
        return text
    masked, mapping = mask_placeholders(text)
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
            return unmask(translated, mapping)
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
    if not tr or tr.strip() == en_val.strip():
        return False
    if len(tr) > max(400, len(en_val) * 6 + 80):
        return False
    return True


def build_locale(locale: str) -> None:
    en = json.loads((L10N / "app_en.arb").read_text(encoding="utf-8"))
    out = {"@@locale": locale}
    for k, v in en.items():
        if k.startswith("@"):
            continue
        out[k] = v

    cache = load_cache()
    loc_cache = cache.setdefault(locale, {})
    tl = GTX[locale]
    keys = [
        k
        for k, v in out.items()
        if k not in SKIP_KEYS
        and isinstance(v, str)
        and (v not in SKIP_VALUES or k in {"appName", "currencyEtb"})
    ]

    print(f"==> {locale}: translating {len(keys)} keys")
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
                tr = gtx_translate(en_val, tl)
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
            time.sleep(0.15)

    # Manual overrides last
    for k, v in MANUAL.get(locale, {}).items():
        out[k] = v

    path = L10N / f"app_{locale}.arb"
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


def main() -> None:
    for loc in ("sw", "zh"):
        build_locale(loc)


if __name__ == "__main__":
    main()
