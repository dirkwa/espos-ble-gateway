#!/usr/bin/env bash
# Run an ESP-IDF build without starving the interactive session.
#
# A full build saturates all cores on a 4-core Pi and the editor's SSH
# session stops getting scheduled -- at -j3 the host has frozen hard enough
# to need a power cycle. nice/ionice plus HALF the cores fix that, and a
# lock keeps two builds from racing on build/.
#
# Usage: scripts/build.sh [idf.py args…]     (default: build)
set -euo pipefail

# Not /tmp, and not XDG_RUNTIME_DIR either: both are tmpfs on this host, and
# nothing a build touches should live in the RAM the compiler is short of.
# The lock itself is empty, so this is about the rule holding everywhere
# rather than about these bytes.
LOCK_DIR="$HOME/.cache"
mkdir -p "$LOCK_DIR"
LOCK="$LOCK_DIR/.idf-build-$(id -u)-$(basename "$PWD").lock"
exec 9>"$LOCK"
if ! flock -n 9; then
  if [ "${BUILD_NOWAIT:-0}" = "1" ]; then
    echo "==> another build is running (BUILD_NOWAIT=1) — aborting" >&2
    exit 1
  fi
  echo "==> waiting for the running build to finish…" >&2
  flock 9
fi

if [ -z "${IDF_PATH:-}" ]; then
  echo "==> IDF_PATH not set: source the export.sh of ESP-IDF $(cat .idf-version)" >&2
  exit 1
fi

# IDF 6's idf.py has no -j option; parallelism is ninja's. Configure via
# idf.py (component manager, sdkconfig), then compile with a capped ninja.
# Half the cores, floor of 1: on a 4-core Pi that is 2, leaving room for the
# editor, SSH and the SignalK containers. Raise deliberately with BUILD_JOBS
# on a bigger machine -- do not raise it here.
JOBS="${BUILD_JOBS:-$(( $(nproc) / 2 ))}"
[ "$JOBS" -lt 1 ] && JOBS=1
if [ $# -gt 0 ] && [ "$1" != "build" ]; then
  exec nice -n 15 ionice -c 3 idf.py "$@"
fi
nice -n 15 ionice -c 3 idf.py reconfigure
exec nice -n 15 ionice -c 3 ninja -C build -j "$JOBS"
