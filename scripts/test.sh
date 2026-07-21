#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
python3 scripts/generate_ports.py
before=$(find ports -type f -print0 | sort -z | xargs -0 shasum -a 256)
python3 scripts/generate_ports.py
after=$(find ports -type f -print0 | sort -z | xargs -0 shasum -a 256)
if [ "$before" != "$after" ]; then
    printf 'Port generation is not deterministic.\n' >&2
    exit 1
fi
swift build
swift run stargazing-selftest
