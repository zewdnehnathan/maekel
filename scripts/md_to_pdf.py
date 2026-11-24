"""Convert docs/architecture.md to a printable PDF via HTML + Chrome."""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "docs" / "architecture.md"
HTML_OUT = ROOT / "docs" / "architecture.html"
PDF_OUT = ROOT / "docs" / "architecture.pdf"

CHROME_CANDIDATES = [
    Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
    Path(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
    Path.home() / r"AppData\Local\Google\Chrome\Application\chrome.exe",
]


def md_to_html(text: str) -> str:
    # Keep mermaid fences as <pre class="mermaid"> for client-side render.
    def mermaid_repl(match: re.Match[str]) -> str:
        body = match.group(1).strip()
        return f'<pre class="mermaid">\n{body}\n</pre>'

    text = re.sub(
        r"```mermaid\s*\n(.*?)```",
        mermaid_repl,
        text,
        flags=re.DOTALL | re.IGNORECASE,
    )

    body = markdown.markdown(
        text,
        extensions=[
            "tables",
            "fenced_code",
            "toc",
            "sane_lists",
            "smarty",
        ],
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Maekel System Architecture</title>
  <style>
    @page {{ size: A4; margin: 18mm 16mm; }}
    body {{
      font-family: "Segoe UI", Calibri, Arial, sans-serif;
      font-size: 11pt;
      line-height: 1.45;
      color: #1a1a1a;
      max-width: 920px;
      margin: 0 auto;
      padding: 24px;
    }}
    h1, h2, h3, h4 {{ color: #0a1018; page-break-after: avoid; }}
    h1 {{ font-size: 22pt; border-bottom: 2px solid #2ef3c5; padding-bottom: 8px; }}
    h2 {{ font-size: 16pt; margin-top: 1.6em; border-bottom: 1px solid #d0d7de; padding-bottom: 4px; }}
    h3 {{ font-size: 13pt; margin-top: 1.2em; }}
    table {{
      border-collapse: collapse;
      width: 100%;
      margin: 12px 0 18px;
      font-size: 10pt;
      page-break-inside: avoid;
    }}
    th, td {{
      border: 1px solid #c9d1d9;
      padding: 6px 8px;
      text-align: left;
      vertical-align: top;
    }}
    th {{ background: #eef6f4; }}
    code {{
      font-family: Consolas, "Courier New", monospace;
      font-size: 0.92em;
      background: #eef2f6;
      color: #111827;
      padding: 1px 4px;
      border-radius: 3px;
    }}
    pre {{
      background: #f3f6f9;
      color: #111827;
      border: 1px solid #c9d1d9;
      padding: 12px;
      border-radius: 8px;
      overflow-x: auto;
      font-size: 9pt;
      line-height: 1.35;
      page-break-inside: avoid;
      white-space: pre-wrap;
      word-break: break-word;
    }}
    pre code {{
      background: transparent;
      color: inherit;
      padding: 0;
    }}
    pre.mermaid {{
      background: #ffffff;
      color: #111827;
      border: 1px solid #d0d7de;
      text-align: center;
    }}
    blockquote {{
      border-left: 4px solid #2ef3c5;
      margin-left: 0;
      padding: 4px 12px;
      color: #444;
      background: #f7fbfa;
    }}
    a {{ color: #0b6e4f; }}
    hr {{ border: none; border-top: 1px solid #d0d7de; margin: 24px 0; }}
  </style>
  <script type="module">
    import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs";
    mermaid.initialize({{ startOnLoad: true, theme: "neutral", securityLevel: "loose" }});
  </script>
</head>
<body>
{body}
</body>
</html>
"""


def find_chrome() -> Path:
    for path in CHROME_CANDIDATES:
        if path.exists():
            return path
    raise FileNotFoundError("Google Chrome not found (needed for PDF print).")


def html_to_pdf(chrome: Path, html: Path, pdf: Path) -> None:
    html_uri = html.resolve().as_uri()
    pdf.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(chrome),
        "--headless=new",
        "--disable-gpu",
        "--no-pdf-header-footer",
        "--virtual-time-budget=15000",
        f"--print-to-pdf={pdf.resolve()}",
        html_uri,
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def main() -> int:
    if not SRC.exists():
        print(f"Missing source: {SRC}", file=sys.stderr)
        return 1

    html = md_to_html(SRC.read_text(encoding="utf-8"))
    HTML_OUT.write_text(html, encoding="utf-8")
    print(f"Wrote {HTML_OUT}")

    chrome = find_chrome()
    html_to_pdf(chrome, HTML_OUT, PDF_OUT)
    print(f"Wrote {PDF_OUT} ({PDF_OUT.stat().st_size / 1024:.1f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
