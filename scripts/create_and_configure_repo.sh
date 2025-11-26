#!/usr/bin/env bash
# Full repository creation and configuration script
# Combines create_repo.sh and local-configure-repo.sh into one workflow
#
# Usage: create_and_configure_repo.sh <name> "description" <python_version> <workflow> \
#        [python_version_max] [repo_topics] [public|private]
#
# Required arguments:
#   <name>                 Repository name
#   "description"          Repository description
#   <python_version>       Minimum Python version (e.g., "3.11")
#   <workflow>             Workflow type (see local-configure-repo.sh for available options)
#
# Optional arguments:
#   [python_version_max]   Maximum Python version (e.g., "3.12")
#   [repo_topics]          Repository topics (comma-separated)
#   [public|private]       Repository visibility (default: private)

set -e

# ============================================
# Parse arguments
# ============================================

REPO_NAME="${1:?Error: Repository name is required}"
DESCRIPTION="${2:?Error: Repository description is required}"
PYTHON_VERSION="${3:?Error: Python version is required}"
WORKFLOW="${4:?Error: Workflow is required}"
PYTHON_VERSION_MAX="${5:-}"
REPO_TOPICS="${6:-}"
VISIBILITY="${7:-private}"

# Normalize visibility
if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
    echo "Invalid visibility '$VISIBILITY'. Use 'public' or 'private'."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="$HOME/projects"

echo "=========================================="
echo "Full Repository Setup Script"
echo "=========================================="
echo "Repository: $REPO_NAME"
echo "Description: $DESCRIPTION"
echo "Visibility: $VISIBILITY"
echo "Python version: $PYTHON_VERSION"
echo "Python max version: ${PYTHON_VERSION_MAX:-'Not specified'}"
echo "Topics: ${REPO_TOPICS:-'Not specified'}"
echo "Workflow: $WORKFLOW"
echo "=========================================="
echo ""

# ============================================
# Step 1: Create repository from template
# ============================================

echo "Step 1: Creating GitHub repository from template..."
bash "$SCRIPT_DIR/create_repo.sh" "$REPO_NAME" "$DESCRIPTION" "$VISIBILITY"

echo ""
echo "✓ Repository created successfully"
echo ""

# ============================================
# Step 2: Configure repository
# ============================================

REPO_PATH="$PROJECTS_DIR/$REPO_NAME"

if [ ! -d "$REPO_PATH" ]; then
    echo "Error: Repository directory not found at $REPO_PATH"
    exit 1
fi

echo "Step 2: Configuring repository..."
cd "$REPO_PATH"

# Check if local-configure-repo.sh exists
if [ ! -f "scripts/init/local-configure-repo.sh" ]; then
    echo "Error: local-configure-repo.sh not found at scripts/init/local-configure-repo.sh"
    exit 1
fi

# Run the configuration script
bash scripts/init/local-configure-repo.sh \
    "$PYTHON_VERSION" \
    "$PYTHON_VERSION_MAX" \
    "$REPO_TOPICS" \
    "$WORKFLOW"

echo ""
echo "=========================================="
echo "✓ Repository setup completed successfully!"
echo "=========================================="
echo "Repository location: $REPO_PATH"
echo ""
