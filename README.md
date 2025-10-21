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
