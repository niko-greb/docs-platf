#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p artifacts

echo "🔍 Running Spectral..."

# Ищем только OpenAPI-файлы
find "$ROOT/docs" -type f \( -name "*.yaml" -o -name "*.yml" \) \
  ! -path "*/.git/*" \
  ! -path "*/.github/*" \
  ! -path "*/node_modules/*" \
  ! -path "*/artifacts/*" \
  ! -path "*/.vale/*" \
  ! -path "*/scripts/*" \
  -print0 | xargs -0 -n1 spectral lint --format stylish || true
