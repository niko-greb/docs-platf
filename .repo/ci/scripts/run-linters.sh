#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# run-linters.sh — Универсальный запуск Docs-as-Code линтеров
# Проверяет только изменённые или переданные файлы.
# Работает внутри контейнера docs-cli:ci или локально.
# ===================================================================

SOFT_MODE=true   # true — soft mode (не ломает CI)
mkdir -p artifacts
RUN_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
echo "==============================================================="
echo "🧩 Starting Docs-as-Code Validation (Soft Mode: ${SOFT_MODE})"
echo "📅 Run: ${RUN_TIMESTAMP}"
echo "📂 Working dir: $(pwd)"
echo "==============================================================="

exit_code=0

REPO_CONFIG_DIR=".repo/config"
REPO_SCRIPTS_DIR=".repo/ci/scripts"
VALE_CONFIG="${REPO_CONFIG_DIR}/.vale.ini"
MARKDOWNLINT_CONFIG="${REPO_CONFIG_DIR}/.markdownlint-cli2.jsonc"
SPECTRAL_CONFIG="${REPO_CONFIG_DIR}/.spectral.yaml"
VALE_STYLES_DIR="${REPO_CONFIG_DIR}/.vale/styles"

# -----------------------
# Collect files to check
# -----------------------
FILES=()

# 1) args
if [ "$#" -gt 0 ]; then
  for a in "$@"; do FILES+=("$a"); done
fi

