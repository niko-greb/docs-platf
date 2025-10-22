#!/usr/bin/env bash
set -euo pipefail

# ===================================================================
# 🧩 Docs-as-Code Linter Orchestrator
# Проверяет только изменённые или переданные файлы.
# Конфиги лежат в .repo/config/
# Используется в CI и при локальной отладке.
# ===================================================================

SOFT_MODE=true   # true — мягкий режим (CI не падает)
mkdir -p artifacts
RUN_TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
exit_code=0

echo "==============================================================="
echo "🧩 Starting Docs-as-Code Validation (Soft Mode: ${SOFT_MODE})"
echo "📅 Run: ${RUN_TIMESTAMP}"
echo "📂 Working dir: $(pwd)"
echo "==============================================================="

# -----------------------------
# 🧱 Пути конфигов
# -----------------------------
REPO_CONFIG_DIR=".repo/config"
REPO_SCRIPTS_DIR=".repo/ci/scripts"
VALE_CONFIG="${REPO_CONFIG_DIR}/.vale.ini"
MARKDOWNLINT_CONFIG="${REPO_CONFIG_DIR}/.markdownlint-cli2.jsonc"
SPECTRAL_CONFIG="${REPO_CONFIG_DIR}/.spectral.yaml"
VALE_STYLES_DIR="${REPO_CONFIG_DIR}/.vale/styles"

# -----------------------------
# 📦 Сбор файлов для проверки
# -----------------------------
FILES=()

# 1️⃣ Из аргументов
if [ "$#" -gt 0 ]; then
  FILES=("$@")
# 2️⃣ Из переменной окружения
elif [ -n "${CHANGED_FILES:-}" ]; then
  mapfile -t FILES < <(echo "$CHANGED_FILES" | tr '\r' '\n' | sed '/^$/d')
# 3️⃣ Фолбэк — все поддерживаемые файлы
else
  mapfile -t FILES < <(find docs . -type f \( -name "*.md" -o -name "*.adoc" -o -name "*.yaml" -o -name "*.yml" \) \
    -not -path "./.git/*" -not -path "./.github/*" -not -path "./.repo/*" -not -path "./artifacts/*")
fi

GOOD_FILES=()
for f in "${FILES[@]}"; do
  f="${f#./}"
  [[ -f "$f" ]] || continue
  case "$f" in
    *.md|*.adoc|*.yml|*.yaml) GOOD_FILES+=("$f") ;;
  esac
done

# Убираем дубликаты (чтобы линтеры не запускались дважды на одних и тех же файлах)
mapfile -t GOOD_FILES < <(printf "%s\n" "${GOOD_FILES[@]}" | sort -u)

