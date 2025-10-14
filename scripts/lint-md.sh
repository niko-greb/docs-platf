#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
docker run --rm -v "$ROOT":/work -w /work docs-cli:local \
  markdownlint "**/*.md"
docker run --rm -v "$ROOT":/work -w /work docs-cli:local \
  mdformat --check .
