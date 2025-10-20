#!/usr/bin/env bash
set -e
echo "🧩 Starting Docs-as-Code Validation..."

mkdir -p artifacts

# Markdown
echo "🧾 Running Markdown Linter..."
markdownlint-cli2 "**/*.md" "#node_modules" "#.git" "#.github" "#artifacts" "#scripts" "#.vale" --format markdown \
  | tee artifacts/markdownlint.log || true

# Formatting
echo "🎨 Checking Markdown formatting..."
mdformat --check . 2>&1 | tee -a artifacts/mdformat.log || true

# AsciiDoc
echo "🏗️ Running AsciiDoctor Doctest..."
find . -type f -name "*.adoc" -not -path "./.git/*" -not -path "./.github/*" \
  -print0 | xargs -0 -n1 asciidoctor-doctest 2>&1 | tee -a artifacts/asciidoc.log || true

# OpenAPI
echo "🔍 Running Spectral..."
find . -type f \( -name "*.yaml" -o -name "*.yml" \) -not -path "./.git/*" -not -path "./.github/*" \
  -print0 | xargs -0 -n1 spectral lint --quiet 2>&1 | tee -a artifacts/openapi.log || true

# Vale
echo "✍️ Running Vale..."
if [ ! -d ".vale/styles" ]; then
  echo "⚙️ Syncing Vale styles..."
  vale sync
fi
vale --output=line --minAlertLevel=warning . 2>&1 | tee -a artifacts/vale.log || true

echo "✅ All checks completed. Review artifacts/*.log for results."
