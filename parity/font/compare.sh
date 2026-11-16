#!/bin/sh
# Compares p5.mbt's font outlines with Typr's: compare.sh font text
cd "$(dirname "$0")/../.."
moon build --target js parity/font/dump >/dev/null 2>&1 || exit 1
js=$(find _build/js -path '*parity/font/dump/dump.js' | head -1)
a=$(node parity/font/typr_dump.mjs "$1" "$2" 2>&1 | tail -1)
b=$(node "$js" "$1" "$2")
if [ "$a" = "$b" ]; then echo "identical: $1 \"$2\""; else
  echo "DIFFER: $1"; echo "$a" | head -c 400; echo; echo "$b" | head -c 400; echo; fi
