#!/usr/bin/env bash
set -euo pipefail

# Upgrade pip and install PDM
python -m pip install --upgrade pip
pip install pdm

# Install code-quality dependencies
pdm install --no-self -G code-quality -G test

# Run pydoclint, ruff, and pyright using the PDM environment
pdm run pydoclint src/
pdm run ruff check .
pdm run pyright
