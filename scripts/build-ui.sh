#!/usr/bin/env bash
# Build the espOS web UI into espos/ui/dist-gz/, which the top-level
# CMakeLists packs into the LittleFS "storage" image.
#
# Skipping this is survivable but confusing: the device then serves espOS's
# embedded placeholder page instead of the config UI, which looks like a
# firmware bug rather than a missing build step.
#
# Same nice/ionice treatment as scripts/build.sh - vite saturates a Pi.
set -euo pipefail

UI="$(cd "$(dirname "$0")/.." && pwd)/espos/ui"
[ -d "$UI" ] || { echo "==> $UI missing - run: git submodule update --init" >&2; exit 1; }
cd "$UI"

# gzip-dist.mjs does `rm -rf dist-gz/` first, so two concurrent runs would
# race on a half-deleted directory.
LOCK="${TMPDIR:-/tmp}/.espos-ui-build-$(id -u).lock"
exec 9>"$LOCK"
flock 9

# `npm ci` is slow and almost always unnecessary; only redo it when the
# lockfile actually changed.
STAMP="node_modules/.espos-lock-hash"
HASH="$(sha256sum package-lock.json | cut -d' ' -f1)"
if [ ! -f "$STAMP" ] || [ "$(cat "$STAMP")" != "$HASH" ]; then
  echo "==> npm ci"
  nice -n 15 ionice -c 3 npm ci
  echo "$HASH" > "$STAMP"
fi

echo "==> npm run build"
nice -n 15 ionice -c 3 npm run build
echo "==> ui bundle ready: $UI/dist-gz"
