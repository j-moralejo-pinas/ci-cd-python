#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
# - GH_TOKEN: token for GitHub CLI auth
# - PRS: (Should be empty or ignored here, as this script is for when PRS is empty)
# - VERSION: tag for the new changelog entry (e.g., vX.Y.Z)
# - CHANGELOG_PATH: path to changelog (default CHANGELOG.rst)

GH_TOKEN="${GH_TOKEN:-}"
VERSION="${VERSION:-}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.rst}"

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
git-cliff --tag "${VERSION}" --prepend "${CHANGELOG_PATH}" -u
