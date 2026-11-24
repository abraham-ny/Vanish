#!/usr/bin/env bash
# Shared by the GitLab and GitHub pipelines.
#   ci/prepare.sh [tag]
# * with a tag: fails unless the tag (minus a leading "v") equals the version in manifest.json.in
# * VANISH_API_URL (CI secret/variable): written into qml/js/config.js so the URL never lives in the repo.
#   Required for tag (release) builds. NOTE: the finished .click still contains it in plain text.
set -euo pipefail
cd "$(dirname "$0")/.."
tag="${1:-}"

version=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' manifest.json.in | head -n1)
[ -n "$version" ] || { echo "cannot read version from manifest.json.in" >&2; exit 1; }
echo "manifest version: $version"

if [ -n "$tag" ] && [ "${tag#v}" != "$version" ]; then
    echo "Tag '$tag' does not match manifest version '$version'. Bump manifest.json.in first." >&2
    exit 1
fi

if [ -n "${VANISH_API_URL:-}" ]; then
    esc=$(printf '%s' "$VANISH_API_URL" | sed 's/[&|\\]/\\&/g')
    sed -i "s|^var API_URL = .*|var API_URL = \"${esc}\";|" qml/js/config.js
    grep -q '^var API_URL = "..*";' qml/js/config.js || { echo "failed to set API_URL" >&2; exit 1; }
    echo "API_URL injected (value not printed)"
elif [ -n "$tag" ]; then
    echo "VANISH_API_URL is not set; refusing to build a release with an empty backend URL." >&2
    exit 1
else
    echo "VANISH_API_URL not set: building with the API_URL from config.js (empty by default)."
fi
