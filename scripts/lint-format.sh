#!/usr/bin/env bash
set +e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "🎨 Checking Markdown formatting with mdformat..."
mdformat --check . \
  | tee "$OUT_DIR/mdformat.log"
echo "📋 mdformat results saved to artifacts/mdformat.log"
