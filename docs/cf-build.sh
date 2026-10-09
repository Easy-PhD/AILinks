#!/bin/bash

git ls-files | while read file; do
  if [ -f "$file" ]; then
    touch -d @$(git log -1 --format="%ct" -- "$file") "$file"
  fi
done
