#!/bin/bash
# ---------------------------------------------------------------------------
# cf-build.sh
#
# Purpose:
#   Generate `_updated.json` — a map of { filepath: ISO-8601 commit time } —
#   from git history. Docsify will read this file at runtime to display the
#   "Last Modified" date.
#
# Why not rely on file mtime / HTTP Last-Modified?
#   Cloudflare Pages does not preserve file mtime when deploying, so the
#   `Last-Modified` response header does not reflect the real commit time.
#   GitHub Pages happens to work, Cloudflare Pages does not. This script
#   sidesteps the problem entirely by baking the timestamps into a JSON file.
#
# Cloudflare Pages config:
#   Root directory          : (leave empty / default = repo root)
#   Build command           : chmod +x cf-build.sh && ./cf-build.sh
#   Build output directory  : /
# ---------------------------------------------------------------------------

set -e

python3 - <<'PYEOF'
import subprocess, json, os

# List all files tracked by git
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
    json.dump(data, fp, ensure_ascii=False)

print(f"cf-build.sh: wrote _updated.json with {len(data)} entries.")
PYEOF
