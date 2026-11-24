#!/usr/bin/env bash
# Build one architecture and leave dist/vanish.vitalsoft_<arch>.click behind.
#   ci/build-click.sh <amd64|arm64|armhf>
# Runs inside a clickable/ci-20.04-* image (clickable is preinstalled and in container mode).
set -euo pipefail
cd "$(dirname "$0")/.."
arch="${1:?usage: build-click.sh <amd64|arm64|armhf>}"

export CLICK_ARCH_OVERRIDE="$arch"      # read by CMakeLists.txt -> manifest "architecture"
rm -rf build dist
clickable build --arch "$arch"

mkdir -p dist
found=$(find build -name "*_${arch}.click" | head -n1 || true)
if [ -z "$found" ]; then
    echo "No *_${arch}.click produced. Click files found:" >&2
    find build -name '*.click' >&2 || true
    exit 1
fi
cp -v "$found" "dist/vanish.vitalsoft_${arch}.click"
chmod -R a+rwX build dist 2>/dev/null || true
ls -l dist
