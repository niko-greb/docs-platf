<!-- # 🧱 Docs-as-Code Repository

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
``` -->


# 🧱 Единая архитектура документации и кода: Docs-as-Source + Dev Sync

## 🎯 Цель
Создать прозрачную, управляемую и масштабируемую систему работы аналитиков и разработчиков  
с технической документацией и API-контрактами, обеспечив единый источник истины.

---

## 🏗️ Концепция

- **Аналитики** работают в репозитории `docs-platf` — это *источник истины* (Single Source of Truth).
- **Разработчики** работают в `dev-*` репозиториях и используют только утверждённые артефакты.
- **Связь между документацией и кодом** обеспечивается через:
  - `JIRA-ID` в коммитах и merge requests,
  - артефакты (`openapi.yaml`, схемы),
  - автоматические GitLab CI-пайплайны.

---

## ⚙️ Общая схема процесса

```mermaid
flowchart TD
    A[Аналитик обновляет ТЗ / OpenAPI в docs-platf] --> B[MR с JIRA ID и ревью аналитиков]
    B --> C[CI: валидация, проверка, публикация артефактов]
    C --> D[Артефакт OpenAPI сохраняется в GitLab Registry]
    D --> E[CI в dev-* репозиториях подхватывает обновлённый OpenAPI]
    E --> F[Разработчик вносит изменения в код]
    F --> G[Jira связывает ТЗ ↔ OpenAPI ↔ код]
    C --> H[CI публикует HTML-документацию в Confluence]
````

---

## 📂 Структура ролей

| Роль                      | Репозиторий                      | Зона ответственности                      |
| ------------------------- | -------------------------------- | ----------------------------------------- |
| 🧩 **Аналитики**          | `docs-platf`                     | ТЗ, OpenAPI, UML, схемы, бизнес-логика    |
| 💻 **Разработчики**       | `dev-pos`, `dev-web`, `dev-back` | Код, SDK, тесты                           |
| ⚙️ **Team Lead / DevOps** | оба                              | Настройка CI/CD, артефакты, синхронизация |

---

## 🔁 CI/CD Поток

### 🧩 Этап 1 — Работа аналитиков (в `docs-platf`)

1. Аналитик обновляет `docs/api/openapi.yaml`.
2. Указывает `JIRA-123` в названии ветки и коммите.
3. Создаёт **MR → проходит ревью**.
4. После merge:

   * выполняется CI-валидация (Vale, Spectral, AsciiDoctor);
   * результат публикуется в Confluence;
   * файл `openapi.yaml` сохраняется как артефакт.

#### Пример `.gitlab-ci.yml` для `docs-platf`

```yaml
stages:
  - validate
  - publish
  - artifacts

validate_docs:
  stage: validate
  image: docs-cli:ci
  script:
    - bash .repo/ci/scripts/run-linters.sh
  artifacts:
    paths:
      - artifacts/
    expire_in: 1 week

publish_confluence:
  stage: publish
  image: docs-cli:ci
  script:
    - doctoolchain . publishConfluence -PconfigFile=.repo/config/docToolchainConfig.groovy
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'

upload_artifacts:
  stage: artifacts
  script:
    - echo "📦 Uploading OpenAPI spec to GitLab Registry"
  artifacts:
    paths:
      - docs/api/openapi.yaml
  only:
    - main
```

---

### 💻 Этап 2 — Работа разработчиков (в `dev-*`)

1. При изменении артефакта (webhook или cron) CI скачивает обновлённый `openapi.yaml` из `docs-platf`.
2. Сохраняет его в `src/api/specs/openapi.yaml`.
3. Проверяет наличие Jira ID.
4. Генерирует Swagger UI или SDK.

#### Пример `.gitlab-ci.yml` для `dev-*`

```yaml
stages:
  - sync
  - build

sync_docs:
  stage: sync
  script:
    - echo "⬇️ Fetching latest OpenAPI spec from docs-platf..."
    - curl -L "$CI_API_V4_URL/projects/<ID_DOCS_PLATF>/jobs/artifacts/main/raw/docs/api/openapi.yaml?job=upload_artifacts" -o src/api/specs/openapi.yaml
    - echo "✅ Synced OpenAPI spec"
  only:
    - main
  rules:
    - changes:
        - src/api/specs/*
        - .gitlab-ci.yml

build:
  stage: build
  script:
    - echo "🚀 Build application with updated OpenAPI spec"
```

---

## 🧱 Схематично

```
       +-----------------------+
       |    Confluence Cloud   |
       | (авто-публикация CI)  |
       +-----------^-----------+
                   |
                   |
           +-------+--------+
           |   docs-platf   |   ← Источник истины
           |----------------|
           | openapi.yaml   |
           | *.adoc (ТЗ)    |
           | *.png, *.uml   |
           +-------+--------+
                   |
                   | GitLab Artifact / Registry
                   ↓
         +---------+-----------+
         |      dev-pos        |
         |      dev-web        |
         |      dev-back       |
         +---------------------+
                   ↓
               Jira Issues
```

---

## ✅ Преимущества

| Категория                  | Преимущество                                              |
| -------------------------- | --------------------------------------------------------- |
| **Контроль качества**      | Все изменения API проходят через ревью аналитиков.        |
| **Трассировка**            | Jira ID связывает бизнес-требование ↔ документацию ↔ код. |
| **Единый источник истины** | OpenAPI и схемы не расходятся между командами.            |
| **CI-автоматизация**       | Реплики и публикации происходят без ручных действий.      |
| **Confluence Sync**        | Документация доступна менеджерам без доступа к GitLab.    |

