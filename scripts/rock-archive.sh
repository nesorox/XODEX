#!/usr/bin/env bash
set -euo pipefail

# rock() — enforce invariant on immutable zone
if git diff --quiet --exit-code -- archive/ 2>/dev/null; then
    echo "✓ archive/ clean — invariant holds"
else
    echo "⚠ DEVIATION DETECTED in immutable archive!"
    echo "Reverting via rock()..."
    git checkout -- archive/
    git restore --staged archive/ 2>/dev/null || true
    echo "Archive restored to canonical state."
fi
