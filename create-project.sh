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

mkdir -p "$TARGET_DIR/api/schemas/errors"
mkdir -p "$TARGET_DIR/shared"
touch "$TARGET_DIR/accesses.md"
touch "$TARGET_DIR/shared/glossary.md"

# Ошибки API
touch "$TARGET_DIR/api/schemas/OrderResponse.adoc"
touch "$TARGET_DIR/api/schemas/Dish.adoc"

# API endpoints (пример)
cat << EOF > "$TARGET_DIR/api/$PROJECT_NAME/v7/GET_api_v7_restaurants.yml"
# Endpoint: GET /api/v7/restaurants
summary: Получить список ресторанов
responses:
  '200':
    description: OK
EOF

# Модули в requirements
for MODULE in $MODULES; do
  MOD_LC=$(echo "$MODULE" | awk '{print tolower($0)}')
  mkdir -p "$TARGET_DIR/requirements/$MODULE"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/UseCases"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Images"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Diagrams"
  mkdir -p "$TARGET_DIR/requirements/$MODULE/Database"
  touch "$TARGET_DIR/requirements/$MODULE/$MODULE.adoc"
done

echo "✅ Проект '$PROJECT_NAME' создан: $TARGET_DIR"
echo "💡 Откройте в VS Code: code $PROJECT_NAME"

# --- Создание README.md ---
cat << EOF > "$TARGET_DIR/../README.md"
# 📚 Документация: $PROJECT_NAME

> Актуальная техническая документация для проекта **$PROJECT_NAME**

---

## 🗂️ Структура документации

\`\`\`
docs/
├── api/                  # Спецификации API
│   ├── schemas/          # Модели данных
│   └── $PROJECT_NAME/    # Эндпоинты
├── requirements/         # Бизнес-требования
│   └── {модуль}/         # Например: Restaurants, Addresses
├── accesses.md           # Права доступа
└── shared/               # Общие ресурсы
    └── glossary.md       # Глоссарий терминов
\`\`\`

---

## 🔗 Основные разделы

- [API](api/$PROJECT_NAME/v7/GET_api_v7_restaurants.yml) — спецификации эндпоинтов
- [Требования](requirements/) — бизнес-логика и сценарии
- [Глоссарий](shared/glossary.md) — общие термины

---

## 🆘 Как внести изменения?

1. Отредактируйте нужный файл.
2. Создайте Pull Request в `main`.
3. Изменения проверит системный аналитик.

> 💡 Подсказка: используйте шаблоны в \`/docs/shared/templates/\`.

---

_Документация обновлена: $(date +%Y-%m-%d)_
EOF

echo "📄 Создано: $TARGET_DIR/../README.md"