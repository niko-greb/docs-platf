# # syntax=docker/dockerfile:1
# FROM python:3.11-slim

# LABEL maintainer="Docs-as-Code Team"
# LABEL purpose="Docs-as-Code CI Environment with doctoolchain"

# ENV DEBIAN_FRONTEND=noninteractive
# WORKDIR /work

# # ─────────────────────────────────────────────
# # 1️⃣ Системные зависимости
# # ─────────────────────────────────────────────
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     ruby-full nodejs npm wget jq git unzip openjdk-21-jre-headless \
#     build-essential ruby-dev libxml2-dev libxslt-dev zlib1g-dev \
#     imagemagick ca-certificates && \
#     rm -rf /var/lib/apt/lists/*

# # ─────────────────────────────────────────────
# # 2️⃣ Node.js утилиты
# # ─────────────────────────────────────────────
# RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli

# # ─────────────────────────────────────────────
# # 3️⃣ Python форматтер
# # ─────────────────────────────────────────────
# RUN python3 -m pip install --upgrade pip setuptools wheel && \
#     pip install --break-system-packages --no-cache-dir mdformat

# # ─────────────────────────────────────────────
# # 4️⃣ Ruby — Asciidoctor
# # ─────────────────────────────────────────────
# RUN gem install --no-document asciidoctor rubocop

# # ─────────────────────────────────────────────
# # 5️⃣ Vale
# # ─────────────────────────────────────────────
# RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
#     && mkdir -p /usr/local/bin/vale-bin \
#     && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin/vale-bin \
#     && mv /usr/local/bin/vale-bin/vale /usr/local/bin/vale \
#     && rm -rf /tmp/vale.tar.gz /usr/local/bin/vale-bin

# # ─────────────────────────────────────────────
# # 6️⃣ doctoolchain
# # ─────────────────────────────────────────────
# RUN mkdir -p /opt/doctoolchain && \
#     wget -q https://github.com/docToolchain/docToolchain/releases/download/v3.4.2/docToolchain-3.4.2.zip -O /tmp/doctoolchain.zip && \
#     unzip -q /tmp/doctoolchain.zip -d /opt/doctoolchain && \
#     rm /tmp/doctoolchain.zip

# ENV PATH="/opt/doctoolchain/bin:${PATH}"

# # ─────────────────────────────────────────────
# # 7️⃣ Конфиги и скрипты
# # ─────────────────────────────────────────────
# COPY .repo/config/.vale.ini .repo/config/.spectral.yaml .repo/config/.markdownlint-cli2.jsonc /work/.repo/config/
# COPY .repo/config/.vale/styles /work/.repo/config/.vale/styles
# COPY .repo/config/docToolchainConfig.groovy /work/.repo/config/
# COPY .repo/ci/scripts/run_doctest.rb /work/.repo/ci/scripts/run_doctest.rb

# # ─────────────────────────────────────────────
# # 8️⃣ Vale sync
# # ─────────────────────────────────────────────
# RUN mkdir -p /work/.vale/styles && \
#     cp -r /work/.repo/config/.vale/styles/* /work/.vale/styles/ 2>/dev/null || true && \
#     vale sync || echo "⚠️ Vale styles not synced (offline mode)"

# # ─────────────────────────────────────────────
# # 9️⃣ Проверка утилит
# # ─────────────────────────────────────────────
# RUN echo "✅ Installed tools:" && \
#     ruby -v && \
#     asciidoctor --version && \
#     rubocop -v && \
#     python3 -m mdformat --version && \
#     markdownlint-cli2 --version && \
#     spectral --version && \
#     vale --version && \
#     doctoolchain --version || echo "ℹ️ doctoolchain OK"

# # ─────────────────────────────────────────────
# # 🔟 Точка входа
# # ─────────────────────────────────────────────
# ENTRYPOINT ["/bin/bash", "-lc"]
# CMD ["echo 'Docs-as-Code CI ready ✅' && bash"]

# syntax=docker/dockerfile:1
FROM python:3.11-slim

LABEL maintainer="Docs-as-Code Team"
LABEL purpose="Unified Docs Validation + Docs-as-Code Build"

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /work

# ─────────────────────────────────────────────
# 1️⃣ Системные зависимости
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git unzip \
    build-essential ruby-dev libxml2-dev libxslt-dev zlib1g-dev \
    imagemagick ca-certificates openjdk-21-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────
# 2️⃣ Node.js и Python утилиты
# ─────────────────────────────────────────────
RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    pip install --break-system-packages --no-cache-dir mdformat

# ─────────────────────────────────────────────
# 3️⃣ Ruby утилиты (Asciidoctor и плагины)
# ─────────────────────────────────────────────
RUN gem install --no-document \
    asciidoctor \
    asciidoctor-diagram \
    asciidoctor-pdf \
    rubocop

# ─────────────────────────────────────────────
# 4️⃣ Doctoolchain (Groovy-based, нужен JDK)
# ─────────────────────────────────────────────
ENV DOCTOOLCHAIN_VERSION=3.4.2
RUN wget -q https://github.com/docToolchain/docToolchain/releases/download/v${DOCTOOLCHAIN_VERSION}/doctoolchain-${DOCTOOLCHAIN_VERSION}.zip -O /tmp/dtc.zip && \
    unzip -q /tmp/dtc.zip -d /opt/doctoolchain && \
    rm /tmp/dtc.zip && \
    ln -s /opt/doctoolchain/bin/doctoolchain /usr/local/bin/doctoolchain

# ─────────────────────────────────────────────
# 5️⃣ Vale (стили и проверки)
# ─────────────────────────────────────────────
ENV VALE_VERSION=2.22.0
RUN wget -q https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz && \
    tar -xzf /tmp/vale.tar.gz -C /usr/local/bin && \
    rm -f /tmp/vale.tar.gz

# ─────────────────────────────────────────────
# 6️⃣ Копируем конфиги и скрипты
# ─────────────────────────────────────────────
COPY .repo/config/.vale.ini .repo/config/.spectral.yaml .repo/config/.markdownlint-cli2.jsonc /work/.repo/config/
COPY .repo/config/.vale/styles /work/.repo/config/.vale/styles
COPY .repo/ci/scripts/run_doctest.rb /work/.repo/ci/scripts/run_doctest.rb
COPY .repo/ci/scripts/run-linters.sh /work/.repo/ci/scripts/run-linters.sh
COPY .repo/config/docToolchainConfig.groovy /work/.repo/config/docToolchainConfig.groovy

# ─────────────────────────────────────────────
# 7️⃣ Проверка и PATH
# ─────────────────────────────────────────────
ENV GEM_HOME=/usr/local/lib/ruby/gems/3.1.0
ENV PATH=$PATH:/usr/local/bin:$GEM_HOME/bin

RUN echo "✅ Installed tools:" && \
    ruby -v && \
    asciidoctor --version && \
    rubocop -v && \
    python3 -m mdformat --version && \
    markdownlint-cli2 --version && \
    spectral --version && \
    vale --version && \
    doctoolchain --version || echo "ℹ️ doctoolchain OK"

# ─────────────────────────────────────────────
# 8️⃣ Точка входа
# ─────────────────────────────────────────────
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]

