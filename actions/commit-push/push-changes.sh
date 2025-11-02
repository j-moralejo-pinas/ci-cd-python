#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Personal Access Token (PAT)
# 2: Repo (owner/repo)
# 3: Branch name

PAT="${1:-}"
REPO="${2:-}"
BRANCH="${3:-}"

if [[ -z "${PAT}" ]]; then
  echo "PAT not provided, skipping push." >&2
  exit 0
fi

git config --unset-all http.https://github.com/.extraheader || true
git config --unset credential.helper || true

git remote set-url origin "https://${PAT}@github.com/${REPO}.git"
git push origin "HEAD:${BRANCH}"
echo "did_push=true" >> "${GITHUB_OUTPUT}"
