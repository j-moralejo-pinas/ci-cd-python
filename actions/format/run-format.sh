#!/usr/bin/env bash
set -euo pipefail

# Upgrade pip and install PDM
python -m pip install --upgrade pip
pip install pdm

# Install formatting dependencies
pdm install --no-self -G format

# Run pyupgrade across src; don't fail if files were changed
if compgen -G "src/*.py" > /dev/null || find src -type f -name "*.py" | grep -q .; then
  find src -name "*.py" -exec pdm run pyupgrade --py38-plus --exit-zero-even-if-changed {} +
fi

# Run Ruff auto-fix; don't fail the job if it returns non-zero
pdm run ruff check . --fix || true

# Run Ruff format
pdm run ruff format .

# Run docformatter: exit code 0 = ok, 3 = changes made; others should fail
set +e
pdm run docformatter -i -r src/
code=$?
set -e
if [[ "$code" != "0" && "$code" != "3" ]]; then
  echo "::error::docformatter failed with exit code $code"
  exit "$code"
fi
