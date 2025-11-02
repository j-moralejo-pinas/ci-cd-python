#!/usr/bin/env bash
set -euo pipefail

# Upgrade pip and install PDM
python -m pip install --upgrade pip
pip install pdm

# Install test dependencies
pdm install --no-self -G test

# Run tests with coverage
export PYTHONPATH="$(pwd)/src"
pdm run pytest --cov=src --cov-report=term-missing
