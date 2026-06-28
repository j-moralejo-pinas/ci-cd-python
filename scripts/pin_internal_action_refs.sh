#!/usr/bin/env bash
set -euo pipefail

REF="${1:?Usage: scripts/pin_internal_action_refs.sh <main|vN>}"

if [[ ! "$REF" =~ ^(main|v[0-9]+)$ ]]; then
    echo "Error: ref must be 'main' or a major release tag like 'v1'."
    exit 1
fi

perl -0pi -e \
    "s#(j-moralejo-pinas/ci-cd-python/(?:actions|\\.github/workflows)/[^\\s'\\\"]+@)[^\\s'\\\"]+#\${1}$REF#g" \
    $(git ls-files '*.yml' '*.yaml')
