#!/usr/bin/env bash
# Create a GitHub repository, scaffold it with Copier, and apply repository settings.
#
# Usage: create_and_configure_repo.sh <name> "description" <python_min> <workflow> \
#        [public|private] [python_max] [repo_topics]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

REPO_NAME="${1:?Repository name is required}"
DESCRIPTION="${2:?Repository description is required}"
PYTHON_MIN="${3:?Minimum Python version is required}"
WORKFLOW="${4:?Workflow is required}"
VISIBILITY="${5:-private}"
PYTHON_MAX="${6:-}"
REPO_TOPICS="${7:-}"

[[ "$PYTHON_MAX" == "none" ]] && PYTHON_MAX=""
[[ "$REPO_TOPICS" == "none" ]] && REPO_TOPICS=""

for command in direnv nix gh; do
    if ! command -v "$command" >/dev/null; then
        echo "Error: $command is not installed or not in PATH." >&2
        exit 1
    fi
done

if ! gh auth status >/dev/null 2>&1; then
    echo "Error: gh CLI is not authenticated. Run 'gh auth login' first." >&2
    exit 1
fi

if ! git config user.name >/dev/null; then
    echo "Error: git user.name is not configured." >&2
    exit 1
fi

if ! git config user.email >/dev/null; then
    echo "Error: git user.email is not configured." >&2
    exit 1
fi

bash "$SCRIPT_DIR/create_repo.sh" \
    "$REPO_NAME" \
    "$DESCRIPTION" \
    "$VISIBILITY" \
    "$PYTHON_MIN" \
    "$PYTHON_MAX" \
    "$REPO_TOPICS" \
    "$WORKFLOW"

OWNER=$(gh api user --jq '.login')
REPO_SLUG="$OWNER/$REPO_NAME"
REPO_PATH="$PROJECTS_DIR/$REPO_NAME"

echo "Applying GitHub repository settings..."
bash "$SCRIPT_DIR/configure_repo.sh" "$REPO_SLUG" "$WORKFLOW" "$REPO_TOPICS"

if [[ "$WORKFLOW" == "gitflow" ]]; then
    echo "Creating dev branch..."
    git -C "$REPO_PATH" checkout -b dev
    git -C "$REPO_PATH" push -u origin dev
    git -C "$REPO_PATH" checkout main
fi

echo "Setting up the local development environment..."
(
    cd "$REPO_PATH"
    direnv allow .
    eval "$(direnv export bash)"
    ./setup-dev.sh
)

echo "Repository setup completed: $REPO_PATH"
code "$REPO_PATH"
