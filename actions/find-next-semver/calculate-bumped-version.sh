#!/usr/bin/env bash
set -euo pipefail

# Usage: ./calculate-bumped-version.sh <current_version> <bump_type>
# <current_version>: e.g. v1.2.3 or 1.2.3
# <bump_type>: major, minor, patch, meta
# Output: vX.Y.Z

CURRENT_VERSION="$1"
BUMP_TYPE="$2"

# Normalize version (remove potential 'v')
VERSION_CLEAN="${CURRENT_VERSION#v}"

if [[ ! "${VERSION_CLEAN}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    # Fallback or error - strict mode implies error
    echo "Error: Invalid version format '${CURRENT_VERSION}'. Expected X.Y.Z or vX.Y.Z" >&2
    exit 1
fi

X="${BASH_REMATCH[1]}"
Y="${BASH_REMATCH[2]}"
Z="${BASH_REMATCH[3]}"

if [[ "${BUMP_TYPE}" == "major" ]]; then
    X=$((X+1)); Y=0; Z=0
elif [[ "${BUMP_TYPE}" == "patch" ]]; then
    Z=$((Z+1))
elif [[ "${BUMP_TYPE}" == "meta" ]]; then
    # No change for meta branches
    :
else
    # Default to minor if unknown or explicitly minor
    Y=$((Y+1)); Z=0
fi

echo "v${X}.${Y}.${Z}"
