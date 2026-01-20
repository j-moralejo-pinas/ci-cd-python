#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: GH_TOKEN - token for GitHub CLI auth
# 2: VERSION - tag for the new changelog entry (e.g., vX.Y.Z)
# 3: CHANGELOG_PATH - path to changelog (default CHANGELOG.rst)

GH_TOKEN="${1:-}"
VERSION="${2:-}"
CHANGELOG_PATH="${3:-CHANGELOG.rst}"

if ! command -v git-cliff &> /dev/null; then
  echo "git-cliff not found. Installing..."
  pip install git-cliff
fi

export GITHUB_TOKEN="${GH_TOKEN}"

# Generate the changelog slice and prepend it to the file
# --unreleased: include commits that are not yet tagged (which works if we are tagging now)
# --tag: sets the version for the unreleased changes
# --prepend: prepends to the file
echo "Running git-cliff to update ${CHANGELOG_PATH}..."
GITHUB_TOKEN="${GH_TOKEN}" git-cliff --tag "${VERSION}" --prepend "${CHANGELOG_PATH}" -u
