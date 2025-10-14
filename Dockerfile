# Универсальный и стабильный Docs-as-Code образ
FROM python:3.11-slim

LABEL maintainer="DevOps Docs-as-Code Lab"
ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git build-essential ruby-dev libxml2-dev libxslt-dev && \
    rm -rf /var/lib/apt/lists/*

# Markdown инструменты
RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli

# Python инструменты
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir mdformat

# AsciiDoc инструменты
RUN gem install --no-document asciidoctor asciidoctor-lint

# Vale (Tone-of-Voice)
RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin --strip-components=1 vale \
    && rm /tmp/vale.tar.gz

WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
