#!/bin/bash
# create-project.sh — создаёт структуру docs для нового проекта

PROJECT_NAME=$1
MODULES=${@:2}  # Дополнительные модули, например: Restaurants Addresses

if [ -z "$PROJECT_NAME" ]; then
  echo "Использование: ./create-project.sh <название_проекта> [модуль1] [модуль2]..."
  exit 1
fi

TARGET_DIR="docs/$PROJECT_NAME"

if [ -d "$TARGET_DIR" ]; then
  echo "❌ Папка $TARGET_DIR уже существует."
  exit 1
fi

echo "🚀 Создаём структуру для проекта: $PROJECT_NAME"

# ───────────────────────────────────────
# 1. API
# ───────────────────────────────────────
mkdir -p "$TARGET_DIR/api/schemas/errors"
mkdir -p "$TARGET_DIR/shared"

# Примеры ошибок
touch "$TARGET_DIR/api/schemas/errors/error400.md"
touch "$TARGET_DIR/api/schemas/errors/error401.md"
touch "$TARGET_DIR/api/schemas/errors/error402.md"

# Модели данных
touch "$TARGET_DIR/api/schemas/OrderResponse.adoc"
touch "$TARGET_DIR/api/schemas/Dish.adoc"

# ───────────────────────────────────────
# 2. Требования (Requirements)
# ───────────────────────────────────────
for MODULE in $MODULES; do
  MOD_LC=$(echo "$MODULE" | awk '{print tolower($0)}')
  
  # API endpoint example
  cat << EOF > "$TARGET_DIR/api/$MODULE/v7/GET_api_v7_restaurants.yml"
# Endpoint: GET /api/v7/restaurants
summary: Получить список ресторанов
responses:
  '200':
    description: OK
EOF

  # Структура требований
  mkdir -p "$TARGET_DIR/requirements/$MODULE"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/UseCases"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Images"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Diagrams"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Database"
  touch "$TARGET_DIR/requirements/$MODULE/$MODULE.adoc"
done

# ───────────────────────────────────────
# 3. Общие файлы
# ───────────────────────────────────────
touch "$TARGET_DIR/accesses.md"
touch "$TARGET_DIR/shared/glossary.md"

echo "✅ Проект '$PROJECT_NAME' создан: $TARGET_DIR"

# ───────────────────────────────────────
# 4. README.md
# ───────────────────────────────────────
cat << EOF > "$TARGET_DIR/README.md"
# 📚 Документация: $PROJECT_NAME

> Актуальная техническая документация для проекта **$PROJECT_NAME**

---

## 🗂️ Структура документации

\`\`\`
docs/
└── $PROJECT_NAME/
    ├── api/
    │   ├── schemas/
    │   │   ├── errors/
    │   │   └── OrderResponse.adoc
    │   └── {модуль}/
    │       └── v7/
    │           └── GET_api_v7_restaurants.yml
    ├── requirements/
    │   └── {модуль}/
    │       ├── UseCases/
    │       ├── Images/
    │       ├── Diagrams/
    │       └── Database/
    ├── accesses.md
    └── shared/
        └── glossary.md
\`\`\`

---

## 🔗 Основные разделы

$(for MODULE in $MODULES; do
  echo "- [API: $MODULE](api/$MODULE/v7/GET_api_v7_restaurants.yml)"
done)

- [Глоссарий](shared/glossary.md) — общие термины

---

## 🆘 Как внести изменения?

1. Отредактируйте нужный файл.
2. Создайте Pull Request в \`main\`.
3. Изменения проверит системный аналитик.

> 💡 Подсказка: используйте шаблоны в \`/docs/shared/templates/\`.

---

_Документация обновлена: $(date +%Y-%m-%d)_
EOF

echo "📄 Создано: $TARGET_DIR/README.md"