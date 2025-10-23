# syntax=docker/dockerfile:1
FROM gradle:8.10-jdk17-slim

LABEL maintainer="Docs-as-Code Team"
LABEL purpose="Docs CI & doctoolchain integration"

WORKDIR /work

# ─────────────────────────────────────────────
# 1️⃣ Устанавливаем системные зависимости
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm python3 python3-pip git wget unzip imagemagick \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# 2️⃣ Node.js линтеры
# ─────────────────────────────────────────────
RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli

# ─────────────────────────────────────────────
# 3️⃣ Python форматтер
# ─────────────────────────────────────────────
RUN pip3 install --no-cache-dir mdformat

# ─────────────────────────────────────────────
# 4️⃣ Ruby — Asciidoctor
# ─────────────────────────────────────────────
RUN gem install --no-document asciidoctor

# ─────────────────────────────────────────────
# 5️⃣ Vale — стиль и терминология
# ─────────────────────────────────────────────
ENV VALE_VERSION=v2.27.1
RUN wget -q https://github.com/errata-ai/vale/releases/download/${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin && rm /tmp/vale.tar.gz

# ─────────────────────────────────────────────
# 6️⃣ doctoolchain
# ─────────────────────────────────────────────
RUN mkdir -p /opt/doctoolchain && \
    wget -q https://github.com/docToolchain/docToolchain/releases/download/v3.2.2/doctoolchain.zip -O /tmp/doctoolchain.zip && \
    unzip -q /tmp/doctoolchain.zip -d /opt/doctoolchain && rm /tmp/doctoolchain.zip

ENV PATH="/opt/doctoolchain/bin:${PATH}"

# ─────────────────────────────────────────────
# 7️⃣ Проверка установленных утилит
# ─────────────────────────────────────────────
RUN echo "✅ Installed tools:" && \
    asciidoctor --version && \
    markdownlint-cli2 --version && \
    spectral --version && \
    vale --version && \
    gradle --version

ENTRYPOINT ["/bin/bash", "-lc"]
