"""Convert docs/architecture.md to a printable PDF.

Mermaid diagrams are pre-rendered to SVG with @mermaid-js/mermaid-cli so Chrome
print never produces blank diagram boxes (CDN/async race).
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
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

MERMAID_BLOCK = re.compile(
    r"```mermaid\s*\n(.*?)```",
    flags=re.DOTALL | re.IGNORECASE,
)


def find_chrome() -> Path:
    for path in CHROME_CANDIDATES:
        if path.exists():
            return path
    raise FileNotFoundError("Google Chrome not found (needed for PDF print).")


def render_mermaid_svgs(md_text: str, work: Path) -> tuple[str, list[Path]]:
    """Replace ```mermaid fences with inline SVG. Returns (md, svg_paths)."""
    svgs: list[Path] = []
    counter = 0

    def repl(match: re.Match[str]) -> str:
        nonlocal counter
        counter += 1
        body = match.group(1).strip() + "\n"
        mmd = work / f"diagram_{counter:02d}.mmd"
        svg = work / f"diagram_{counter:02d}.svg"
        mmd.write_text(body, encoding="utf-8")
        npx = shutil.which("npx") or shutil.which("npx.cmd")
        if not npx:
            raise FileNotFoundError("npx not found on PATH")
        cmd = [
            npx,
            "--yes",
            "@mermaid-js/mermaid-cli@11",
            "-i",
            str(mmd),
            "-o",
            str(svg),
            "-b",
            "transparent",
            "-t",
            "neutral",
            "--quiet",
        ]
        print(f"  rendering mermaid #{counter} …")
        subprocess.run(cmd, check=True, cwd=str(ROOT), shell=False)
        if not svg.exists():
            raise RuntimeError(f"mermaid-cli did not write {svg}")
        svgs.append(svg)
        svg_text = svg.read_text(encoding="utf-8")
        # Strip XML declaration for cleaner HTML embed.
        svg_text = re.sub(r"<\?xml[^>]*\?>", "", svg_text).strip()
        return f'\n\n<div class="diagram">\n{svg_text}\n</div>\n\n'

    return MERMAID_BLOCK.sub(repl, md_text), svgs


def md_to_html(text: str) -> str:
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
    @page {{ size: A4; margin: 16mm 14mm; }}
    body {{
      font-family: "Segoe UI", Calibri, Arial, sans-serif;
      font-size: 10.5pt;
      line-height: 1.45;
      color: #1a1a1a;
      max-width: 960px;
      margin: 0 auto;
      padding: 20px;
    }}
    h1, h2, h3, h4 {{ color: #0a1018; page-break-after: avoid; }}
    h1 {{ font-size: 20pt; border-bottom: 2px solid #2ef3c5; padding-bottom: 8px; }}
    h2 {{ font-size: 15pt; margin-top: 1.5em; border-bottom: 1px solid #d0d7de; padding-bottom: 4px; }}
    h3 {{ font-size: 12.5pt; margin-top: 1.1em; }}
    table {{
      border-collapse: collapse;
      width: 100%;
      margin: 10px 0 16px;
      font-size: 9.5pt;
      page-break-inside: avoid;
    }}
    th, td {{
      border: 1px solid #c9d1d9;
      padding: 5px 7px;
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
      padding: 10px;
      border-radius: 8px;
      overflow-x: auto;
      font-size: 8.5pt;
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
    .diagram {{
      margin: 14px 0 18px;
      padding: 12px;
      background: #ffffff;
      border: 1px solid #d0d7de;
      border-radius: 10px;
      text-align: center;
      page-break-inside: avoid;
      overflow: hidden;
    }}
    .diagram svg {{
      max-width: 100%;
      height: auto;
    }}
    blockquote {{
      border-left: 4px solid #2ef3c5;
      margin-left: 0;
      padding: 4px 12px;
      color: #444;
      background: #f7fbfa;
    }}
    a {{ color: #0b6e4f; }}
    hr {{ border: none; border-top: 1px solid #d0d7de; margin: 22px 0; }}
  </style>
</head>
<body>
{body}
</body>
</html>
"""


def html_to_pdf(chrome: Path, html: Path, pdf: Path) -> None:
    html_uri = html.resolve().as_uri()
    pdf.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(chrome),
        "--headless=new",
        "--disable-gpu",
        "--no-pdf-header-footer",
        "--virtual-time-budget=5000",
        f"--print-to-pdf={pdf.resolve()}",
        html_uri,
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def main() -> int:
    if not SRC.exists():
        print(f"Missing source: {SRC}", file=sys.stderr)
        return 1

    if not shutil.which("npx"):
        print("npx not found — install Node.js to render Mermaid diagrams.", file=sys.stderr)
        return 1

    raw = SRC.read_text(encoding="utf-8")
    with tempfile.TemporaryDirectory(prefix="maekel-arch-") as tmp:
        work = Path(tmp)
        print("Pre-rendering Mermaid diagrams to SVG…")
        md_with_svg, svgs = render_mermaid_svgs(raw, work)
        print(f"Rendered {len(svgs)} diagrams.")
        html = md_to_html(md_with_svg)
        HTML_OUT.write_text(html, encoding="utf-8")
        print(f"Wrote {HTML_OUT}")

    chrome = find_chrome()
    html_to_pdf(chrome, HTML_OUT, PDF_OUT)
    print(f"Wrote {PDF_OUT} ({PDF_OUT.stat().st_size / 1024:.1f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