# 2) env CHANGED_FILES
if [ ${#FILES[@]} -eq 0 ] && [ -n "${CHANGED_FILES:-}" ]; then
  mapfile -t lines < <(printf '%s\n' "$CHANGED_FILES" | tr '\r' '\n')
  for line in "${lines[@]}"; do
    file="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$file" ] && FILES+=("$file")
  done
fi

# 3) fallback — check all
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <(find . -type f \( -name "*.md" -o -name "*.adoc" -o -name "*.yaml" -o -name "*.yml" \) \
    -not -path "./.git/*" -not -path "./.github/*" -not -path "./.repo/*" -not -path "./artifacts/*")
fi

# -----------------------
# Filter and deduplicate
# -----------------------
GOOD_FILES=()
for f in "${FILES[@]}"; do
  [ -z "$f" ] && continue
  f="${f#./}"
  case "$f" in
    .git/*|.github/*|.repo/*|artifacts/*) continue ;;
  esac
  if [ -f "$f" ]; then
    case "$f" in
      *.md|*.adoc|*.yml|*.yaml) GOOD_FILES+=("$f") ;;
    esac
  fi
done

# Убираем дубликаты
mapfile -t GOOD_FILES < <(printf "%s\n" "${GOOD_FILES[@]}" | sort -u)

if [ ${#GOOD_FILES[@]} -eq 0 ]; then
  echo "ℹ️ No documentation files to lint. Exiting."
  exit 0
fi

echo "📋 Files to check (${#GOOD_FILES[@]}):"
for ff in "${GOOD_FILES[@]}"; do echo " - $ff"; done
echo ""

# -----------------------
# Markdownlint
# -----------------------
echo "🧾 Running Markdown Linter..."
MD_FILES=()
for f in "${GOOD_FILES[@]}"; do [[ "$f" == *.md ]] && MD_FILES+=("$f"); done

if [ ${#MD_FILES[@]} -gt 0 ]; then
  markdownlint-cli2 "${MD_FILES[@]}" --config "${MARKDOWNLINT_CONFIG}" --fix false 2>&1 | tee artifacts/markdownlint.log || true
else
  echo "⚠️ No Markdown files to lint." | tee artifacts/markdownlint.log
fi
echo ""

# -----------------------
# mdformat
# -----------------------
echo "🎨 Checking Markdown formatting (mdformat)..."
if command -v mdformat >/dev/null 2>&1; then
  if [ ${#MD_FILES[@]} -gt 0 ]; then
    for f in "${MD_FILES[@]}"; do
      mdformat --check "$f" 2>&1 | tee -a artifacts/mdformat.log || true
    done
  else
    echo "⚠️ No Markdown files for mdformat." | tee artifacts/mdformat.log
  fi
else
  echo "⚠️ mdformat not installed. Skipping." | tee artifacts/mdformat.log
fi
echo ""

# -----------------------
# AsciiDoc (validation)
# -----------------------
echo "🏗️ Running AsciiDoc validation..."
ADOC_FILES=()
for f in "${GOOD_FILES[@]}"; do [[ "$f" == *.adoc ]] && ADOC_FILES+=("$f"); done

if [ ${#ADOC_FILES[@]} -gt 0 ]; then
  echo "# AsciiDoc Validation Log" > artifacts/asciidoc.log
  for f in "${ADOC_FILES[@]}"; do
    echo "📄 Checking $f ..."
    output=$(asciidoctor -q -o /dev/null "$f" 2>&1 || true)
    if echo "$output" | grep -qE "ERROR|WARN|include file not found"; then
      echo "❌ $f → ERROR(s) found!"
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
echo "🔍 Running Spectral (OpenAPI)..."
YAML_FILES=()
for f in "${GOOD_FILES[@]}"; do [[ "$f" == *.yml || "$f" == *.yaml ]] && YAML_FILES+=("$f"); done

if [ ${#YAML_FILES[@]} -gt 0 ]; then
  for f in "${YAML_FILES[@]}"; do
    spectral lint --ruleset "${SPECTRAL_CONFIG}" "$f" 2>&1 | tee -a artifacts/openapi.log || true
  done
else
  echo "⚠️ No OpenAPI YAML files to lint." | tee artifacts/openapi.log
fi
echo ""

# -----------------------
# Vale
# -----------------------
echo "✍️ Running Vale..."
if [ -d "${VALE_STYLES_DIR}" ]; then
  VALE_CMD=(vale --config "${VALE_CONFIG}")
else
  VALE_CMD=(vale)
fi

if command -v vale >/dev/null 2>&1; then
  "${VALE_CMD[@]}" --output=line --minAlertLevel=warning "${GOOD_FILES[@]}" 2>&1 | tee artifacts/vale.log || true
else
  echo "⚠️ Vale not installed. Skipping." | tee artifacts/vale.log
fi
echo ""

# -----------------------
# GitHub Annotations
# -----------------------
echo "📋 Generating GitHub annotations..."
for log in artifacts/*.log; do
  [ -f "$log" ] || continue
  [ -s "$log" ] || continue

  grep -hE "^[^[:space:]]+:[0-9]+:" "$log" || \
  grep -hE "^[^[:space:]]+.*line[[:space:]]+[0-9]+:" "$log" || true | while IFS= read -r line; do
    file=""
    ln=""
    msg=""

    if [[ "$line" =~ ([^:]+\.adoc):[[:space:]]*line[[:space:]]*([0-9]+):(.*) ]]; then
      file="${BASH_REMATCH[1]}"
      ln="${BASH_REMATCH[2]}"
      msg="${BASH_REMATCH[3]}"
    elif [[ "$line" =~ ^([^:]+):([0-9]+):(.*)$ ]]; then
      file="${BASH_REMATCH[1]}"
      ln="${BASH_REMATCH[2]}"
      msg="${BASH_REMATCH[3]}"
    fi

    msg=$(echo "$msg" | sed 's/"/\\"/g')

    if echo "$msg" | grep -qi "error"; then
      echo "::error file=${file},line=${ln}::${msg}"
      exit_code=1
    else
      echo "::warning file=${file},line=${ln}::${msg}"
    fi
  done
done

echo ""
if [ "$exit_code" -ne 0 ]; then
  echo "⚠️ Validation finished with issues. Check artifacts/*.log"
else
  echo "✅ Validation finished: no blocking issues found."
fi

echo "📂 Artifacts stored in /artifacts/"

if [ "${SOFT_MODE}" = true ]; then
  echo "🩶 Soft mode enabled: exiting 0 (non-blocking)"
  exit 0
else
  exit "${exit_code}"
fi
