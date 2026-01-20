#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: BUMP_TYPE_INPUT - bump type (major, minor, patch, meta, auto, or empty)
# 2: DETECTED_BRANCH_TYPE - detected branch type (from detect-branch-type action)
# 3: PAT_TOKEN - optional PAT token for git-cliff

BUMP_TYPE_INPUT="${1:-}"
DETECTED_BRANCH_TYPE="${2:-}"
PAT_TOKEN="${3:-}"

# Location of helper scripts (fallback to current dir if var not set)
SCRIPT_DIR="${GITHUB_ACTION_PATH:-$(cd $(dirname "$0") && pwd)}"

# 1) Get Latest Version
LATEST="$("${SCRIPT_DIR}/get-latest-semver.sh")"
echo "latest=${LATEST}" >> "${GITHUB_OUTPUT}"

# Determine strategy
USE_GIT_CLIFF=false
BRANCH_TYPE=""

if [[ -n "$BUMP_TYPE_INPUT" && "$BUMP_TYPE_INPUT" != "auto" ]]; then
    # Explicit bump type (manual override)
    BRANCH_TYPE="$BUMP_TYPE_INPUT"
elif [[ "$BUMP_TYPE_INPUT" == "auto" ]]; then
    # Auto mode
    if [[ "$DETECTED_BRANCH_TYPE" == "major" || "$DETECTED_BRANCH_TYPE" == "patch" || "$DETECTED_BRANCH_TYPE" == "meta" ]]; then
        BRANCH_TYPE="$DETECTED_BRANCH_TYPE"
    else
        # If detected as minor (default/no match) or empty, use git-cliff
        USE_GIT_CLIFF=true
    fi
else
    # Empty bump type input -> use detected (legacy manual behavior)
    BRANCH_TYPE="${DETECTED_BRANCH_TYPE:-minor}"
fi


if [[ "$USE_GIT_CLIFF" == "true" ]]; then
    echo "Auto-bump: Using git-cliff to determine version..."

    # Install git-cliff if not present
    if ! command -v git-cliff &> /dev/null; then
        echo "Installing git-cliff..."
        pip install git-cliff
    fi

    # Run git-cliff
    if [[ -n "$PAT_TOKEN" ]]; then
        export GITHUB_TOKEN="$PAT_TOKEN"
    fi

    echo "Running git-cliff --bumped-version..."
    OUTPUT=$(git-cliff --bumped-version 2>&1 || true)
    
    echo "git-cliff output:"
    echo "$OUTPUT"

    # Extract version: Look for lines that match version format
    NEW_TAG_RAW=$(echo "$OUTPUT" | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+" | tail -n1)
    
    if [[ -z "$NEW_TAG_RAW" ]]; then
         echo "Error: Could not determine next version with git-cliff."
         exit 1
    fi
    
    if [[ "$NEW_TAG_RAW" != v* ]]; then
        NEW_TAG="v$NEW_TAG_RAW"
    else
        NEW_TAG="$NEW_TAG_RAW"
    fi

    echo "Calculated new tag (git-cliff): $NEW_TAG"

else
    echo "Manual specific bump: ${BRANCH_TYPE}"
    
    # Use helper script to calculate
    NEW_TAG="$("${SCRIPT_DIR}/calculate-bumped-version.sh" "${LATEST}" "${BRANCH_TYPE}")"
    
    echo "Calculated new tag (manual): $NEW_TAG"
fi

echo "new_tag=${NEW_TAG}" >> "${GITHUB_OUTPUT}"
echo "version=${NEW_TAG#v}" >> "${GITHUB_OUTPUT}"
