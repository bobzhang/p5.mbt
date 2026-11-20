#!/bin/sh
# Packages or publishes both modules of the workspace.
#
#   tools/publish.sh package   # dry run: build both zips and list their files
#   tools/publish.sh publish   # publish bobzhang/p5, then bobzhang/p5_demos
#
# The root .moonignore keeps p5_demos/ out of the bobzhang/p5 package. moon
# also applies that file when packaging p5_demos itself (which would then be
# empty), so it is set aside for that step and restored afterwards.
set -eu
cd "$(dirname "$0")/.."

case "${1:-package}" in
  package) cmd="package --list" ;;
  publish) cmd="publish" ;;
  *) echo "usage: $0 [package|publish]" >&2; exit 2 ;;
esac

echo "== bobzhang/p5"
moon $cmd

echo "== bobzhang/p5_demos"
mv .moonignore .moonignore.root
trap 'mv .moonignore.root .moonignore' EXIT
(cd p5_demos && moon $cmd)
