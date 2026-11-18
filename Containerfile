# syntax=docker/dockerfile:1

FROM python:3.14-slim

# Package specs are ARGs so the image can be rebuilt with pinned versions:
#   docker build --build-arg DEVPI_SERVER="devpi-server==6.10.0" .
ARG DEVPI_SERVER="devpi-server"
ARG DEVPI_WEB="devpi-web"
ARG DEVPI_CLIENT="devpi-client"

LABEL org.opencontainers.image.title="devpi" \
      org.opencontainers.image.description="devpi server (private PyPI index and caching proxy)" \
      org.opencontainers.image.source="https://github.com/khrpcek/devpi" \
      org.opencontainers.image.licenses="MIT"

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEVPI_DATA_DIR=/data \
    DEVPI_PORT=3141

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir "$DEVPI_SERVER" "$DEVPI_WEB" "$DEVPI_CLIENT"

COPY devpi-entrypoint.sh /usr/local/bin/devpi-entrypoint.sh
RUN chmod +x /usr/local/bin/devpi-entrypoint.sh \
 && groupadd --gid 1000 devpi \
 && useradd --uid 1000 --gid devpi --create-home --home-dir /home/devpi devpi \
 && mkdir -p /data \
 && chown -R devpi:devpi /data

USER 1000:1000
WORKDIR /home/devpi
EXPOSE 3141
VOLUME /data

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/' % os.environ.get('DEVPI_PORT', '3141'))"

ENTRYPOINT ["/usr/local/bin/devpi-entrypoint.sh"]
