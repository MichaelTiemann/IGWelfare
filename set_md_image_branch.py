#!/usr/bin/env python3
"""
set_md_image_branch.py
Switches Markdown image URLs between explicit GitHub branch raw URLs (while on a WIP branch)
and clean relative shorthand paths (when resolving to main).

Usage:
  python3 set_md_image_branch.py                  # Auto-detects current git branch (e.g., 'launch') on Document 1D.md
  python3 set_md_image_branch.py --all-docs       # Pins all *.md files to current git branch
  python3 set_md_image_branch.py --to-main --all-docs  # Restores relative shorthand paths before/at merge to main
"""

import argparse
import pathlib
import re
import subprocess

REPO_OWNER_NAME = "MichaelTiemann/IGWelfare"
RAW_PREFIX_RE = re.compile(
    rf"https://(?:raw\.githubusercontent\.com/{REPO_OWNER_NAME}|github\.com/{REPO_OWNER_NAME}/(?:raw|blob))/(?:refs/heads/)?[^/]+/"
)
MD_IMAGE_RE = re.compile(r"(!\[[^\]]*\]\()([^)]+)(\))")


def detect_git_branch(repo_dir: pathlib.Path) -> str:
    res = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        cwd=repo_dir, capture_output=True, text=True, check=True,
    )
    return res.stdout.strip()


def rewrite_links(md_text: str, target_branch: str | None) -> str:
    # Also ensure Document 1D points to Fig_11Layer_Welfare_And_MirrorInvestments
    md_text = md_text.replace(
        "Fig_7Segment_Welfare_And_MirrorInvestments_",
        "Fig_11Layer_Welfare_And_MirrorInvestments_",
    )

    def _repl(match: re.Match) -> str:
        prefix, url, suffix = match.groups()
        # Strip any existing GitHub raw/blob branch prefix down to relative repo path
        rel_path = RAW_PREFIX_RE.sub("", url.strip()).lstrip("./")
        if rel_path.startswith(("http://", "https://")):
            return match.group(0)  # Leave external non-repo URLs untouched
        if target_branch is None or target_branch == "main":
            return f"{prefix}{rel_path}{suffix}"
        raw_url = f"https://raw.githubusercontent.com/{REPO_OWNER_NAME}/{target_branch}/{rel_path}"
        return f"{prefix}{raw_url}{suffix}"

    return MD_IMAGE_RE.sub(_repl, md_text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--branch", help="Explicit branch name (defaults to active git branch)")
    parser.add_argument("--to-main", action="store_true", help="Convert back to relative shorthand paths for main")
    parser.add_argument("--all-docs", action="store_true", help="Apply across all *.md files in repo")
    args = parser.parse_args()

    repo_dir = pathlib.Path(__file__).resolve().parent
    branch = None if args.to_main else (args.branch or detect_git_branch(repo_dir))

    targets = sorted(repo_dir.glob("*.md")) if args.all_docs else [repo_dir / "Document 1D.md"]
    for path in targets:
        if not path.exists():
            continue
        orig = path.read_text(encoding="utf-8")
        updated = rewrite_links(orig, branch)
        if updated != orig:
            path.write_text(updated, encoding="utf-8")
            mode_lbl = "relative shorthand (main)" if branch in (None, "main") else f"branch '{branch}' raw URLs"
            print(f"Updated {path.name} -> {mode_lbl}")
        else:
            print(f"No link changes needed in {path.name}")


if __name__ == "__main__":
    main()
