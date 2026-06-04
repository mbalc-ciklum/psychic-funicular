#!/usr/bin/env bash
# Run the Robocop linter (and optionally the formatter) over the suite.
#
# Usage:
#   ./lint.sh            # strict lint (fails on any finding)
#   ./lint.sh --format   # also check formatting
#   ./lint.sh --fix      # apply the formatter in place
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

case "${1:-}" in
    --fix)
        uv run robocop format
        uv run robocop check
        ;;
    --format)
        uv run robocop check
        uv run robocop format --check
        ;;
    *)
        uv run robocop check
        ;;
esac

