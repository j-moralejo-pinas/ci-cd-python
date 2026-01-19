#!/usr/bin/env bash
# Usage: newrepo <name> "description" [public|private]

set -e

TEMPLATE="python-boilerplate"
PROJECTS_DIR="$HOME/projects"

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
    --$VISIBILITY

echo "Waiting for repository to be available..."
for i in {1..10}; do
    if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
        echo "Repository available."
        break
    fi
    echo "Waiting for repository..."
    sleep 2
done

echo "Cloning repository to $PROJECTS_DIR/$REPO_NAME..."
gh repo clone "$REPO_NAME" "$PROJECTS_DIR/$REPO_NAME"
