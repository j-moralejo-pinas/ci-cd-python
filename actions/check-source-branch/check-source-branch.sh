#!/usr/bin/env bash
set -euo pipefail

# Arguments
# 1: Source branch name
# 2: Comma-separated exact branch names allowed
# 3: Comma-separated allowed branch prefixes

SOURCE_BRANCH="${1:-}"
ALLOWED_BRANCHES_RAW="${2:-}"
ALLOWED_PREFIXES_RAW="${3:-}"

echo "Source branch: ${SOURCE_BRANCH}"

# Remove spaces to avoid whitespace issues
EXACT_RAW_NO_WS="$(echo "${ALLOWED_BRANCHES_RAW}" | tr -d ' ' || true)"
PREFIX_RAW_NO_WS="$(echo "${ALLOWED_PREFIXES_RAW}" | tr -d ' ' || true)"

# Split CSVs into arrays
IFS=',' read -r -a EXACT <<< "${EXACT_RAW_NO_WS}"
IFS=',' read -r -a PREFIXES <<< "${PREFIX_RAW_NO_WS}"

ALLOWED=false

# Check exact matches
for b in "${EXACT[@]}"; do
  if [[ -n "${b}" && "${SOURCE_BRANCH}" == "${b}" ]]; then
    ALLOWED=true
    break
  fi
done

# Check prefixes if not allowed yet
if [[ "${ALLOWED}" == false ]]; then
  for p in "${PREFIXES[@]}"; do
    if [[ -n "${p}" && "${SOURCE_BRANCH}" == "${p}"* ]]; then
      ALLOWED=true
      break
    fi
  done
fi

if [[ "${ALLOWED}" == false ]]; then
  echo "❌ Branch '${SOURCE_BRANCH}' is not allowed."
  echo "   Allowed exact branches: '${EXACT_RAW_NO_WS}'"
  echo "   Allowed prefixes: '${PREFIX_RAW_NO_WS}'"
  exit 1
fi

exit 0
