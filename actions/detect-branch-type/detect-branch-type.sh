#!/usr/bin/env bash
set -euo pipefail

# Environment variables:
# - HEAD_BRANCH: The branch name to check (required)
# - MAJOR_BRANCH_PATTERNS: Comma-separated patterns for major version bumps (default: "major/")
# - HOTFIX_BRANCH_PATTERNS: Comma-separated patterns for hotfix/patch version bumps (default: "hotfix/")
# - META_BRANCH_PATTERNS: Comma-separated patterns for non-version-bumping branches (default: "meta/")

HEAD_BRANCH="${HEAD_BRANCH:-}"
MAJOR_BRANCH_PATTERNS="${MAJOR_BRANCH_PATTERNS:-major/}"
PATCH_BRANCH_PATTERNS="${PATCH_BRANCH_PATTERNS:-hotfix/}"
META_BRANCH_PATTERNS="${META_BRANCH_PATTERNS:-meta/}"

# Function to check if branch matches any pattern
matches_pattern() {
    local branch="$1"
    local patterns="$2"
    IFS=',' read -ra PATTERN_ARRAY <<< "$patterns"
    for pattern in "${PATTERN_ARRAY[@]}"; do
        # Trim whitespace
        pattern=$(echo "$pattern" | xargs)
        if [[ "${branch}" =~ ^${pattern} ]]; then
            return 0
        fi
    done
    return 1
}

# Detect branch type
if matches_pattern "${HEAD_BRANCH}" "${META_BRANCH_PATTERNS}"; then
    BRANCH_TYPE="meta"
    echo "Detected meta branch (no version bump): ${HEAD_BRANCH}"
elif matches_pattern "${HEAD_BRANCH}" "${MAJOR_BRANCH_PATTERNS}"; then
    BRANCH_TYPE="major"
    echo "Detected major branch: ${HEAD_BRANCH}"
elif matches_pattern "${HEAD_BRANCH}" "${PATCH_BRANCH_PATTERNS}"; then
    BRANCH_TYPE="patch"
    echo "Detected patch branch: ${HEAD_BRANCH}"
else
    BRANCH_TYPE="minor"
    echo "Detected minor branch: ${HEAD_BRANCH}"
fi

echo "branch_type=${BRANCH_TYPE}" >> "${GITHUB_OUTPUT}"