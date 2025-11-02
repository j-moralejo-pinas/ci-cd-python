#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: new tag (e.g., v1.2.3 or 1.2.3)
# 2: last tag (e.g., v1.2.2 or empty)

NEW_TAG_INPUT="${1:-}"
LAST_TAG_INPUT="${2:-}"

new="${NEW_TAG_INPUT#v}"
last="${LAST_TAG_INPUT#v}"

if [[ -z "${last}" ]]; then
  echo "result=true" >> "${GITHUB_OUTPUT}"
  exit 0
fi

IFS=. read -r nx ny nz <<< "${new}"
IFS=. read -r lx ly lz <<< "${last}"

result=false
if [[ "${nx:-0}" -gt "${lx:-0}" ]]; then
  result=true
elif [[ "${nx:-0}" -eq "${lx:-0}" && "${ny:-0}" -gt "${ly:-0}" ]]; then
  result=true
elif [[ "${nx:-0}" -eq "${lx:-0}" && "${ny:-0}" -eq "${ly:-0}" && "${nz:-0}" -gt "${lz:-0}" ]]; then
  result=true
fi

echo "result=${result}" >> "${GITHUB_OUTPUT}"
