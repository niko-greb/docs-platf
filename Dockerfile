# syntax=docker/dockerfile:1
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /work

# --- Системные зависимости ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git build-essential ruby-dev libxml2-dev libxslt-dev zlib1g-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# --- Node.js утилиты ---
RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli

# --- Python утилиты ---
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir mdformat

# --- Ruby утилиты ---
RUN gem install --no-document asciidoctor rubocop

# Добавляем Ruby пути
ENV GEM_HOME="/usr/local/lib/ruby/gems/3.1.0"
ENV GEM_PATH="/usr/local/lib/ruby/gems/3.1.0:/root/.local/share/gem/ruby/3.3.0:/usr/local/lib/ruby/gems/3.3.0"
ENV PATH="$PATH:/usr/local/lib/ruby/gems/3.1.0/bin:/usr/local/lib/ruby/gems/3.3.0/bin"


# --- Vale ---
RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && mkdir -p /usr/local/bin/vale-bin \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin/vale-bin \
    && mv /usr/local/bin/vale-bin/vale /usr/local/bin/vale \
    && rm -rf /tmp/vale.tar.gz /usr/local/bin/vale-bin && \
    mkdir -p /work/.vale/styles && \
    vale sync || true

# --- Проверка утилит ---
RUN echo "✅ Installed tools:" && \
    markdownlint-cli2 --version && \
    spectral --version && \
    asciidoctor --version && \
    rubocop -v && \
    python3 -m mdformat --version && \
    vale --version || true

ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
