#!/usr/bin/env python3
"""Render any IGWelfare GitHub-Flavored Markdown file to clean sans-serif, responsive HTML."""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

CLEAN_SANS_CSS = """<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  :root {
    --sans: -apple-system, BlinkMacSystemFont, "Inter", "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    --mono: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
  }
  html, body {
    font-family: var(--sans);
    font-size: 16.5px;
    line-height: 1.6;
    color: #1a202c;
    background: #ffffff;
    margin: 0;
    padding: 0;
    -webkit-font-smoothing: antialiased;
  }
  body {
    max-width: 960px;
    margin: 0 auto;
    padding: 2.5rem 1.75rem 4rem;
  }
  h1, h2, h3, h4, h5, h6, p, li, td, th, blockquote {
    font-family: var(--sans);
  }
  h1, h2, h3, h4 {
    color: #0f172a;
    line-height: 1.25;
    margin-top: 2rem;
    margin-bottom: 0.75rem;
  }
  h1 { font-size: 2.05rem; border-bottom: 1px solid #e2e8f0; padding-bottom: 0.5rem; margin-top: 0; }
  h2 { font-size: 1.48rem; border-bottom: 1px solid #edf2f7; padding-bottom: 0.35rem; }
  h3 { font-size: 1.18rem; }
  a { color: #0b6bcb; text-decoration: none; }
  a:hover { text-decoration: underline; }
  img, svg {
    display: block;
    max-width: 100% !important;
    width: 100%;
    height: auto !important;
    margin: 1.5rem auto 0.5rem;
    border-radius: 6px;
  }
  blockquote {
    margin: 1.25rem 0;
    padding: 0.65rem 1.15rem;
    border-left: 4px solid #0d9488;
    background: #f8fafc;
    color: #334155;
  }
  code {
    font-family: var(--mono);
    font-size: 0.88em;
    background: #f1f5f9;
    padding: 0.15em 0.38em;
    border-radius: 4px;
  }
  pre {
    background: #0f172a;
    color: #f8fafc;
    padding: 1rem 1.2rem;
    border-radius: 6px;
    overflow-x: auto;
  }
  pre code { background: transparent; padding: 0; color: inherit; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 1.35rem 0;
    font-size: 0.93rem;
    display: block;
    overflow-x: auto;
  }
  th, td {
    border: 1px solid #cbd5e1;
    padding: 0.55rem 0.75rem;
    text-align: left;
    vertical-align: top;
  }
  th { background: #f1f5f9; font-weight: 600; color: #0f172a; }
  tr:nth-child(even) td { background: #f8fafc; }
  hr { border: 0; border-top: 1px solid #e2e8f0; margin: 2rem 0; }
</style>
"""

def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python3 scripts/render_md_html.py <input.md> [output.html]")
    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2]) if len(sys.argv) >= 3 else in_path.with_suffix(".html")

    md_txt = in_path.read_text(encoding="utf-8")
    # Convert GitHub $`...`$ inline math to standard $...$ so Pandoc --mathjax parses it cleanly
    md_clean = re.sub(r"\$`([^`]+)`\$", r"$\1$", md_txt)

    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as hf:
        hf.write(CLEAN_SANS_CSS)
        hdr_path = Path(hf.name)

    try:
        subprocess.run(
            [
                "pandoc",
                "-f", "gfm+tex_math_dollars",
                "-t", "html5",
                "--standalone",
                "--mathjax=https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js",
                "-H", str(hdr_path),
                "--metadata", f"title={in_path.stem}",
                "-o", str(out_path),
            ],
            input=md_clean,
            text=True,
            check=True,
        )
        print(f"[render_md_html] Wrote clean sans-serif HTML -> {out_path}")
    finally:
        hdr_path.unlink(missing_ok=True)

if __name__ == "__main__":
    main()
