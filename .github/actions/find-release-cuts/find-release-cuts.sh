#!/usr/bin/env bash
set -euo pipefail

DEV_BRANCH="${DEV_BRANCH:-dev}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"

git fetch origin --prune --tags

# Current release cut from dev
CUR_CUT=$(git merge-base --fork-point "origin/${DEV_BRANCH}" HEAD || git merge-base "origin/${DEV_BRANCH}" HEAD)

# Previous release cut via latest x.y.0 tag reachable from main
TAG=$(git tag --merged "origin/${MAIN_BRANCH}" --sort=-v:refname | awk '/^v?[0-9]+\.[0-9]+\.0$/ {print; exit}')
if [[ -z "${TAG:-}" ]]; then
  echo "No x.y.0 tag found on origin/${MAIN_BRANCH}" >&2
  exit 1
fi

# Merge into main that brought TAG in, if any
MERGE=$(git rev-list --merges --ancestry-path "${TAG}".."origin/${MAIN_BRANCH}" | tail -n1 || true)
[[ -z "${MERGE}" ]] && MERGE="${TAG}"

# If MERGE is a true merge, parent 2 is the release tip; else fall back to the tag itself
PARENTS=$(git rev-list --parents -n1 "${MERGE}")
if [[ "$(wc -w <<<"${PARENTS}")" -ge 3 ]]; then
  REL_TIP=$(awk '{print $3}' <<<"${PARENTS}")
else
  REL_TIP="${TAG}"
fi

PREV_CUT=$(git merge-base --fork-point "origin/${DEV_BRANCH}" "${REL_TIP}" || git merge-base "origin/${DEV_BRANCH}" "${REL_TIP}")

{
  echo "cur_cut=${CUR_CUT}"
  echo "prev_cut=${PREV_CUT}"
} >> "${GITHUB_OUTPUT}"

echo "Current cut:  ${CUR_CUT}"
echo "Previous cut: ${PREV_CUT}"
