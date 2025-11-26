#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-}"
DEV_BRANCH="${DEV_BRANCH:-dev}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"

git fetch origin --prune --tags

# =============================================================================
# Find previous release cut
# =============================================================================
# Look for latest x.y.0 tag reachable from main
TAG=$(git tag --merged "origin/${MAIN_BRANCH}" --sort=-v:refname | awk '/^v?[0-9]+\.[0-9]+\.0$/ {print; exit}')
if [[ -z "${TAG:-}" ]]; then
  echo "No x.y.0 tag found - using initial commit of dev as previous cut"
  PREV_CUT=$(git rev-list --max-parents=0 "origin/${DEV_BRANCH}" | head -1)
else
  echo "Found previous release tag: ${TAG}"
  # Find merge into main that brought TAG in, if any
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
fi

echo "Previous cut: ${PREV_CUT}"
echo "prev_cut=${PREV_CUT}" >> "${GITHUB_OUTPUT}"

# =============================================================================
# Find current release cut
# =============================================================================
CUR_CUT=$(git merge-base --fork-point "origin/${DEV_BRANCH}" HEAD || git merge-base "origin/${DEV_BRANCH}" HEAD)

echo "Current cut: ${CUR_CUT}"
echo "cur_cut=${CUR_CUT}" >> "${GITHUB_OUTPUT}"

# =============================================================================
# Find PRs between cuts
# =============================================================================
PRS=$(git rev-list --reverse --first-parent "${PREV_CUT}..${CUR_CUT}" \
  | xargs -n1 -I{} gh api "repos/${REPO_SLUG}/commits/{}/pulls" \
       -H "Accept: application/vnd.github+json" \
       --jq "map(select(.base.ref==\"${DEV_BRANCH}\")) | .[].number" \
  | awk '!seen[$0]++')

# Output space-separated PR numbers for GitHub Actions compatibility
PR_NUMBERS_SPACE_SEPARATED=$(printf '%s' "${PRS}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
echo "numbers=${PR_NUMBERS_SPACE_SEPARATED}" >> "${GITHUB_OUTPUT}"

echo "PRs between cuts:"
printf '%s\n' "${PRS}"
