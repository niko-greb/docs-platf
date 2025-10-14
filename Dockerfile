FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
# Установим Ruby через RVM (чтобы не зависеть от устаревшего apt)
RUN apt-get update && apt-get install -y --no-install-recommends curl gnupg2 ca-certificates && \
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
        7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable --ruby && \
    /bin/bash -lc "rvm use ruby --default && gem install --no-document asciidoctor asciidoctor-lint"

RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm wget jq git build-essential libxml2-dev libxslt-dev && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli
RUN python3 -m pip install --upgrade pip setuptools wheel && pip install --no-cache-dir mdformat

# ✅ Устанавливаем AsciiDoctor + lint с фиксированными версиями
RUN gem install --no-document asciidoctor asciidoctor-lint

# Vale
RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin --strip-components=1 vale \
    && rm /tmp/vale.tar.gz

WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
