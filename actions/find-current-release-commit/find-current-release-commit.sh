#!/usr/bin/env bash
set -euo pipefail

MAIN_BRANCH="${MAIN_BRANCH:-main}"

git fetch origin --prune --tags

# Current release commit is the HEAD of main
CUR_COMMIT=$(git rev-parse "origin/${MAIN_BRANCH}")

# Find the latest x.y.0 version tag on main (if any)
CUR_TAG=$(git tag --merged "origin/${MAIN_BRANCH}" --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+\.0$' | head -1 || true)

echo "cur_commit=${CUR_COMMIT}" >> "${GITHUB_OUTPUT}"
echo "cur_tag=${CUR_TAG:-}" >> "${GITHUB_OUTPUT}"

echo "Current release commit: ${CUR_COMMIT}"
if [[ -n "${CUR_TAG:-}" ]]; then
    echo "Current release tag: ${CUR_TAG}"
else
    echo "No version tag found on main"
fi
