#!/usr/bin/env bash
set -euo pipefail

# Run tests with coverage
export PYTHONPATH="$(pwd)/src"
pdm run pytest --cov=src --cov-report=term-missing
