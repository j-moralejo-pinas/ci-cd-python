#!/usr/bin/env bash
set -euo pipefail

# Upgrade pip and install PDM
python -m pip install --upgrade pip
pip install pdm

# Install test dependencies (--no-lock allows installation without a lockfile)
pdm lock --group test
pdm install --no-self -G test