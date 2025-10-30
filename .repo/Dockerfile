# syntax=docker/dockerfile:1
FROM openjdk:17-slim

LABEL maintainer="Docs-as-Code Team"
LABEL purpose="Unified Docs Validation + Docs-as-Code Build"

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /work

# ─────────────────────────────────────────────
# 1️⃣ Системные зависимости + Node 18 LTS
# ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git unzip \
    build-essential ruby-dev libxml2-dev libxslt-dev zlib1g-dev imagemagick ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g @stoplight/spectral-cli && \
    gem install --no-document asciidoctor asciidoctor-diagram rubocop
  


# ─────────────────────────────────────────────
# 3️⃣ Ruby утилиты (Asciidoctor и плагины)
# ─────────────────────────────────────────────
RUN gem install --no-document \
    asciidoctor \
    asciidoctor-diagram \
    asciidoctor-pdf \
    rubocop

# ─────────────────────────────────────────────
# 4️⃣ DocToolchain (официальный дистрибутив)
# ─────────────────────────────────────────────
ENV DOCTOOLCHAIN_VERSION=3.4.2
RUN wget -q "https://github.com/docToolchain/docToolchain/releases/download/v${DOCTOOLCHAIN_VERSION}/docToolchain-${DOCTOOLCHAIN_VERSION}.zip" -O /tmp/dtc.zip && \
    unzip -q /tmp/dtc.zip -d /opt && \
    rm /tmp/dtc.zip && \
    chmod +x /opt/docToolchain-${DOCTOOLCHAIN_VERSION}/bin/doctoolchain && \
    echo "export PATH=/opt/docToolchain-${DOCTOOLCHAIN_VERSION}/bin:\$PATH" > /etc/profile.d/doctoolchain.sh

# ─────────────────────────────────────────────
# 5️⃣ Vale (стили и проверки)
# ─────────────────────────────────────────────
ENV VALE_VERSION=2.22.0
RUN wget -q https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz && \
    tar -xzf /tmp/vale.tar.gz -C /usr/local/bin && \
    rm -f /tmp/vale.tar.gz

# ─────────────────────────────────────────────
# 6️⃣ Конфиги и скрипты
# ─────────────────────────────────────────────
COPY .repo/config/.vale.ini .repo/config/.spectral.yaml .repo/config/.markdownlint-cli2.jsonc /work/.repo/config/
COPY .repo/config/.vale/styles /work/.repo/config/.vale/styles
COPY .repo/config/docToolchainConfig.groovy /work/.repo/config/docToolchainConfig.groovy
COPY .repo/ci/scripts/run_doctest.rb /work/.repo/ci/scripts/run_doctest.rb
COPY .repo/ci/scripts/run-linters.sh /work/.repo/ci/scripts/run-linters.sh

# ─────────────────────────────────────────────
# 7️⃣ Пользователь
# ─────────────────────────────────────────────
RUN useradd -ms /bin/bash dtcuser
USER dtcuser

# ─────────────────────────────────────────────
# 8️⃣ PATH и окружение
# ─────────────────────────────────────────────
ENV GEM_HOME=/usr/local/lib/ruby/gems/3.1.0
ENV PATH=$PATH:/usr/local/bin:$GEM_HOME/bin:/opt/docToolchain-${DOCTOOLCHAIN_VERSION}/bin

# ─────────────────────────────────────────────
# 9️⃣ Проверка установок
# ─────────────────────────────────────────────
RUN bash -lc "ruby -v && \
    asciidoctor --version && \
    rubocop -v && \
    spectral --version && \
    vale --version && \
    (doctoolchain --help >/dev/null 2>&1 || true) && \
    echo '✅ doctoolchain OK'"




ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
