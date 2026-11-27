#!/usr/bin/env python3
"""
Audits output/ against all *.md references in the repository.
Default: Dry-run (prints what is referenced vs. extraneous).
Pass --apply to remove extraneous Mirage/Set/SingleShock/scratch files (via git rm if tracked, else unlink).
Pass --apply --all-unreferenced to also remove any other unreferenced CSV/PNG/JPG files in output/.
"""
from pathlib import Path
import re
import subprocess
import sys

apply_mode = "--apply" in sys.argv
prune_all_unref = "--all-unreferenced" in sys.argv

root = Path(".")
out_dir = root / "output"
if not out_dir.exists():
    print("No output/ directory found.")
    sys.exit(0)

# 1. Collect every filename referenced inside any *.md file in the repo
md_refs = set()
for md in root.rglob("*.md"):
    if ".git" in md.parts:
        continue
    txt = md.read_text(encoding="utf-8", errors="ignore")
    for m in re.findall(r"output/[A-Za-z0-9_./-]+", txt):
        md_refs.add(Path(m).name)
    for m in re.findall(r"[A-Za-z0-9_-]+\.(?:png|jpg|svg|html|csv)", txt):
        md_refs.add(m)

# Check which files are git-tracked
tracked = set()
res = subprocess.run(["git", "ls-files", "output"], capture_output=True, text=True)
if res.returncode == 0:
    tracked = {Path(p.strip()) for p in res.stdout.splitlines() if p.strip()}

mirage_scratch_pat = re.compile(
    r"^(?:"
    r"Fig_LTFM_SingleShock_.*|"
    r"Table_LTFM_SingleShock_.*|"
    r"Fig_Doc3_Set_.*|"
    r"Table_Doc3_Set_.*|"
    r"Table_Doc3_Coalition_.*|"
    r"Table_Doc3_Accounting_Lens_.*|"
    r".*_[2-9]\.(?:jpg|jpeg|png)"
    r")$"
)

keep_referenced = []
prune_mirage = []
other_unref = []

for f in sorted(out_dir.rglob("*")):
    if not f.is_file() or f.name.startswith("."):
        continue
    if f.name in md_refs:
        keep_referenced.append(f)
    elif mirage_scratch_pat.match(f.name):
        prune_mirage.append(f)
    else:
        other_unref.append(f)

print(f"=== OUTPUT HYGIENE AUDIT ({'APPLY MODE' if apply_mode else 'DRY-RUN'}) ===")
print(f"  Protected (referenced in *.md):          {len(keep_referenced):3d} files")
print(f"  Extraneous Mirage/Subset/Scratch files:  {len(prune_mirage):3d} files")
print(f"  Other unreferenced files in output/:     {len(other_unref):3d} files\n")

if prune_mirage:
    print("Extraneous Mirage / Subset / Scratch files targeted for removal:")
    for f in prune_mirage:
        tag = "[git-tracked]" if f in tracked else "[untracked]  "
        print(f"  - {tag} {f}")

if other_unref:
    print("\nOther unreferenced files in output/ (kept unless --all-unreferenced is passed):")
    for f in other_unref[:35]:
        tag = "[git-tracked]" if f in tracked else "[untracked]  "
        print(f"  ? {tag} {f}")
    if len(other_unref) > 35:
        print(f"  ... and {len(other_unref) - 35} more.")

targets = prune_mirage + (other_unref if prune_all_unref else [])
if apply_mode and targets:
    print(f"\nRemoving {len(targets)} file(s)...")
    for f in targets:
        if f in tracked:
            subprocess.run(["git", "rm", "-f", str(f)], check=True)
        else:
            f.unlink()
    print("Done.")
elif not apply_mode:
    print("\nDry-run complete. Re-run with `python3 scripts_prune_output.py --apply` to delete targeted files.")
