# Base image pinned for reproducible builds
FROM docker.io/library/ubuntu:24.04

# Suppress interactive prompts during apt operations
ARG DEBIAN_FRONTEND=noninteractive

# OCI metadata so the image stays self-describing
LABEL org.opencontainers.image.title="httpbin-re" \
        org.opencontainers.image.description="HTTP Request and Response Service" \
        org.opencontainers.image.authors="Kenneth Reitz, Phil Huang <phil.huang@microsoft.com>" \
        org.opencontainers.image.source="https://github.com/pichuang/httpbin-re" \
        org.opencontainers.image.licenses="ISC License" \
        org.opencontainers.image.url="https://httpbin.org" \
        org.opencontainers.image.version="20251123" \
        org.opencontainers.image.base.name="library/ubuntu:24.04"

# Python virtual environment plus pip defaults (no cache, quiet upgrades)
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /httpbin-re

# Install Python dependencies first for better layer caching
COPY requirements.txt ./

# Build tooling + venv setup happen in one layer to simplify cleanup
RUN set -eux; \
      apt-get update; \
      apt-get install -y --no-install-recommends python3 python3-venv python3-pip python3-dev build-essential ca-certificates; \
      python3 -m venv "$VIRTUAL_ENV"; \
      "$VIRTUAL_ENV/bin/pip" install --upgrade pip --break-system-packages; \
      "$VIRTUAL_ENV/bin/pip" install --no-cache-dir --break-system-packages -r requirements.txt; \
      rm -rf /var/lib/apt/lists/*

# Copy the rest of the application code
COPY . ./

# Default values for Swagger
ARG TITLE="httpbin-re" \
      DESCRIPTION="PING & PONG"
ENV SWAGGER_TITLE=$TITLE \
      SWAGGER_DESCRIPTION=$DESCRIPTION

# Install the project itself, then strip build-only packages to shrink the image
RUN set -eux; \
      "$VIRTUAL_ENV/bin/pip" install --no-cache-dir --break-system-packages .; \
      apt-get purge -y --auto-remove build-essential python3-dev python3-pip python3-venv; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

CMD ["gunicorn", "-b", "0.0.0.0:80", "httpbin:app", "-k", "gevent"]