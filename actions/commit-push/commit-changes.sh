#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Base commit message
# 2: Labels (comma or space separated)

BASE_MESSAGE="${1:-}"
INPUT_LABELS="${2:-}"

echo "=== DEBUG INFO: commit-changes.sh ==="
echo "Base commit message: '${BASE_MESSAGE}'"
echo "Input labels: '${INPUT_LABELS}'"
echo "Current directory: $(pwd)"
echo "Git version: $(git --version)"
echo "Current branch: $(git rev-parse --abbrev-ref HEAD || echo 'detached')"
echo "Current commit: $(git rev-parse --short HEAD)"
echo "Repository status before committing:"
git status --short || echo "(no git status output)"

# Check if there are any changes to commit
git add -A
if git diff --quiet; then
  echo "No changes detected — skipping commit."
  echo "has_changes=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "=== END DEBUG INFO ==="
  exit 0
fi

# Confirm that Git identity is configured
echo "Configured git user:"
git config user.name || echo "(no user.name set)"
git config user.email || echo "(no user.email set)"

# Extract labels from previous commit (if any)
prev_labels_file="$(mktemp)"
if git log -1 --pretty=%B | grep -o -E '\[[^][]+\]' > "${prev_labels_file}" 2>/dev/null; then
  echo "Previous labels found in last commit:"
  cat "${prev_labels_file}"
else
  echo "No previous labels found."
  : > "${prev_labels_file}"
fi

# Combine previous and new labels
all_labels_file="$(mktemp)"
while IFS= read -r token; do
  lbl="${token#[}"
  lbl="${lbl%]}"
  [[ -n "${lbl}" ]] && printf '%s\n' "${lbl}" >> "${all_labels_file}"
done < "${prev_labels_file}"

tmp=${INPUT_LABELS//,/ }
for lbl in ${tmp}; do
  [[ -n "${lbl}" ]] && printf '%s\n' "${lbl}" >> "${all_labels_file}"
done

# Deduplicate while preserving order
mapfile -t uniq_labels < <(awk 'NF{ if (!seen[$0]++) print $0 }' "${all_labels_file}")

# Build formatted label string
formatted_labels=""
for lbl in "${uniq_labels[@]}"; do
  [[ -n "${lbl}" ]] && formatted_labels+=" [${lbl}]"
done

# Final commit message
final_msg="${BASE_MESSAGE}${formatted_labels}"
echo "Final commit message to use: '${final_msg}'"

# Show which files are about to be committed
echo "Files that will be included in the commit:"
git diff --name-only

# Create commit
echo "Creating commit..."
set -x
git commit -m "${final_msg}"
set +x

echo "✅ Commit created successfully."
git log -1 --pretty=oneline

echo "has_changes=true" >> "${GITHUB_OUTPUT:-/dev/null}"
echo "=== END DEBUG INFO ==="