if [ ${#GOOD_FILES[@]} -eq 0 ]; then
  echo "ℹ️ No relevant documentation files to lint. Exiting."
  exit 0
fi

echo "📋 Files to check (${#GOOD_FILES[@]}):"
for f in "${GOOD_FILES[@]}"; do echo " - $f"; done
echo ""

# ===================================================================
# 1️⃣ Markdownlint
# ===================================================================
echo "🧾 Running Markdown Linter..."
MD_FILES=($(printf "%s\n" "${GOOD_FILES[@]}" | grep -E '\.md$' || true))

if [ ${#MD_FILES[@]} -gt 0 ]; then
  config_arg=()
  [ -f "$MARKDOWNLINT_CONFIG" ] && config_arg=(--config "$MARKDOWNLINT_CONFIG")
  markdownlint-cli2 "${config_arg[@]}" "${MD_FILES[@]}" --fix false 2>&1 | tee artifacts/markdownlint.log || true
else
  echo "⚠️ No Markdown files found." | tee artifacts/markdownlint.log
fi
echo ""

# ===================================================================
# 2️⃣ mdformat (Markdown formatting)
# ===================================================================
echo "🎨 Checking Markdown formatting (mdformat)..."
if command -v mdformat >/dev/null 2>&1; then
  for f in "${MD_FILES[@]}"; do
    mdformat --check "$f" 2>&1 | tee -a artifacts/mdformat.log || true
  done
else
  echo "⚠️ mdformat not installed. Skipping." | tee artifacts/mdformat.log
fi
echo ""

# ===================================================================
# 3️⃣ AsciiDoc validation
# ===================================================================
echo "🏗️ Running AsciiDoc validation..."
ADOC_FILES=($(printf "%s\n" "${GOOD_FILES[@]}" | grep -E '\.adoc$' || true))

if [ ${#ADOC_FILES[@]} -gt 0 ]; then
  echo "# AsciiDoc Validation Log (${RUN_TIMESTAMP})" > artifacts/asciidoc.log

  for f in "${ADOC_FILES[@]}"; do
    echo "📄 Checking $f ..."
    output=$(asciidoctor --trace --failure-level WARN -o /dev/null "$f" 2>&1 || true)

    if echo "$output" | grep -qE "(: ERROR|: FAILED)"; then
      echo "❌ $f → ERROR(s) found!"
      echo "$output" | grep -E "(: ERROR|: FAILED)" | tee -a artifacts/asciidoc.log
      exit_code=1
    elif echo "$output" | grep -qE "(: WARNING|: WARN)"; then
      echo "⚠️  $f → warning(s) found."
      echo "$output" | grep -E "(: WARNING|: WARN)" | tee -a artifacts/asciidoc.log
    else
      echo "✅ $f passed"
    fi
  done
else
  echo "⚠️ No AsciiDoc files found." | tee artifacts/asciidoc.log
fi
echo ""

# ===================================================================
# 4️⃣ OpenAPI validation (Spectral)
# ===================================================================
echo "🔍 Running Spectral (OpenAPI)..."
YAML_FILES=($(printf "%s\n" "${GOOD_FILES[@]}" | grep -E '\.ya?ml$' || true))

if [ ${#YAML_FILES[@]} -gt 0 ]; then
  for f in "${YAML_FILES[@]}"; do
    if [ -f "$SPECTRAL_CONFIG" ]; then
      spectral lint --ruleset "$SPECTRAL_CONFIG" "$f" 2>&1 | tee -a artifacts/openapi.log || true
    else
      spectral lint "$f" 2>&1 | tee -a artifacts/openapi.log || true
    fi
  done
else
  echo "⚠️ No OpenAPI YAML files found." | tee artifacts/openapi.log
fi
echo ""

# ===================================================================
# 5️⃣ Vale Style & Terminology
# ===================================================================
echo "✍️ Running Vale..."
if [ ! -d "$VALE_STYLES_DIR" ]; then
  echo "⚙️ Syncing Vale styles..."
  vale sync || true
fi

if command -v vale >/dev/null 2>&1; then
  vale --config "$VALE_CONFIG" --output=line --minAlertLevel=warning "${GOOD_FILES[@]}" 2>&1 | tee artifacts/vale.log || true
else
  echo "⚠️ Vale not found. Skipping style check." | tee artifacts/vale.log
fi
echo ""

# ===================================================================
# 6️⃣ GitHub Annotations
# ===================================================================
echo "📋 Generating GitHub annotations..."
for log in artifacts/*.log; do
  [ -f "$log" ] || continue
  [ -s "$log" ] || continue

  # Ищем обычные ошибки (file:line:msg) и asciidoctor (file: line N: msg)
  grep -hE "^[^[:space:]]+:[0-9]+:" "$log" || \
  grep -hE "^[^[:space:]]+.*line[[:space:]]+[0-9]+:" "$log" || true | while IFS= read -r line; do
    file=""
    ln=""
    msg=""

    # Обработка формата Asciidoctor: "asciidoctor: ERROR: docs/file.adoc: line 3: message"
    if [[ "$line" =~ ([^:]+\.adoc):[[:space:]]*line[[:space:]]*([0-9]+):(.*) ]]; then
      file="${BASH_REMATCH[1]}"
      ln="${BASH_REMATCH[2]}"
      msg="${BASH_REMATCH[3]}"
    # Обычный формат file:line:msg
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

# ===================================================================
# 7️⃣ Итог
# ===================================================================
if [ "$exit_code" -ne 0 ]; then
  echo "⚠️ Validation finished with issues. Check artifacts/*.log"
else
  echo "✅ Validation successful: no blocking issues found."
fi

echo "📂 Artifacts stored in /artifacts/"
if [ "${SOFT_MODE}" = true ]; then
  echo "🩶 Soft mode enabled: exiting 0 (non-blocking)"
  exit 0
else
  exit "${exit_code}"
fi
