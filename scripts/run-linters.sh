#!/usr/bin/env bash
set +e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "🧩 Starting Docs-as-Code Validation..."

bash "$ROOT/scripts/lint-md.sh"
bash "$ROOT/scripts/lint-format.sh"

echo ""
echo "✅ All checks completed (soft mode). Review artifacts/*.log for details."
