#!/usr/bin/env bash
set -euo pipefail

MAIN_BRANCH="${MAIN_BRANCH:-main}"

git fetch origin --prune --tags

# Get all x.y.0 version tags on main, sorted by version descending
TAGS=$(git tag --merged "origin/${MAIN_BRANCH}" --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+\.0$' || true)

# Count tags to determine previous
TAG_COUNT=$(echo "${TAGS}" | grep -c . || true)

if [[ "${TAG_COUNT}" -ge 2 ]]; then
  # Get the second tag (previous release)
  PREV_TAG=$(echo "${TAGS}" | sed -n '2p')
  PREV_COMMIT=$(git rev-list -n1 "${PREV_TAG}")
  echo "prev_commit=${PREV_COMMIT}" >> "${GITHUB_OUTPUT}"
  echo "prev_tag=${PREV_TAG}" >> "${GITHUB_OUTPUT}"
  echo "Previous release commit: ${PREV_COMMIT}"
  echo "Previous release tag: ${PREV_TAG}"
elif [[ "${TAG_COUNT}" -eq 1 ]]; then
  # Only one tag exists, use initial commit as previous
  echo "Only one version tag found - using initial commit as previous release"
  PREV_COMMIT=$(git rev-list --max-parents=0 "origin/${MAIN_BRANCH}" | head -1)
  echo "prev_commit=${PREV_COMMIT}" >> "${GITHUB_OUTPUT}"
  echo "prev_tag=" >> "${GITHUB_OUTPUT}"
  echo "Previous release commit (initial): ${PREV_COMMIT}"
else
  # No tags exist, use initial commit
  echo "No version tags found - using initial commit as previous release"
  PREV_COMMIT=$(git rev-list --max-parents=0 "origin/${MAIN_BRANCH}" | head -1)
  echo "prev_commit=${PREV_COMMIT}" >> "${GITHUB_OUTPUT}"
  echo "prev_tag=" >> "${GITHUB_OUTPUT}"
  echo "Previous release commit (initial): ${PREV_COMMIT}"
fi
