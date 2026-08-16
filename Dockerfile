FROM python:3.12-slim

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL   io.hass.version="${BUILD_VERSION}"   io.hass.type="app"   io.hass.arch="${BUILD_ARCH}"

WORKDIR /app

RUN pip install --no-cache-dir --disable-pip-version-check anki-connect-server==0.2.0

COPY run.sh /run.sh
COPY sync_loop.py /sync_loop.py

RUN chmod +x /run.sh

EXPOSE 8765

CMD ["/run.sh"]
