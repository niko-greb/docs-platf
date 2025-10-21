#!/usr/bin/env bash
# ─────────────────────────────────────────────
# 🧩 Docs-as-Code Validator (Soft Mode)
# Проверяет Markdown, AsciiDoc, OpenAPI и Vale
# ─────────────────────────────────────────────

set -euo pipefail
SOFT_MODE=true  # 🔸 "Мягкий режим" — не падает при ошибках
echo "🧩 Starting Docs-as-Code Validation (Soft Mode: ${SOFT_MODE})..."

mkdir -p artifacts
exit_code=0

# ─────────────────────────────────────────────
# 1️⃣ Markdown Linter
# ─────────────────────────────────────────────
echo "🧾 Running Markdown Linter..."
if find . -type f -name "*.md" -not -path "./.git/*" | grep -q .; then
  markdownlint-cli2 "**/*.md" \
    "#node_modules" "#.git" "#.github" "#artifacts" "#scripts" "#.vale" \
    --config .markdownlint-cli2.jsonc \
    --fix false \
    2>&1 | tee artifacts/markdownlint.log || true
else
  echo "⚠️ No Markdown files found." | tee artifacts/markdownlint.log
fi

# ─────────────────────────────────────────────
# 2️⃣ Markdown Formatting (mdformat)
# ─────────────────────────────────────────────
echo "🎨 Checking Markdown formatting..."
if command -v mdformat >/dev/null 2>&1; then
  mdformat --check . 2>&1 | tee -a artifacts/mdformat.log || true
else
  echo "⚠️ mdformat not installed. Skipping format check." | tee artifacts/mdformat.log
fi

# ─────────────────────────────────────────────
# 3️⃣ AsciiDoc Validation
# ─────────────────────────────────────────────
echo "🏗️ Running AsciiDoctor Doctest..."
ASCIIDOC_FILES=$(find . -type f -name "*.adoc" -not -path "./.git/*" -not -path "./.github/*")
if [ -z "$ASCIIDOC_FILES" ]; then
  echo "⚠️ No AsciiDoc files found." | tee artifacts/asciidoc.log
else
  for file in $ASCIIDOC_FILES; do
    echo "📄 Testing $file..."
    if ruby /work/run_doctest.rb "$file" >> artifacts/asciidoc.log 2>&1; then
      echo "✅ $file passed"
    else
      echo "❌ $file failed" | tee -a artifacts/asciidoc.log
      exit_code=1
    fi
  done
fi

# ─────────────────────────────────────────────
# 4️⃣ OpenAPI Validation (Spectral)
# ─────────────────────────────────────────────
echo "🔍 Running Spectral..."
OPENAPI_FILES=$(find . -type f \( -name "*.yaml" -o -name "*.yml" \) -not -path "./.git/*" -not -path "./.github/*")
if [ -z "$OPENAPI_FILES" ]; then
  echo "⚠️ No OpenAPI YAML files found." | tee artifacts/openapi.log
else
  echo "$OPENAPI_FILES" | xargs -r -n1 spectral lint --quiet 2>&1 | tee artifacts/openapi.log || true
fi

# ─────────────────────────────────────────────
# 5️⃣ Vale Style Checker
# ─────────────────────────────────────────────
echo "✍️ Running Vale..."
if [ ! -d ".vale/styles" ]; then
  echo "⚙️ Syncing Vale styles..."
  vale sync || true
fi

if command -v vale >/dev/null 2>&1; then
  vale --output=line --minAlertLevel=warning . 2>&1 | tee artifacts/vale.log || true
else
  echo "⚠️ Vale not found. Skipping style check." | tee artifacts/vale.log
fi

# ─────────────────────────────────────────────
# 6️⃣ GitHub Warnings/Errors (PR annotations)
# ─────────────────────────────────────────────
echo "📋 Generating GitHub warnings for PR..."
for log in artifacts/*.log; do
  if [ -s "$log" ]; then
    grep -hE "^[^ ]+:[0-9]+:" "$log" | while IFS= read -r line; do
      file=$(echo "$line" | cut -d: -f1)
      ln=$(echo "$line" | cut -d: -f2)
      msg=$(echo "$line" | cut -d: -f3- | sed 's/"/\\"/g')

      if echo "$msg" | grep -qi "error"; then
        echo "::error file=${file},line=${ln}::${msg}"
        exit_code=1
      else
        echo "::warning file=${file},line=${ln}::${msg}"
      fi
    done
  fi
done

# ─────────────────────────────────────────────
# 7️⃣ Резюме
# ─────────────────────────────────────────────
echo ""
if [ "$exit_code" -ne 0 ]; then
  echo "⚠️ Validation completed with issues. Check artifacts for details."
else
  echo "✅ All checks passed (Soft Mode active)."
fi

echo "📂 Logs saved in artifacts/"
echo "🪶 Review artifacts/*.log for detailed results."

# ─────────────────────────────────────────────
# 8️⃣ Soft Mode Exit
# ─────────────────────────────────────────────
if [ "${SOFT_MODE}" = true ]; then
  echo "🩶 Soft mode enabled: exiting with 0 (non-blocking)."
  exit 0
else
  exit "${exit_code}"
fi
