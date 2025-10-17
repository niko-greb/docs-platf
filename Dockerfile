FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full nodejs npm wget jq git build-essential ruby-dev libxml2-dev libxslt-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*
 
RUN npm install markdownlint-cli2 markdownlint --save-dev    
RUN npm install -g @stoplight/spectral-cli
RUN python3 -m pip install --upgrade pip setuptools wheel && pip install --no-cache-dir mdformat

# ✅ Ruby tools: AsciiDoctor и asciidoctor-lint с GitHub
RUN gem install --no-document asciidoctor rubocop asciidoctor-doctest

# Vale
RUN wget -q https://github.com/errata-ai/vale/releases/download/v2.22.0/vale_2.22.0_Linux_64-bit.tar.gz -O /tmp/vale.tar.gz \
    && tar -xzf /tmp/vale.tar.gz -C /usr/local/bin --strip-components=1 vale \
    && rm /tmp/vale.tar.gz

WORKDIR /work
ENTRYPOINT ["/bin/bash", "-lc"]
CMD ["echo 'Docs-as-Code CLI ready ✅' && bash"]
