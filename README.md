# 🧱 Docs-as-Code Repository

Этот репозиторий содержит документацию по всем проектам в формате Docs-as-Code.

## 📂 Структура

- `docs/` — основная рабочая директория для аналитиков.
- `.repo/` — технические файлы (CI, линтеры, шаблоны, конфиги).

## 🧩 Проверка документации

Проверка выполняется автоматически в PR через GitHub Actions.  
Результаты выводятся в виде комментария к PR и сохраняются в артефакты.

### 🔹 Для локальной проверки
```bash
docker build -t docs-cli:ci -f .repo/Dockerfile .
docker run --rm -v "$PWD":/work -w /work docs-cli:ci bash .repo/ci/scripts/run-linters.sh
```


📘 Руководство по .gitattributes
🎯 Назначение файла

.gitattributes управляет тем, как Git обрабатывает файлы в репозитории:

Определяет, какие файлы текстовые, а какие бинарные

Нормализует переносы строк (LF / CRLF)

Улучшает отображение различий (diff) для документации

Исключает артефакты CI из статистики GitHub

Предотвращает «грязные» коммиты при работе в разных ОС

🧩 В Docs-as-Code экосистеме .gitattributes обеспечивает консистентную работу аналитиков, разработчиков и CI/CD-пайплайнов.

⚙️ Основные разделы файла
Раздел	Назначение
* text=auto eol=lf	Все текстовые файлы сохраняются с LF (Unix-формат)
*.md diff=markdown	Показывает Markdown-изменения в удобном формате
*.adoc diff=asciidoc	Улучшает диффы для AsciiDoc
.repo/config/**	Конфиги линтеров — не учитываются в статистике кода
artifacts/**, build-html/**	Помечены как сгенерированные артефакты
*.png, *.jpg, *.svg	Отмечены как бинарные — Git не делает diff
🧱 Как это помогает CI и линтерам

Docs-as-Code CI использует .gitattributes для:

корректного определения текстовых файлов;

исключения временных артефактов (artifacts/**);

предотвращения ошибок форматирования (разные EOL);

правильной работы линтеров (Vale, Spectral, Markdownlint).

💡 Это особенно важно при кросс-платформенной разработке (Windows + Linux).

🧩 Проверка работы
# Проверить атрибуты конкретного файла
git check-attr --all docs/README.adoc

# Проверить тип переносов строк
file docs/testcases/01_bad_markdown.md


Если Git сообщает with CRLF line terminators, значит, файл сохранён в Windows-формате и должен быть нормализован.

🧰 Как правильно обновлять .gitattributes

Внеси изменения в .gitattributes.

Проверь корректность атрибутов:

git check-attr --all docs/MP/README.md


Применить нормализацию к уже существующим файлам:

git add --renormalize .


Пересобери Docker-образ, чтобы убедиться, что CI работает корректно:

docker build -t docs-cli:ci -f .repo/Dockerfile .

⚠️ Частые ошибки и решения
Ошибка	Причина	Решение
LF will be replaced by CRLF	Git на Windows переопределяет переносы строк	git config --global core.autocrlf false
Vale не видит стили	.repo/config/.vale/styles не отмечен как text	Добавить в .gitattributes
Изображения отображаются как diff	Отсутствует binary для расширений	Добавить *.png binary, *.svg binary
Линтеры жалуются на EOL	Файлы сохранены с CRLF	Исправить: dos2unix <file> или git add --renormalize .
🧩 Рекомендации по использованию

✅ Аналитикам

Не редактировать .gitattributes без ревью DevOps.

Следить, чтобы файлы сохранялись в формате LF.

✅ Разработчикам

Проверять IDE — переносы строк LF, кодировка UTF-8.

Не коммитить бинарные файлы без причины.

✅ DevOps и Team Leads

Контролировать структуру атрибутов в CI.

Добавить защиту .gitattributes через pull request rules.

🧩 Пример минимального .gitattributes
# ─────────────────────────────────────────────
# Base text normalization
# ─────────────────────────────────────────────
* text=auto eol=lf

# ─────────────────────────────────────────────
# Documentation formats
# ─────────────────────────────────────────────
*.md   diff=markdown
*.adoc diff=asciidoc
*.yaml text
*.yml  text

# ─────────────────────────────────────────────
# Linter configs
# ─────────────────────────────────────────────
.repo/config/** linguist-documentation
.repo/ci/**      linguist-documentation

# ─────────────────────────────────────────────
# Generated outputs
# ─────────────────────────────────────────────
artifacts/**  linguist-generated
build-html/** linguist-generated

# ─────────────────────────────────────────────
# Binary files
# ─────────────────────────────────────────────
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.svg binary

✅ Итог

.gitattributes — ключевой элемент инфраструктуры Docs-as-Code, обеспечивающий:

стабильную работу CI/CD;

чистые и понятные PR;

единообразную обработку Markdown и AsciiDoc файлов;

предсказуемые результаты линтеров.