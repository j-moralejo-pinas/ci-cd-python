#!/usr/bin/env bash

# Read configuration
STOP_ON_FAILURE="${STOP_ON_FAILURE:-true}"

# Set bash options based on stop-on-failure setting
if [[ "${STOP_ON_FAILURE}" == "true" ]]; then
    set -euo pipefail  # Stop on first failure (original behavior)
else
    set -uo pipefail   # Continue on failures, but still catch undefined vars and pipe failures
fi

# Upgrade pip and install PDM
python -m pip install --upgrade pip
pip install pdm

# Install code-quality dependencies
pdm install --no-self -G code-quality -G test

# Run pydoclint, ruff, and pyright using the PDM environment
pdm run pydoclint src/
pdm run ruff check .
pdm run pyright
