#!/usr/bin/env bash
set -e
echo "🧩 Starting Docs-as-Code Validation..."

mkdir -p artifacts

# Markdown
echo "🧾 Running Markdown Linter..."
markdownlint-cli2 "**/*.md" "#node_modules" "#.git" "#.github" "#artifacts" "#scripts" "#.vale" -config .markdownlint-cli2.jsonc \
  --fix false \
  2>&1 | tee artifacts/markdownlint.log

# Formatting
# echo "🎨 Checking Markdown formatting..."
# mdformat --check . 2>&1 | tee -a artifacts/mdformat.log || true

# AsciiDoc
echo "🏗️ Running AsciiDoctor Doctest..."
find . -type f -name "*.adoc" -not -path "./.git/*" -not -path "./.github/*" | \
  while read file; do
    echo "📄 Checking $file..."
    if asciidoctor \
      --base-dir . \
      --failure-level ERROR \
      --trace \
      -o /dev/null "$file" 2>>artifacts/asciidoc.log; then
      echo "✅ $file"
    else
      echo "❌ Syntax error in $file (see log)" | tee -a artifacts/asciidoc.log
    fi
  done

if grep -q "ERROR:" artifacts/asciidoc.log; then
  echo "⚠️ Found AsciiDoc errors"
  exit 1
else
  echo "✅ All AsciiDoc files are valid"
fi

# Если в логе есть ERROR — считаем, что проверка провалена
if grep -q "ERROR:" artifacts/asciidoc.log; then
  echo "⚠️ Found AsciiDoc errors"
  exit_code=1
else
  echo "✅ All AsciiDoc files are valid"
  exit_code=0
fi


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

# Конвертируем ошибки в GitHub warnings
grep -hE "^[^ ]+:[0-9]+:" artifacts/markdownlint.log | while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  ln=$(echo "$line" | cut -d: -f2)
  msg=$(echo "$line" | cut -d: -f3- | sed 's/"/\\"/g')
  echo "::warning file=${file},line=${ln}::${msg}"
done