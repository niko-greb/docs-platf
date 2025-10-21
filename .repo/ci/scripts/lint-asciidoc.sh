#!/usr/bin/env bash
set +e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/artifacts"
mkdir -p "$OUT_DIR"

echo "🏗️ Running AsciiDoctor Doctest..."
FILES=$(find . -type f -name "*.adoc" | wc -l)
if [ "$FILES" -eq 0 ]; then
  echo "⚠️ No AsciiDoc files found" | tee "$OUT_DIR/asciidoc.log"
  exit 0
fi

find . -type f -name "*.adoc" -print0 | xargs -0 -n1 asciidoctor-doctest 2>&1 \
  | tee "$OUT_DIR/asciidoc.log"
echo "📋 AsciiDoc results saved to artifacts/asciidoc.log"
