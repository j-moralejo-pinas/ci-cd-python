#!/usr/bin/env bash
set -euo pipefail

# Fetches tags and determines the latest SemVer tag (vX.Y.Z)
# Outputs the tag to stdout, or v0.0.0 if none found.

# Fetch tags, silencing output
git fetch --tags --force --prune >/dev/null 2>&1

# Find the latest tag matching semver pattern
LATEST="$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-version:refname | head -n1)"

if [[ -z "${LATEST}" ]]; then
    echo "v0.0.0"
else
    echo "${LATEST}"
fi
