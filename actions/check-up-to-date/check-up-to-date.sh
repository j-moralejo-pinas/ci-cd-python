#!/bin/bash
set -u

TARGET_BRANCH="${1:?Target branch is required}"
SOURCE_REF="${2:?Source ref is required}"
IGNORE_PATTERNS="${3:-}"

# Ensure we are in the repo root or have git context
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository."
    exit 1
fi

echo "Fetching latest changes..."
# Fetch origin to ensure we know about target branch state
# We fetch target branch specifically
git fetch origin "$TARGET_BRANCH" --depth=1 >/dev/null 2>&1 || { echo "Could not fetch $TARGET_BRANCH"; exit 1; }

# Parse SHAs
TARGET_SHA=$(git rev-parse "origin/$TARGET_BRANCH")
# Source ref is usually checked out or available.
# Use origin/source_ref if available, else local
SOURCE_SHA=$(git rev-parse "$SOURCE_REF")

echo "Checking if $SOURCE_REF ($SOURCE_SHA) is up to date with $TARGET_BRANCH ($TARGET_SHA)..."

if git merge-base --is-ancestor "$TARGET_SHA" "$SOURCE_SHA"; then
    echo "✅ Branch is up to date."
    exit 0
else
    echo "⚠️ Branch is NOT up to date with $TARGET_BRANCH."
fi

# Check ignore patterns
if [[ -n "$IGNORE_PATTERNS" ]]; then
    echo "Checking ignore patterns: $IGNORE_PATTERNS"
    IFS=',' read -ra ADDR <<< "$IGNORE_PATTERNS"
    for pattern in "${ADDR[@]}"; do
        # trim whitespace
        pattern=$(echo "$pattern" | xargs)

        # Check glob match using bash pattern matching
        # shellcheck disable=SC2053
        if [[ "$SOURCE_REF" == $pattern ]]; then
            echo "⏭️ Matched ignore pattern: '$pattern'. Skipping enforcement."
            exit 0
        fi
    done
fi

echo "❌ Enforcing up-to-date policy: Please update your branch."
echo "Command to run: git pull origin $TARGET_BRANCH"
exit 1
