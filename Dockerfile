# ===========================
# 📦 Docs CI Image (Universal)
# ===========================
FROM node:18-slim

# Устанавливаем системные утилиты и пакеты
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ruby-full \
      python3-pip \
      git \
      curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Устанавливаем линтеры и утилиты
RUN npm install -g \
      markdownlint-cli2 \
      markdownlint \
      @stoplight/spectral-cli && \
    pip3 install mdformat && \
    gem install --no-document asciidoctor && \
    gem install --no-document asciidoctor-doctest && \
    gem install --no-document rubocop

# Настраиваем рабочую директорию
WORKDIR /work
ENTRYPOINT ["/bin/bash"]
