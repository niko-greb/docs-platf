FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git build-essential libxml2-dev libxslt-dev && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli
RUN python3 -m pip install --upgrade pip setuptools wheel && pip install --no-cache-dir mdformat

# ✅ Устанавливаем AsciiDoctor + lint с фиксированными версиями
RUN gem install --no-document asciidoctor -v 2.0.20 && \
    gem install --no-document rubocop -v 1.62.0 && \
    gem install --no-document asciidoctor-lint -v 0.2.0

# Vale
RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin --strip-components=1 vale \
    && rm /tmp/vale.tar.gz

WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
