#!/usr/bin/env bash
set +e  # не прерываем выполнение при ошибках (warnings mode)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "🧾 Running Markdown Linter..."
docker run --rm -v "$ROOT":/work -w /work docs-cli:local bash -lc '
  set +e
  echo "📂 Files in project:"
  find docs -type f -name "*.md"
  echo ""
  echo "🚀 Linting..."
  markdownlint-cli2 "**/*.md" "#node_modules" --format markdown
' | tee "$OUT_DIR/markdownlint.log"

echo ""
echo "📋 Markdownlint results saved to artifacts/markdownlint.log"
