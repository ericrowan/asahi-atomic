#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
#  PROJECT CORTEX: LOCAL LINTER
# ──────────────────────────────────────────────────────────────────────────────
# Usage: bash scripts/lint.sh
# Goal: Scans all scripts for syntax errors before pushing to GitHub.

set -e

echo "🔍 Scanning scripts with ShellCheck..."

if ! command -v shellcheck &> /dev/null; then
    echo "⚠️ ShellCheck not found. Install it to run local checks."
    echo "   Host: sudo rpm-ostree install shellcheck"
    echo "   Toolbox: sudo dnf install shellcheck"
    exit 1
fi

# Find all .sh files in scripts/ and config/modules/ and check them
find scripts config/modules -name "*.sh" -print0 | xargs -0 shellcheck -x

echo "✅ All scripts passed."
