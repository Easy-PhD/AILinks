#!/bin/bash
# ---------------------------------------------------------------------------
# cf-build.sh
#
# Purpose:
#   Generate `_updated.json` (map of { filepath: ISO-8601 commit time }) from
#   git history, so Docsify can display an accurate "Last Modified" date on
#   every page — including on Cloudflare Pages, which does not preserve file
#   mtimes and does not expose a reliable `Last-Modified` HTTP header.
#
# IMPORTANT:
#   Cloudflare Pages performs a SHALLOW clone by default. With a shallow
#   clone, `git log -1 -- <file>` returns the tip commit's time for every
#   file, making all pages show the same date. We therefore run
#   `git fetch --unshallow` first to restore the full history.
#
# Cloudflare Pages config:
#   Root directory          : (leave empty / default = repo root)
#   Build command           : chmod +x cf-build.sh && ./cf-build.sh
#   Build output directory  : /
# ---------------------------------------------------------------------------

set -e

# --- Step 1: ensure full git history ---------------------------------------
# Cloudflare Pages uses a shallow clone; unshallow it so per-file commit
# timestamps are accurate. `--unshallow` fails on a complete repo, so we
# fall back to a deep fetch and finally ignore failure with `|| true`.
if [ -f .git/shallow ]; then
  echo "cf-build.sh: shallow clone detected, fetching full history..."
  git fetch --unshallow --tags 2>/dev/null \
    || git fetch --depth=1000 2>/dev/null \
    || true
fi

# --- Step 2: build _updated.json -------------------------------------------
python3 - <<'PYEOF'
import subprocess, json, os

result = subprocess.run(['git', 'ls-files'], capture_output=True, text=True, check=True)
files = [f for f in result.stdout.splitlines() if f]

data = {}
for f in files:
    if not os.path.isfile(f):
        continue
    # %cI = committer date in strict ISO-8601 format
    r = subprocess.run(['git', 'log', '-1', '--format=%cI', '--', f],
                       capture_output=True, text=True)
    ts = r.stdout.strip()
    if ts:
        data[f] = ts

with open('_updated.json', 'w', encoding='utf-8') as fp:
    json.dump(data, fp, ensure_ascii=False, indent=2)

print(f"cf-build.sh: wrote _updated.json with {len(data)} entries.")
for k, v in list(data.items())[:5]:
    print(f"  {v}  {k}")
PYEOF