---

## ⚠️ Возможные сложности

| Проблема                                    | Решение                                                                             |
| ------------------------------------------- | ----------------------------------------------------------------------------------- |
| Разработчики хотят тестировать API до ревью | разрешить `feature`-ветки с локальными `.yaml`, но в мейн — только из `docs-platf`. |
| Подрядчики без доступа к docs-platf         | CI может получать артефакт по публичному read-token.                                |
| Несовпадение версий                         | Версионировать артефакты (`openapi-v2025.10.yaml`) и тегировать GitLab releases.    |
| Много CI цепочек                            | Использовать единый Docker-образ `docs-cli:ci` для всех проверок и публикаций.      |

---

## 🔗 Интеграция с Jira

* Каждый MR должен содержать ссылку на задачу Jira (`JIRA-123`).
* CI валидирует наличие Jira ID.
* После мёржа в main:

  * Confluence получает обновление страницы;
  * Jira-таска автоматически помечается как “Документация опубликована”.

---

## 📘 Резюме

| Область                    | Источник               |
| -------------------------- | ---------------------- |
| **ТЗ, схемы, UML**         | `docs-platf`           |
| **OpenAPI (артефакт)**     | `docs-platf` → `dev-*` |
| **Реализация и код**       | `dev-*`                |
| **Публикация для бизнеса** | Confluence             |
| **Связь и трассировка**    | Jira                   |

---

## 🚀 Результат

* Прозрачный и согласованный документооборот между командами.
* Единая точка ревью и контроля качества документации.
* Полная трассировка от бизнес-требования до кода.
* Автоматическая синхронизация между GitLab, Jira и Confluence.

```

---

⚙️ 1. Процесс работы: один репозиторий для аналитика и разработчика
🔹 Цель

Создать единый жизненный цикл задачи (от ТЗ до кода), но при этом сохранить возможность передачи итоговой документации в общий репозиторий данных / документации (docs-platf, например).

🧭 Общий сценарий
Этап	Действие	Ответственный	Результат
1. Постановка задачи	В Jira создаётся задача (с ID, например PLATF-123)	Аналитик	В задаче указываются ссылки на репозиторий разработки
2. Создание ветки	Создаётся ветка feature/PLATF-123	Разработчик	Одна ветка на задачу
3. Создание документации	Аналитик добавляет/редактирует .adoc, .yaml (OpenAPI), README и т.д.	Аналитик	ТЗ, API, схемы, описание требований
4. Разработка	Разработчик пишет код и добавляет комментарии / примеры в тех же папках	Разработчик	Синхронизированная ветка: код + доки
5. CI проверка	docs-ci.yml валидирует документацию (Vale, linters, doctoolchain и т.д.)	CI	Отчёты об ошибках в PR
6. Ревью документации	Аналитик проверяет, что OpenAPI и README актуальны	Аналитик	Одобрение merge
7. Merge feature → main	После ревью код и доки попадают в main	TL / Maintainer	Стабильная версия документации
8. Синхронизация с репо документации	Автоматический pipeline переносит docs-файлы из main → docs-platf	CI (через token / PR)	Вся актуальная документация на центральном портале (Confluence / GitHub Pages)
🧰 2. Что меняется в CI/CD

Теперь про самое важное — архитектуру CI и где должен быть Docker worker.

🔸 Принципиальная идея

Каждый репозиторий (аналитика + разработка) должен:

Иметь локальный CI, чтобы проверять свою документацию (docs-ci.yml).

Не дублировать тяжёлые зависимости (Vale, doctoolchain, Ruby и т.д.) — они будут в Docker image (docs-cli:ci).

После merge — триггерить экспорт документации в общий репозиторий (docs-platf).

🧩 Конфигурация по шагам
🔹 A. Репозиторий разработчиков (или общий dev-repo)

CI использует docs-cli:ci (через docker build или pull).

Выполняет:

Vale, markdownlint, asciidoctor проверки.

Проверку на наличие Jira ID в PR.

Проверку связности OpenAPI ↔ ТЗ (при наличии).

При merge в main запускает второй job:

jobs:
  sync-docs:
    needs: docs-validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 🧩 Push docs to platform repo
        run: |
          git clone https://github.com/org/docs-platf.git
          cp -r docs/* docs-platf/${{ github.repository }}
          cd docs-platf
          git add .
          git commit -m "Sync docs from ${{ github.repository }} (${{ github.sha }})"
          git push origin main

🔹 B. Репозиторий docs-platf (хранилище документации)

CI уже занимается сборкой HTML/PDF/Pages.

Работает с тем же образом docs-cli:ci.

Основные задачи:

doctoolchain generateHTML

Сборка GitHub Pages / Confluence Sync

Проверка на дублирующиеся документы

🔹 C. Docker Worker

✅ Да, нужен в каждом репозитории.
Но образ один и тот же — docs-cli:ci, который мы уже готовим.

Ты можешь хранить его в:

GitHub Container Registry (ghcr.io/org/docs-cli:ci)

или локальном Docker Hub

Тогда в docs-ci.yml вместо docker build можно просто делать docker pull:

- name: 🧰 Pull Docs CLI image
  run: docker pull ghcr.io/org/docs-cli:ci:latest

🧠 Что это даёт
Задача	Решение
Разделение ответственности	Аналитики и разработчики работают в одном потоке
Повторное использование инструментов	Один Docker образ, однотипный CI
Централизация публикаций	docs-platf хранит «чистые» артефакты
Масштабируемость	Можно добавить интеграцию с Jira, Confluence, GitLab Pages без дублирования
