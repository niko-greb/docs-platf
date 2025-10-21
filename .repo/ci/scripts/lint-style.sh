#!/usr/bin/env bash
set +e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "✍️ Running Vale Style Checker..."
FILES=$(find . -type f \( -name "*.md" -o -name "*.adoc" \) | wc -l)
if [ "$FILES" -eq 0 ]; then
  echo "⚠️ No documentation files found" | tee "$OUT_DIR/vale.log"
  exit 0
fi

vale --output=line --minAlertLevel=warning . 2>&1 | tee "$OUT_DIR/vale.log"
echo "📋 Vale results saved to artifacts/vale.log"
