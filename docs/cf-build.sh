#!/bin/bash
# ---------------------------------------------------------------------------
# cf-build.sh
#
# Purpose:
#   Rewrite the modification time (mtime) of every git-tracked file to the
#   timestamp of its last commit, so Docsify's `time-updater` plugin shows
#   the correct "Last Modified" date.
#
# Why this works with Cloudflare Pages:
#   Docsify is a pure static site. The entry point is `index.html` at the
#   repo root, so no build artifacts are produced here. On Cloudflare Pages:
#
#     Root directory          : (leave empty / default = repo root)
#     Build command           : chmod +x cf-build.sh && ./cf-build.sh
#     Build output directory  : /
#
#   Setting the output directory to `/` tells Cloudflare to serve the repo
#   root directly as static assets. This script only fixes file timestamps.
#
# Notes:
#   - No files are copied or generated. That is intentional.
#   - If you later switch Build output to `public`, you must also copy files
#     into `public/` (see alternative below).
# ---------------------------------------------------------------------------

set -e  # Exit immediately on error

# Iterate over all files tracked by git
git ls-files | while read -r file; do
  # Only process regular files (skip dirs, submodules, symlinks to dirs, etc.)
  if [ -f "$file" ]; then
    # %ct = committer timestamp (Unix epoch) of the last commit touching
    #       this file. `touch -d @<epoch>` sets the file's mtime to it.
    touch -d "@$(git log -1 --format=%ct -- "$file")" "$file"
  fi
done

echo "cf-build.sh: file timestamps updated."
