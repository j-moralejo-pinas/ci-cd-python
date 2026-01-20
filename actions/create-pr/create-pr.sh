#!/bin/bash

set -euo pipefail

# Arguments:
# 1: BRANCH_NAME - name of the branch to create PR from
# 2: PAT_TOKEN - Personal Access Token for git authentication
# 3: GH_TOKEN - GitHub token for gh CLI (optional, uses GITHUB_TOKEN env var if not provided)

BRANCH_NAME="$1"
PAT_TOKEN="$2"
GH_TOKEN="${3:-${GITHUB_TOKEN:-}}"
BASE_BRANCH="${BASE_BRANCH:-main}"

# Export GH_TOKEN for gh CLI if provided
if [[ -n "${GH_TOKEN}" ]]; then
  export GH_TOKEN
fi

# Fetch latest refs from origin
git fetch origin "$BASE_BRANCH"

# Resolve refs to commit SHAs
BASE_COMMIT=$(git rev-parse "origin/$BASE_BRANCH")
HEAD_COMMIT=$(git rev-parse HEAD)

# Check if there are differences between the commits
if git diff --quiet "$BASE_COMMIT" "$HEAD_COMMIT"; then
    echo "No differences found between $BRANCH_NAME and $BASE_BRANCH. Creating empty commit..."
    git commit --allow-empty -m "chore: empty commit to trigger PR"
    git push "https://x-access-token:${PAT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD:"$BRANCH_NAME"
fi

# Create a pull request using gh CLI
gh pr create \
    --base "$BASE_BRANCH" \
    --head "$BRANCH_NAME" \
    --title "Release: $BRANCH_NAME" \
    --body "Automated release pull request from $BRANCH_NAME to $BASE_BRANCH"

# Enable auto-merge for the PR
gh pr merge "$BRANCH_NAME" --auto --merge -d

echo "Pull request created from $BRANCH_NAME to $BASE_BRANCH with auto-merge enabled"