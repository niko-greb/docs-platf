#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# run-linters.sh
# Проверка изменённых/переданных файлов (Docs-as-Code).
# - Использует конфиги из .repo/config/
# - Поддерживает передачу файлов в аргументах или через env CHANGED_FILES
# Usage:
#   ./run-linters.sh docs/testcases/03_bad_asciidoc.adoc docs/api/order.yaml
#   export CHANGED_FILES="$(git diff --name-only origin/main...HEAD)"
#   ./run-linters.sh
# NOTE: запуск внутри контейнера предполагает рабочую директорию /work
# ===================================================================

SOFT_MODE=true   # true — soft mode (не ломает CI)
mkdir -p artifacts
exit_code=0

REPO_CONFIG_DIR=".repo/config"
REPO_SCRIPTS_DIR=".repo/ci/scripts"
VALE_CONFIG="${REPO_CONFIG_DIR}/.vale.ini"
SPECTRAL_CONFIG="${REPO_CONFIG_DIR}/.spectral.yaml"
VALE_STYLES_DIR="${REPO_CONFIG_DIR}/.vale/styles"

echo "🧩 Starting Docs-as-Code Validation (Soft Mode: ${SOFT_MODE})"
echo "Working dir: $(pwd)"
echo ""

# -----------------------
# Collect files to check
# -----------------------
FILES=()

# 1) from script args
if [ "$#" -gt 0 ]; then
  for a in "$@"; do
    FILES+=("$a")
  done
fi

# 2) from CHANGED_FILES env
if [ ${#FILES[@]} -eq 0 ] && [ -n "${CHANGED_FILES:-}" ]; then
  mapfile -t lines < <(printf '%s\n' "$CHANGED_FILES" | tr '\r' '\n')
  for line in "${lines[@]}"; do
    file="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$file" ] && FILES+=("$file")
  done
fi

# 3) fallback — check all relevant files
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <(find . -type f \( -name "*.adoc" -o -name "*.yaml" -o -name "*.yml" \) \
    -not -path "./.git/*" -not -path "./.github/*" -not -path "./.repo/*" -not -path "./artifacts/*")
fi

# Normalize and filter files
GOOD_FILES=()
for f in "${FILES[@]}"; do
  [ -z "$f" ] && continue
  f="${f#./}"
  case "$f" in
    .git/*|.github/*|.repo/*|artifacts/*)
      continue
      ;;
  esac
  if [ -f "$f" ]; then
    case "$f" in
      *.adoc|*.yml|*.yaml) GOOD_FILES+=("$f") ;;
      *) ;;
    esac
  else
    echo "⚠️ Skipping missing file: $f"
  fi
done

if [ ${#GOOD_FILES[@]} -eq 0 ]; then
  echo "ℹ️ No documentation files to lint. Exiting."
  exit 0
fi

echo "📋 Files to check (${#GOOD_FILES[@]}):"
for ff in "${GOOD_FILES[@]}"; do echo " - $ff"; done
echo ""

# -----------------------
# AsciiDoc (doctest / asciidoctor)
# -----------------------
echo "🏗️ Running AsciiDoc checks..."
ADOC_FILES=()
for f in "${GOOD_FILES[@]}"; do
  case "$f" in *.adoc) ADOC_FILES+=("$f") ;; esac
done

if [ ${#ADOC_FILES[@]} -gt 0 ]; then
  for f in "${ADOC_FILES[@]}"; do
    echo "📄 Checking $f ..."
    if asciidoctor --failure-level=WARN -q -o /dev/null "$f" 2>&1 | tee -a artifacts/asciidoc.log; then
      echo "✅ $f passed"
    else
      echo "❌ $f failed (see artifacts/asciidoc.log)" | tee -a artifacts/asciidoc.log
      exit_code=1
    fi
  done
else
  echo "⚠️ No AsciiDoc files to check." | tee artifacts/asciidoc.log
fi
echo ""

# -----------------------
# Spectral (OpenAPI)
# -----------------------
echo "🔍 Running Spectral (OpenAPI lint)..."
YAML_FILES=()
for f in "${GOOD_FILES[@]}"; do
  case "$f" in *.yml|*.yaml) YAML_FILES+=("$f") ;; esac
done

if [ ${#YAML_FILES[@]} -gt 0 ]; then
  for f in "${YAML_FILES[@]}"; do
    if [ -f "${SPECTRAL_CONFIG}" ]; then
      spectral lint --ruleset "${SPECTRAL_CONFIG}" "$f" 2>&1 | tee -a artifacts/openapi.log || true
    else
      spectral lint "$f" 2>&1 | tee -a artifacts/openapi.log || true
    fi
  done
else
  echo "⚠️ No OpenAPI YAML files to lint." | tee artifacts/openapi.log
fi
echo ""

# -----------------------
# Vale (style & terminology)
# -----------------------
echo "✍️ Running Vale style checks..."
if command -v vale >/dev/null 2>&1; then
  vale --config "${VALE_CONFIG}" --output=line --minAlertLevel=warning "${GOOD_FILES[@]}" 2>&1 | tee artifacts/vale.log || true
else
  echo "⚠️ Vale not installed. Skipping." | tee artifacts/vale.log
fi
echo ""

# -----------------------
# Convert logs to GitHub annotations
# -----------------------
echo "📋 Generating GitHub annotations..."
for log in artifacts/*.log; do
  [ -f "$log" ] || continue
  if [ ! -s "$log" ]; then
    continue
  fi
  grep -hE "^[^[:space:]]+:[0-9]+" "$log" || true | while IFS= read -r line; do
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
done

# -----------------------
# Final summary & exit
# -----------------------
echo ""
if [ "$exit_code" -ne 0 ]; then
  echo "⚠️ Validation finished with issues. Check artifacts/*.log"
else
  echo "✅ Validation finished: no blocking issues found."
fi

echo "📂 Artifacts saved to artifacts/"

if [ "${SOFT_MODE}" = true ]; then
  echo "🩶 Soft mode: exiting 0 (non-blocking)."
  exit 0
else
  exit "${exit_code}"
fi