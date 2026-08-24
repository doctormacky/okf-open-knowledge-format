#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VALIDATOR="$SCRIPT_DIR/validate.py"

if command -v python3 >/dev/null 2>&1 &&
   python3 -c 'import sys, yaml; raise SystemExit(sys.version_info < (3, 10))' \
     >/dev/null 2>&1; then
  exec python3 "$VALIDATOR" "$@"
fi

if command -v uv >/dev/null 2>&1; then
  exec uv run --quiet "$VALIDATOR" "$@"
fi

echo "ERROR: OKF validation requires Python 3 with PyYAML, or uv." >&2
echo "Install uv (recommended) or run: python3 -m pip install PyYAML" >&2
exit 2
