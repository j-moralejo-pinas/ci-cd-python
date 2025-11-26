#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
PATCH_PATTERNS="${PATCH_PATTERNS:-hotfix/}"
PREV_COMMIT="${PREV_COMMIT:-}"

git fetch origin --prune --tags

# =============================================================================
# Build regex pattern from patch-branch-patterns
# =============================================================================
# Convert comma-separated patterns to regex alternation
# e.g., "hotfix/,patch/" -> "^(hotfix/|patch/)"
if [[ -n "${PATCH_PATTERNS}" ]]; then
  PATCH_REGEX="^($(echo "${PATCH_PATTERNS}" | sed 's/,/|/g'))"
  echo "Excluding branches matching: ${PATCH_REGEX}"
else
  PATCH_REGEX=""
fi

# =============================================================================
# Find PRs between previous release and HEAD
# =============================================================================
echo "Finding PRs between ${PREV_COMMIT} and HEAD..."

# Get all commits between previous release and HEAD
COMMITS=$(git rev-list --reverse --first-parent "${PREV_COMMIT}..HEAD" || true)

if [[ -z "${COMMITS}" ]]; then
  echo "No commits found between previous release and HEAD"
  echo "numbers=" >> "${GITHUB_OUTPUT}"
  exit 0
fi

# For each commit, find associated PRs merged to main, excluding patch branches
PRS=""
while IFS= read -r commit; do
  [[ -z "${commit}" ]] && continue
  
  # Get PRs associated with this commit that were merged to main
  PR_DATA=$(gh api "repos/${REPO_SLUG}/commits/${commit}/pulls" \
    -H "Accept: application/vnd.github+json" \
    --jq "map(select(.base.ref==\"${MAIN_BRANCH}\")) | .[] | \"\(.number) \(.head.ref)\"" 2>/dev/null || true)
  
  while IFS= read -r pr_line; do
    [[ -z "${pr_line}" ]] && continue
    
    PR_NUM=$(echo "${pr_line}" | awk '{print $1}')
    HEAD_REF=$(echo "${pr_line}" | awk '{print $2}')
    
    # Skip if branch matches patch patterns
    if [[ -n "${PATCH_REGEX}" ]] && echo "${HEAD_REF}" | grep -qE "${PATCH_REGEX}"; then
      echo "Skipping PR #${PR_NUM} from patch branch: ${HEAD_REF}"
      continue
    fi
    
    PRS="${PRS}${PR_NUM}"$'\n'
  done <<< "${PR_DATA}"
done <<< "${COMMITS}"

# Remove duplicates and empty lines
PRS=$(echo "${PRS}" | awk 'NF && !seen[$0]++')

# Output space-separated PR numbers for GitHub Actions compatibility
PR_NUMBERS_SPACE_SEPARATED=$(printf '%s' "${PRS}" | tr '\n' ' ' | sed 's/[[:space:]]*$//')
echo "numbers=${PR_NUMBERS_SPACE_SEPARATED}" >> "${GITHUB_OUTPUT}"

echo "PRs between releases (excluding patch branches):"
printf '%s\n' "${PRS}"
