#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: PyPI token

PYPI_TOKEN="${1:-}"

TWINE_USERNAME=__token__ TWINE_PASSWORD="${PYPI_TOKEN}" \
  twine upload dist/* --verbose
