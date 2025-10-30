#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# run-linters.sh — Универсальный запуск Docs-as-Code линтеров
# Проверяет только изменённые или переданные файлы.
# Работает внутри контейнера docs-cli:ci или локально.
# ===================================================================

SOFT_MODE=true
mkdir -p artifacts
RUN_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")

echo "==============================================================="
echo "🧩 Starting Docs-as-Code Validation (Soft Mode: ${SOFT_MODE})"
echo "📅 Run: ${RUN_TIMESTAMP}"
echo "📂 Working dir: $(pwd)"
echo "==============================================================="

exit_code=0

REPO_CONFIG_DIR=".repo/config"
VALE_CONFIG="${REPO_CONFIG_DIR}/.vale.ini"
MARKDOWNLINT_CONFIG="${REPO_CONFIG_DIR}/.markdownlint-cli2.jsonc"
SPECTRAL_CONFIG="${REPO_CONFIG_DIR}/.spectral.yaml"
VALE_STYLES_DIR="${REPO_CONFIG_DIR}/.vale/styles"

# -----------------------
# Collect files
# -----------------------
FILES=()

if [ "$#" -gt 0 ]; then
  for a in "$@"; do FILES+=("$a"); done
elif [ -n "${CHANGED_FILES:-}" ]; then
  mapfile -t FILES < <(echo "$CHANGED_FILES" | tr '\r' '\n' | sed '/^$/d')
else
  mapfile -t FILES < <(find docs -type f \( -name "*.md" -o -name "*.adoc" -o -name "*.yaml" -o -name "*.yml" \))
fi

mapfile -t GOOD_FILES < <(printf "%s\n" "${FILES[@]}" | sort -u)

if [ ${#GOOD_FILES[@]} -eq 0 ]; then
  echo "ℹ️ No documentation files to lint."
  exit 0
fi

echo "📋 Files to check (${#GOOD_FILES[@]}):"
printf ' - %s\n' "${GOOD_FILES[@]}"

# -----------------------
# AsciiDoc validation
# -----------------------
echo "🏗️ Validating AsciiDoc..."
ADOC_FILES=($(printf '%s\n' "${GOOD_FILES[@]}" | grep -E '\.adoc$' || true))
if [ ${#ADOC_FILES[@]} -gt 0 ]; then
  for f in "${ADOC_FILES[@]}"; do
    echo "📄 Checking $f ..."
    output=$(asciidoctor -q -o /dev/null "$f" 2>&1 || true)
    if echo "$output" | grep -qE "ERROR|include file not found"; then
      echo "❌ $f → ERROR!"
      echo "$output" >> artifacts/asciidoc.log
      exit_code=1
    else
      echo "✅ $f passed"
    fi
  done
else
  echo "⚠️ No AsciiDoc files to check." > artifacts/asciidoc.log
fi
echo ""

# -----------------------
# Spectral (OpenAPI)
# -----------------------
echo "🔍 Running Spectral..."
YAML_FILES=($(printf '%s\n' "${GOOD_FILES[@]}" | grep -E '\.ya?ml$' || true))
if [ ${#YAML_FILES[@]} -gt 0 ]; then
  for f in "${YAML_FILES[@]}"; do
    spectral lint --ruleset "${SPECTRAL_CONFIG}" "$f" | tee -a artifacts/openapi.log || true
  done
else
  echo "⚠️ No YAML files found." | tee artifacts/openapi.log
fi
echo ""

# -----------------------
# Vale (Style check)
# -----------------------
echo "✍️ Running Vale..."
if [ -d "${VALE_STYLES_DIR}" ]; then
  VALE_CMD=(vale --config "${VALE_CONFIG}")
else
  VALE_CMD=(vale)
fi

"${VALE_CMD[@]}" --output=line --minAlertLevel=warning "${GOOD_FILES[@]}" 2>&1 | tee artifacts/vale.log || true
echo ""

# -----------------------
# Doctoolchain (build diagrams)
# -----------------------
echo "📘 Testing doctoolchain build (dry-run)..."
if command -v doctoolchain >/dev/null; then
  doctoolchain . tasks | grep generateDiagrams >/dev/null && \
    echo "✅ doctoolchain available." || \
    echo "⚠️ doctoolchain diagram task not found."
else
  echo "⚠️ doctoolchain not installed."
fi
echo ""

echo "✅ Linting completed. Logs in /artifacts."
exit 0