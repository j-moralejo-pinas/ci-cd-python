#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Personal Access Token (PAT)
# 2: Repo (owner/repo)
# 3: Branch name

PAT="${1:-}"
REPO="${2:-}"
BRANCH="${3:-}"

echo "=== DEBUG INFO: push-changes.sh ==="
echo "Repo: ${REPO}"
echo "Branch: ${BRANCH}"
echo "Current directory: $(pwd)"
echo "Git version: $(git --version)"
echo "Current commit: $(git rev-parse --short HEAD)"
echo "Remote before modification:"
git remote -v || echo "No remotes found."

if [[ -z "${PAT}" ]]; then
  echo "PAT not provided, skipping push." >&2
  echo "did_push=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

# Unset default credentials to avoid conflicts
echo "Clearing existing git credentials..."
git config --unset-all http.https://github.com/.extraheader || true
git config --unset credential.helper || true

# Configure new remote
echo "Setting new remote URL for origin..."
git remote set-url origin "https://${PAT}@github.com/${REPO}.git"

echo "Remote after modification:"
git remote -v

# Show what’s staged and untracked before pushing
echo "Status before push:"
git status

# Show last commit message
echo "Last commit message:"
git log -1 --pretty=oneline

# Try to push
echo "Attempting to push HEAD to ${BRANCH}..."
set -x
git push origin "HEAD:${BRANCH}"
set +x

# Confirm the result
if git ls-remote origin "${BRANCH}" &>/dev/null; then
  echo "✅ Push successful!"
  echo "did_push=true" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "❌ Push failed or branch not found remotely."
  echo "did_push=false" >> "${GITHUB_OUTPUT:-/dev/null}"
fi

echo "=== END DEBUG INFO ==="
