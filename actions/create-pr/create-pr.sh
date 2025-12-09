#!/bin/bash

set -euo pipefail

BRANCH_NAME="$1"
BASE_BRANCH="${BASE_BRANCH:-main}"

# Get the current branch info
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if there are differences between the branches
if git diff --quiet "origin/$BASE_BRANCH...$BRANCH_NAME"; then
    echo "No differences found between $BRANCH_NAME and $BASE_BRANCH. Creating empty commit..."
    git commit --allow-empty -m "chore: empty commit to trigger PR"
    git push origin "$BRANCH_NAME"
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