#!/usr/bin/env bash
set -euo pipefail

# Arguments:
# 1: Package name (import/distribution)
# 2: Expected version string

PKG="${1:-}"
EXPECTED="${2:-}"

# Prefer local venv created in previous step if present
if [[ -x .venv_test/bin/python ]]; then
    PYBIN="./.venv_test/bin/python"
else
    PYBIN="python"
fi

"${PYBIN}" - <<'PY'
import os
import sys
import importlib
try:
    from importlib.metadata import version as meta_version
except Exception:  # pragma: no cover - Python <3.8 not used here
    meta_version = None  # type: ignore[assignment]

pkg = os.environ.get("PKG", "")
expected = os.environ.get("EXPECTED", "")

try:
    mod = importlib.import_module(pkg)
except ModuleNotFoundError as exc:
    print(f"ERROR: failed to import '{pkg}': {exc}", file=sys.stderr)
    sys.exit(1)

actual = getattr(mod, "__version__", None)
if actual is None and meta_version is not None:
    try:
        actual = meta_version(pkg)
    except Exception:
        actual = None

if actual is None:
    print(
        f"ERROR: package '{pkg}' has no __version__ and metadata lookup failed",
        file=sys.stderr,
    )
    sys.exit(1)

if str(actual) != str(expected):
    print(
        f"ERROR: version mismatch: installed={actual} expected={expected}",
        file=sys.stderr,
    )
    sys.exit(1)

print(f"Version OK: {pkg}=={expected}")
PY
