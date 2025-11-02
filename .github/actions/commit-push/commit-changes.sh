#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Base commit message
# 2: Labels (comma or space separated)

BASE_MESSAGE="${1:-}"
INPUT_LABELS="${2:-}"

if git diff --quiet; then
  echo "has_changes=false" >> "${GITHUB_OUTPUT}"
  exit 0
fi

# Git identity is expected to be configured by a prior step/action

# Extract labels from previous commit (current HEAD before this new commit)
prev_labels_file="$(mktemp)"
if git log -1 --pretty=%B | grep -o -E '\[[^][]+\]' > "${prev_labels_file}" 2>/dev/null; then
  :
else
  : > "${prev_labels_file}"
fi

# Build a combined label list: previous labels + input labels
all_labels_file="$(mktemp)"
# Add previous labels (strip brackets)
while IFS= read -r token; do
  lbl="${token#[}"
  lbl="${lbl%]}"
  if [[ -n "${lbl}" ]]; then
    printf '%s\n' "${lbl}" >> "${all_labels_file}"
  fi
done < "${prev_labels_file}"

# Add labels provided via inputs (comma and/or space separated)
tmp=${INPUT_LABELS//,/ }
for lbl in ${tmp}; do
  if [[ -n "${lbl}" ]]; then
    printf '%s\n' "${lbl}" >> "${all_labels_file}"
  fi
done

# De-duplicate while preserving order of first occurrence
mapfile -t uniq_labels < <(awk 'NF{ if (!seen[$0]++) print $0 }' "${all_labels_file}")

# Build bracketed labels string
formatted_labels=""
for lbl in "${uniq_labels[@]}"; do
  if [[ -n "${lbl}" ]]; then
    formatted_labels+=" [${lbl}]"
  fi
done

# Final commit message
final_msg="${BASE_MESSAGE}${formatted_labels}"

git commit -am "${final_msg}"
echo "has_changes=true" >> "${GITHUB_OUTPUT}"
