#!/bin/bash

set -euo pipefail

BRANCH_NAME="$1"
PAT_TOKEN="$2"

# Create and push the new branch
git checkout -b "$BRANCH_NAME"
git push https://x-access-token:"${PAT_TOKEN}"@github.com/${{ github.repository }}.git "$BRANCH_NAME"

echo "Branch '$BRANCH_NAME' created and pushed successfully"
