#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: version (X.Y.Z)
# 2: TestPyPI token

VERSION="${1:-}"
TEST_PYPI_TOKEN="${2:-}"

# Detect package name from pyproject.toml
if [[ ! -f pyproject.toml ]]; then
  echo "::error::pyproject.toml not found at repository root" >&2
  exit 1
fi

NAME="$(awk 'BEGIN{inproj=0} /^\[project\]/{inproj=1; next} /^\[/{inproj=0} inproj && match($0,/^\s*name\s*=\s*\"(.*)\"\s*$/,m){print m[1]; exit}' pyproject.toml)"
if [[ -z "${NAME}" ]]; then
  echo "::error::Could not determine [project].name from pyproject.toml" >&2
  exit 1
fi
IMPORT_NAME="$(printf '%s' "${NAME}" | tr '-' '_')"

echo "Detected distribution name: ${NAME}"
echo "Detected import name: ${IMPORT_NAME}"

# Export to GITHUB_ENV for subsequent steps in composite action
if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "PACKAGE_NAME=${NAME}"
    echo "IMPORT_NAME=${IMPORT_NAME}"
  } >> "${GITHUB_ENV}"
fi

# Install build and twine
python -m pip install --upgrade pip
python -m pip install build twine

# Build distributions
python -m build

twine check dist/*

# Upload to TestPyPI
TWINE_USERNAME=__token__ TWINE_PASSWORD="${TEST_PYPI_TOKEN}" \
  twine upload --repository-url https://test.pypi.org/legacy/ dist/* --verbose

# Wait a bit for indexing
sleep 60

# Create clean venv and install from TestPyPI
python -m venv .venv_test
. .venv_test/bin/activate
python -m pip install --upgrade pip
pip install --index-url https://test.pypi.org/simple --extra-index-url https://pypi.org/simple \
  "${NAME}==${VERSION}"
