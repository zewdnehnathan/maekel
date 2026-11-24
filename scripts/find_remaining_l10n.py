# -*- coding: utf-8 -*-
from __future__ import annotations

import re
from pathlib import Path

root = Path("lib/features")

for mod in ["ride", "market", "food", "events", "games", "admin"]:
    hits: list[tuple[str, str, str]] = []
    for path in sorted((root / mod).rglob("*.dart")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in re.finditer(r"'([^']{4,})'", text):
            s = match.group(1)
            line_start = text.rfind("\n", 0, match.start()) + 1
            line_end = text.find("\n", match.end())
            if line_end < 0:
                line_end = len(text)
            line = text[line_start:line_end]
            if "AppLocalizations" in line or "import " in line or "package:" in line:
                continue
            if s.startswith(("assets/", "http", "lib/", ".", "/")):
                continue
            if not re.search(r"[A-Za-z]{3,}", s):
                continue
            kind = "dynamic" if ("$" in s or "{" in s) else "static"
            if kind == "static" and " " not in s and not s[:1].isupper():
                continue
            # skip pure identifiers / codes
            if re.fullmatch(r"[a-z0-9_\-]+", s):
                continue
            hits.append((str(path.relative_to(root)), kind, s[:140]))
    print(f"=== {mod.upper()} ({len(hits)}) ===")
    for path, kind, s in hits[:50]:
        print(f"  [{kind}] {path}: {s}")
    if len(hits) > 50:
        print(f"  ... +{len(hits) - 50} more")
    print()
