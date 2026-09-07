#!/usr/bin/env bash
# Create an empty GitHub repository and scaffold it with Copier.
#
# Usage: create_repo.sh <name> "description" [public|private]
#        [python_min] [python_max] [topics] [workflow]

set -euo pipefail

TEMPLATE="${COPIER_TEMPLATE:-https://github.com/j-moralejo-pinas/python-boilerplate.git}"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"

REPO_NAME="${1:?Repository name is required}"
DESCRIPTION="${2:?Repository description is required}"
VISIBILITY="${3:-private}"
PYTHON_MIN="${4:-}"
PYTHON_MAX="${5:-}"
REPO_TOPICS="${6:-}"
WORKFLOW="${7:-}"
CI_CD_REPO="${CI_CD_REPO:-j-moralejo-pinas/ci-cd-python}"

if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
    echo "Invalid visibility '$VISIBILITY'. Use 'public' or 'private'." >&2
    exit 1
fi

if ! command -v gh >/dev/null; then
    echo "Error: gh CLI is required." >&2
    exit 1
fi

if command -v copier >/dev/null; then
    COPIER=(copier)
elif command -v uv >/dev/null; then
    COPIER=(uvx copier)
else
    echo "Error: install Copier or uv before creating a repository." >&2
    exit 1
fi

OWNER=$(gh api user --jq '.login')
PROJECT_PATH="$PROJECTS_DIR/$REPO_NAME"

latest_ci_cd_ref() {
    local latest_tag
    latest_tag=$(gh api "repos/$CI_CD_REPO/tags?per_page=100" --jq '.[].name' |
        grep -E '^v[0-9]+$' | sort -V | tail -n 1 || true)

    if [[ -n "$latest_tag" ]]; then
        printf '%s\n' "$latest_tag"
    else
        gh api "repos/$CI_CD_REPO/commits/main" --jq '.sha'
    fi
}

CI_CD_REF="${CI_CD_REF:-$(latest_ci_cd_ref)}"

if [[ -e "$PROJECT_PATH" ]]; then
    echo "Error: destination already exists: $PROJECT_PATH" >&2
    exit 1
fi

mkdir -p "$PROJECTS_DIR"
echo "Creating GitHub repository '$OWNER/$REPO_NAME' ($VISIBILITY)..."
gh repo create "$OWNER/$REPO_NAME" \
    --description "$DESCRIPTION" \
    --"$VISIBILITY"

echo "Cloning repository to $PROJECT_PATH..."
gh repo clone "$OWNER/$REPO_NAME" "$PROJECT_PATH"

COPIER_DATA=(
    --data "project_name=$REPO_NAME"
    --data "project_description=$DESCRIPTION"
    --data "github_owner=$OWNER"
    --data "ci_cd_ref=$CI_CD_REF"
)
COPIER_OPTIONS=()

if [[ -n "$PYTHON_MIN" && "$PYTHON_MIN" != "none" ]]; then
    COPIER_DATA+=(--data "python_min_version=$PYTHON_MIN")
fi
if [[ -n "$PYTHON_MAX" && "$PYTHON_MAX" != "none" ]]; then
    COPIER_DATA+=(--data "python_max_version=$PYTHON_MAX")
fi
if [[ -n "$REPO_TOPICS" && "$REPO_TOPICS" != "none" ]]; then
    TOPICS_JSON=$(printf '%s' "$REPO_TOPICS" | tr ', ' '\n' | awk 'NF' | jq -R -s 'split("\n") | map(select(length > 0))')
    COPIER_DATA+=(--data "repo_topics=$TOPICS_JSON")
fi
if [[ -n "$WORKFLOW" && "$WORKFLOW" != "none" ]]; then
    COPIER_DATA+=(--data "workflow=$WORKFLOW")
fi

if [[ -n "$PYTHON_MIN" && "$PYTHON_MIN" != "none" && -n "$WORKFLOW" && "$WORKFLOW" != "none" ]]; then
    COPIER_DATA+=(
        --data "author_name=Javier Moralejo Piñas"
        --data "author_email=j.moralejo.pinas@gmail.com"
    )
    COPIER_OPTIONS+=(--defaults)
fi

echo "Scaffolding with Copier..."
"${COPIER[@]}" copy "${COPIER_OPTIONS[@]}" "${COPIER_DATA[@]}" "$TEMPLATE" "$PROJECT_PATH"

CURRENT_BRANCH=$(git -C "$PROJECT_PATH" branch --show-current)
if [[ -z "$CURRENT_BRANCH" ]]; then
    git -C "$PROJECT_PATH" checkout -b main
elif [[ "$CURRENT_BRANCH" != "main" ]]; then
    git -C "$PROJECT_PATH" branch -M main
fi

git -C "$PROJECT_PATH" add -A
git -C "$PROJECT_PATH" commit -m "chore: scaffold project with Copier"
git -C "$PROJECT_PATH" push -u origin HEAD

echo "Repository created at $PROJECT_PATH"
