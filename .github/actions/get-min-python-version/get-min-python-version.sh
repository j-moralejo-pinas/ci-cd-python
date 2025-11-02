#!/bin/bash
set -euo pipefail

# Default pyproject.toml path
PYPROJECT_PATH="${1:-pyproject.toml}"

# Check if pyproject.toml exists
if [[ ! -f "$PYPROJECT_PATH" ]]; then
    echo "Error: pyproject.toml not found at path: $PYPROJECT_PATH" >&2
    exit 1
fi

# Function to extract Python version from various formats
extract_min_python_version() {
    local pyproject_file="$1"

    # Try different patterns to find Python version requirement
    # Look for requires-python first (PEP 621)
    if grep -q "requires-python" "$pyproject_file"; then
        # Extract requires-python value
        requires_python=$(grep "requires-python" "$pyproject_file" | head -1)
        echo "Found requires-python: $requires_python" >&2

        # Extract version from requires-python
        # Handle formats like: ">=3.8", ">=3.8.0", "~=3.8", "==3.9.2"
        version=$(echo "$requires_python" | sed -n 's/.*[>~=]\+\s*\([0-9]\+\.[0-9]\+\(\.[0-9]\+\)*\).*/\1/p')

        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    # Fall back to checking classifiers for Programming Language :: Python :: versions
    if grep -q "Programming Language :: Python ::" "$pyproject_file"; then
        # Extract all Python version classifiers and find the minimum
        versions=$(grep "Programming Language :: Python ::" "$pyproject_file" | \
                  sed -n 's/.*Python :: \([0-9]\+\.[0-9]\+\).*/\1/p' | \
                  sort -V | head -1)

        if [[ -n "$versions" ]]; then
            echo "$versions"
            return 0
        fi
    fi

    # Check for python_requires in setup() call (less common in pyproject.toml but possible)
    if grep -q "python_requires" "$pyproject_file"; then
        version=$(grep "python_requires" "$pyproject_file" | \
                 sed -n 's/.*[>~=]\+\s*\([0-9]\+\.[0-9]\+\(\.[0-9]\+\)*\).*/\1/p' | head -1)

        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    # If no version found, return empty
    echo ""
    return 1
}

# Extract the minimum Python version
echo "Analyzing pyproject.toml at: $PYPROJECT_PATH" >&2

MIN_VERSION=$(extract_min_python_version "$PYPROJECT_PATH" || echo "")

if [[ -z "$MIN_VERSION" ]]; then
    echo "Warning: Could not determine minimum Python version from $PYPROJECT_PATH" >&2
    echo "Defaulting to Python 3.8" >&2
    MIN_VERSION="3.8"
fi

echo "Detected minimum Python version: $MIN_VERSION" >&2

# Set the output for GitHub Actions (only if GITHUB_OUTPUT is set)
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "min_python_version=$MIN_VERSION" >> "$GITHUB_OUTPUT"
fi

# Also echo for visibility in logs
echo "Minimum Python version: $MIN_VERSION"