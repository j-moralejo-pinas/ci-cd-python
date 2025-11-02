#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: new tag (vX.Y.Z)
# 2: base branch name
# 3: merge commit sha (may be empty)

NEW_TAG="${1:-}"
BASE_BRANCH="${2:-}"
MERGE_SHA="${3:-}"
PAT="${4:-}"
REPO="${5:-}"

if git rev-parse -q --verify "refs/tags/${NEW_TAG}" >/dev/null; then
  echo "Tag ${NEW_TAG} already exists" >&2
  exit 1
fi

if [[ -z "${MERGE_SHA}" ]] || ! git cat-file -e "${MERGE_SHA}^{commit}" 2>/dev/null; then
  echo "merge_commit_sha not available, fallback to latest on base branch"
  git fetch origin "${BASE_BRANCH}":"refs/remotes/origin/${BASE_BRANCH}"
  MERGE_SHA="$(git rev-parse "origin/${BASE_BRANCH}")"
fi

echo "Tagging ${MERGE_SHA} with ${NEW_TAG}"
git tag -a "${NEW_TAG}" "${MERGE_SHA}" -m "chore(release): ${NEW_TAG}"

git config --unset-all http.https://github.com/.extraheader || true
git config --unset credential.helper || true

git remote set-url origin "https://${PAT}@github.com/${REPO}.git"

git push origin "${NEW_TAG}"
