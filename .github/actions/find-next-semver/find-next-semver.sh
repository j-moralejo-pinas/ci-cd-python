#!/usr/bin/env bash
set -euo pipefail

# Reads HEAD_BRANCH from environment if provided.

# 1) Fetch tags
git fetch --tags --force --prune

# 2) Determine latest tag vX.Y.Z
LATEST="$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-version:refname | head -n1)"
if [[ -z "${LATEST}" ]]; then LATEST="v0.0.0"; fi
echo "latest=${LATEST}" >> "${GITHUB_OUTPUT}"

# 3) Compute next version based on HEAD_BRANCH
if [[ ! "${LATEST}" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Malformed latest tag" >&2
  exit 1
fi

X="${BASH_REMATCH[1]}"; Y="${BASH_REMATCH[2]}"; Z="${BASH_REMATCH[3]}"

HEAD_BRANCH="${HEAD_BRANCH:-}"
if [[ "${HEAD_BRANCH}" =~ ^major/ ]]; then
  X=$((X+1)); Y=0; Z=0; REASON="major branch bump"
elif [[ "${HEAD_BRANCH}" =~ ^hotfix/ ]]; then
  Z=$((Z+1)); REASON="hotfix patch bump"
else
  Y=$((Y+1)); Z=0; REASON="regular release minor bump"
fi

NEW_TAG="v${X}.${Y}.${Z}"
echo "new_tag=${NEW_TAG}" >> "${GITHUB_OUTPUT}"
echo "${REASON}"

# 4) Derive version without leading v
echo "version=${NEW_TAG#v}" >> "${GITHUB_OUTPUT}"
