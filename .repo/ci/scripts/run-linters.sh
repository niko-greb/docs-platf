#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# run-linters.sh
# Проверка изменённых/переданных файлов (Docs-as-Code).
# - Использует конфиги из .repo/config/
# - Поддерживает передачу файлов в аргументах или через env CHANGED_FILES
# Usage:
#   ./run-linters.sh docs/testcases/01_bad_markdown.md docs/api/order.yaml
#   export CHANGED_FILES="$(git diff --name-only origin/main...HEAD)"
#   ./run-linters.sh
# NOTE: запуск внутри контейнера предполагает рабочую директорию /work
# ===================================================================

SOFT_MODE=true   # true — soft mode (не ломает CI)
mkdir -p artifacts
RUN_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
LOG_HEADER="=== Lint run started at ${RUN_TIMESTAMP} ==="
echo "$LOG_HEADER" | tee -a artifacts/markdownlint.log artifacts/mdformat.log \
                                      artifacts/asciidoc.log artifacts/openapi.log \
                                      artifacts/vale.log >/dev/null
exit_code=0

REPO_CONFIG_DIR=".repo/config"
REPO_SCRIPTS_DIR=".repo/ci/scripts"
VALE_CONFIG="${REPO_CONFIG_DIR}/.vale.ini"
MARKDOWNLINT_CONFIG="${REPO_CONFIG_DIR}/.markdownlint-cli2.jsonc"
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

# 2) from CHANGED_FILES env (if no args or even if args present — args take precedence)
if [ ${#FILES[@]} -eq 0 ] && [ -n "${CHANGED_FILES:-}" ]; then
  # support newline or space separated CHANGED_FILES
  # normalize CRLF -> LF
  mapfile -t lines < <(printf '%s\n' "$CHANGED_FILES" | tr '\r' '\n')
  for line in "${lines[@]}"; do
    # trim
    file="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$file" ] && FILES+=("$file")
  done
fi

# 3) fallback — check all relevant files (used e.g. for main push)
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <(find . -type f \( -name "*.md" -o -name "*.adoc" -o -name "*.yaml" -o -name "*.yml" \) \
    -not -path "./.git/*" -not -path "./.github/*" -not -path "./.repo/*" -not -path "./artifacts/*")
fi

# Normalize and filter files: keep only those that exist and match extensions we handle
GOOD_FILES=()
for f in "${FILES[@]}"; do
  # skip directories or patterns
  [ -z "$f" ] && continue
  # remove leading "./" if present
  f="${f#./}"
  # ignore system paths
  case "$f" in
    .git/*|.github/*|.repo/*|artifacts/*)
      continue
      ;;
  esac
  if [ -f "$f" ]; then
    case "$f" in
      *.md|*.adoc|*.yml|*.yaml) GOOD_FILES+=("$f") ;;
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
# Markdownlint
# -----------------------
echo "🧾 Running markdownlint..."
MD_FILES=()
for f in "${GOOD_FILES[@]}"; do
  case "$f" in *.md) MD_FILES+=("$f") ;; esac
done

if [ ${#MD_FILES[@]} -gt 0 ]; then
  if [ -f "${MARKDOWNLINT_CONFIG}" ]; then
    markdownlint-cli2 "${MD_FILES[@]}" --config "${MARKDOWNLINT_CONFIG}" --fix false 2>&1 | tee artifacts/markdownlint.log || true
  else
    markdownlint-cli2 "${MD_FILES[@]}" --fix false 2>&1 | tee artifacts/markdownlint.log || true
  fi
else
  echo "⚠️ No Markdown files to lint." | tee artifacts/markdownlint.log
fi
echo ""

# -----------------------
# mdformat (format check)
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
# AsciiDoc (doctest / asciidoctor)
# -----------------------
echo "🏗️ Running AsciiDoc checks..."
# -----------------------
# AsciiDoc checks (reliable version)
# -----------------------
echo "🏗️ Running AsciiDoc checks..."
ADOC_FILES=()
for f in "${GOOD_FILES[@]}"; do
  case "$f" in *.adoc) ADOC_FILES+=("$f") ;; esac
done

if [ ${#ADOC_FILES[@]} -gt 0 ]; then
  echo "# AsciiDoc Validation Log" > artifacts/asciidoc.log

  for f in "${ADOC_FILES[@]}"; do
    echo "📄 Checking $f ..."
    
    # Запускаем и ловим ВЕСЬ вывод
    error_output=$(asciidoctor  -q -o /dev/null "$f" 2>&1)
    exit_code_cmd=$?

    # Считаем файл "проваленным", если:
    # - команда вернула ошибку ИЛИ
    # - в выводе есть WARNING или ERROR
    if [ $exit_code_cmd -ne 0 ] || echo "$error_output" | grep -qE ":( WARNING|: ERROR)"; then
      # Извлекаем первое сообщение
      clean_msg=$(echo "$error_output" | grep -E ":( WARNING|: ERROR)" | head -1 | sed 's/.*: \(WARNING\|ERROR\): //')
      if [ -z "$clean_msg" ]; then
        clean_msg="Validation failed (see log)"
      fi
      echo "❌ $f: $clean_msg"
      {
        echo
        echo "=== ERROR in: $f ==="
        echo "$error_output"
      } >> artifacts/asciidoc.log
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
# ensure Vale styles available: if styles exist in repo config, point Vale to use that config
if [ -d "${VALE_STYLES_DIR}" ]; then
  # if .repo/config/.vale.ini exists, use it; otherwise use default vale behavior
  if [ -f "${VALE_CONFIG}" ]; then
    VALE_CMD=(vale --config "${VALE_CONFIG}")
  else
    # create minimal temporary ini to point to styles
    TMP_VALE_INI="/tmp/.vale-temp.ini"
    printf "[*.{md,adoc}]\nStylesPath = %s\n" "${VALE_STYLES_DIR}" > "${TMP_VALE_INI}"
    VALE_CMD=(vale --config "${TMP_VALE_INI}")
  fi
else
  # fallback: default vale
  VALE_CMD=(vale)
fi

if command -v vale >/dev/null 2>&1; then
  # call vale with list of files (it accepts files as args)
  "${VALE_CMD[@]}" --output=line --minAlertLevel=warning "${GOOD_FILES[@]}" 2>&1 | tee artifacts/vale.log || true
else
  echo "⚠️ Vale not installed. Skipping." | tee artifacts/vale.log
fi
echo ""

# -----------------------
# Convert logs to GitHub annotations (warnings/errors)
# -----------------------
echo "📋 Generating GitHub annotations..."
# pattern: file:line:message  (markdownlint and others follow similar)
for log in artifacts/*.log; do
  [ -f "$log" ] || continue
  if [ ! -s "$log" ]; then
    continue
  fi
  # grep lines that look like file:line:msg
  grep -hE "^[^[:space:]]+:[0-9]+" "$log" || true | while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    ln=$(echo "$line" | cut -d: -f2)
    msg=$(echo "$line" | cut -d: -f3- | sed 's/"/\\"/g')
    # determine severity by presence of 'error' word (best-effort)
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
