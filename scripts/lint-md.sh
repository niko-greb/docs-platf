#!/usr/bin/env bash
set +e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "🧾 Running Markdown Linter..."
# ✅ вызываем инструмент напрямую
markdownlint-cli2 "**/*.md" "#node_modules" --format markdown \
  | tee "$OUT_DIR/markdownlint.log"

echo "📋 Markdownlint results saved to artifacts/markdownlint.log"
