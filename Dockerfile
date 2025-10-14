FROM ruby:3.2-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip nodejs npm wget jq && \
    rm -rf /var/lib/apt/lists/*

RUN npm install -g markdownlint-cli2 @stoplight/spectral-cli
RUN pip3 install mdformat

RUN gem install --no-document asciidoctor asciidoctor-lint

RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin --strip-components=1 vale \
    && rm /tmp/vale.tar.gz

WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready' && bash"]
