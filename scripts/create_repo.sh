#!/usr/bin/env bash
# Usage: newrepo <name> "description" [public|private]

set -e

TEMPLATE="python-boilerplate"
PROJECTS_DIR="$HOME/Projects"

REPO_NAME="$1"
DESCRIPTION="$2"
VISIBILITY="${3:-private}"

if [ -z "$REPO_NAME" ]; then
    echo "Usage: newrepo <name> \"description\" [public|private]"
    exit 1
fi

# Normalize visibility
if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
    echo "Invalid visibility '$VISIBILITY'. Use 'public' or 'private'."
    exit 1
fi

mkdir -p "$PROJECTS_DIR"

echo "Creating GitHub repository '$REPO_NAME' from template '$TEMPLATE' ($VISIBILITY)..."
gh repo create "$REPO_NAME" \
    --template "$TEMPLATE" \
    --description "$DESCRIPTION" \
    --$VISIBILITY \
    --clone "$PROJECTS_DIR/$REPO_NAME"

echo "Repository created and cloned to $PROJECTS_DIR/$REPO_NAME"
cd "$PROJECTS_DIR/$REPO_NAME"
code .
