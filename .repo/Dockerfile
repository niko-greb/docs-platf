# syntax=docker/dockerfile:1
FROM python:3.11-slim

LABEL maintainer="Docs-as-Code Team"
LABEL purpose="Unified Docs Linter Environment"

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /work

# ─────────────────────────────────────────────
# 1️⃣ Системные и языковые зависимости
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git build-essential ruby-dev \
    libxml2-dev libxslt-dev zlib1g-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    npm install -g markdownlint-cli2 @stoplight/spectral-cli && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    pip install --break-system-packages --no-cache-dir mdformat && \
    gem install --no-document asciidoctor rubocop

# ─────────────────────────────────────────────
# 2️⃣ Vale
# ─────────────────────────────────────────────

RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && mkdir -p /usr/local/bin/vale-bin \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin/vale-bin \
    && mv /usr/local/bin/vale-bin/vale /usr/local/bin/vale \
    && rm -rf /tmp/vale.tar.gz /usr/local/bin/vale-bin

# ─────────────────────────────────────────────
# 3️⃣ Конфиги и скрипты
# ─────────────────────────────────────────────
COPY .repo/config/.vale.ini .repo/config/.spectral.yaml .repo/config/.markdownlint-cli2.jsonc /work/.repo/config/
COPY .repo/config/.vale/styles /work/.repo/config/.vale/styles
COPY .repo/ci/scripts/run_doctest.rb /work/.repo/ci/scripts/run_doctest.rb

# ─────────────────────────────────────────────
# 4️⃣ Настройка Vale
# ─────────────────────────────────────────────
RUN mkdir -p /work/.vale/styles && \
    cp -r /work/.repo/config/.vale/styles/* /work/.vale/styles/ 2>/dev/null || true && \
    vale sync || echo "⚠️ Vale styles not synced (offline mode)"

# ─────────────────────────────────────────────
# 5️⃣ Проверка утилит
# ─────────────────────────────────────────────
RUN echo "✅ Installed tools:" && \
    ruby -v && \
    asciidoctor --version && \
    rubocop -v && \
    python3 -m mdformat --version && \
    markdownlint-cli2 --version && \
    spectral --version && \
    vale --version

# ─────────────────────────────────────────────
# 6️⃣ Точка входа
# ─────────────────────────────────────────────
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]