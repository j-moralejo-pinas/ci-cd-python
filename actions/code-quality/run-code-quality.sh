#!/usr/bin/env bash

# Argument 1: stop-on-failure (true|false, default: true)
STOP_ON_FAILURE="${1:-true}"

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
pdm lock --group code-quality
pdm install --no-self -G code-quality

# Remove 'extends' entry from pyrightconfig.json to avoid missing local config errors
if [[ -f "pyrightconfig.json" ]]; then
    python -c "
import json
with open('pyrightconfig.json', 'r') as f:
    config = json.load(f)
config.pop('extends', None)
with open('pyrightconfig.json', 'w') as f:
    json.dump(config, f, indent=2)
"
fi

# Run pydoclint, ruff, and pyright using the PDM environment
pdm run pydoclint src/
pdm run ruff check .
pdm run pyright
