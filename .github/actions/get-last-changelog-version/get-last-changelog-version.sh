#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Path to the changelog file (default: CHANGELOG.rst)

CHANGELOG_PATH="${1:-CHANGELOG.rst}"

if [[ -f "${CHANGELOG_PATH}" ]]; then
  # Look for the first line starting with "v" followed by a version number (X, X.Y, or X.Y.Z)
  LAST_TAG=$(awk '/^v[0-9]+(\.[0-9]+)?(\.[0-9]+)?([[:space:]]+.*)?$/{
    # Extract the version number from the line (including the "v")
    match($0, /v[0-9]+(\.[0-9]+)?(\.[0-9]+)?/)
    if (RSTART > 0) {
      version = substr($0, RSTART, RLENGTH)
      print version
      exit
    }
  }' "${CHANGELOG_PATH}" || true)
  echo "last_tag=${LAST_TAG:-v0.0.0}" >> "${GITHUB_OUTPUT}"
else
  echo "last_tag=v0.0.0" >> "${GITHUB_OUTPUT}"
fi
