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
echo "PWD: $(pwd)"
echo "Repo argument: ${REPO}"
echo "Branch argument: ${BRANCH}"
echo "Git version: $(git --version)"
echo "Current commit: $(git rev-parse --short HEAD 2>/dev/null || echo '(none)')"
echo "HEAD ref: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(none)')"
echo "Git dir: $(git rev-parse --git-dir 2>/dev/null || echo '(not a repo)')"
echo "Work tree: $(git rev-parse --show-toplevel 2>/dev/null || echo '(none)')"
echo

echo "--- Remote configuration BEFORE modification ---"
git remote -v || echo "(no remotes)"
echo

echo "--- Branch list ---"
git branch -a || true
echo

echo "--- Origin URL (raw) ---"
git config --get remote.origin.url || echo "(none)"
echo

if [[ -z "${PAT}" ]]; then
  echo "❌ PAT not provided — skipping push."
  echo "did_push=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

# Clear default credentials to avoid conflicts
echo "--- Clearing default GitHub credentials ---"
git config --unset-all http.https://github.com/.extraheader || true
git config --unset credential.helper || true
echo "Done."
echo

# Set remote URL with token
echo "--- Setting remote URL to use provided PAT ---"
git remote set-url origin "https://${PAT}@github.com/${REPO}.git"
git config --get remote.origin.url || echo "(remote not set)"
echo

# Confirm we are in a valid repo
echo "--- Repo status before push ---"
git status || echo "(status unavailable)"
echo

echo "--- Last 2 commits ---"
git log -2 --oneline || true
echo

echo "--- Testing remote connectivity ---"
git ls-remote origin HEAD || echo "Remote not reachable"
echo

# Attempt push
echo "--- Pushing now ---"
set -x
git push origin "HEAD:${BRANCH}" || {
  set +x
  echo "❌ Push failed with exit code $?"
  echo "Current user: $(git config user.name 2>/dev/null || echo '(unset)')"
  echo "Current email: $(git config user.email 2>/dev/null || echo '(unset)')"
  echo "Remote after push attempt:"
  git remote -v || true
  echo "Listing remotes in config file:"
  git config --list | grep remote || true
  echo "did_push=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 1
}
set +x

echo "✅ Push succeeded."
echo "did_push=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "=== END DEBUG INFO ==="
