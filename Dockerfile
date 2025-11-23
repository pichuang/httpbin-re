FROM docker.io/library/ubuntu:22.04

LABEL org.opencontainers.image.title="httpbin-re" \
      org.opencontainers.image.description="HTTP Request and Response Service" \
      org.opencontainers.image.authors="Kenneth Reitz, Phil Huang <phil.huang@microsoft.com>" \
      org.opencontainers.image.source="https://github.com/pichuang/httpbin-re" \
      org.opencontainers.image.licenses="ISC License" \
      org.opencontainers.image.url="https://httpbin.org" \
      org.opencontainers.image.version="20251123" \
      org.opencontainers.image.base.name="library/ubuntu:22.04"

RUN apt update -y && \
      apt install python3-pip -y && \
      pip3 install --upgrade pip

ADD . /httpbin-re
WORKDIR /httpbin-re

# Default values for Swagger
ARG TITLE="httpbin-re" \
    DESCRIPTION="PING & PONG"
ENV SWAGGER_TITLE=$TITLE \
    SWAGGER_DESCRIPTION=$DESCRIPTION

RUN pip3 install --no-cache-dir -r requirements.txt && \
      pip3 install --no-cache-dir /httpbin-re

EXPOSE 80

CMD ["gunicorn", "-b", "0.0.0.0:80", "httpbin:app", "-k", "gevent"]