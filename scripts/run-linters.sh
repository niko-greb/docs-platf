#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "📘 Markdown Lint..."
docker run --rm -v "$ROOT":/work -w /work docs-cli:local markdownlint "**/*.md"
echo "🧾 AsciiDoc Lint..."
docker run --rm -v "$ROOT":/work -w /work docs-cli:local asciidoctor-doctest **/*.adoc
echo "🧩 API Validation..."
docker run --rm -v "$ROOT":/work -w /work docs-cli:local spectral lint api/*.yaml
echo "📖 Vale (Tone check)..."
docker run --rm -v "$ROOT":/work -w /work docs-cli:local vale .
echo "✅ All linters completed."
