#!/bin/sh
set -eu

OPTIONS=/data/options.json

ANKIWEB_USER="$(python -c 'import json; print(json.load(open("/data/options.json")).get("ankiweb_user",""))')"
ANKIWEB_PASS="$(python -c 'import json; print(json.load(open("/data/options.json")).get("ankiweb_password",""))')"
SYNC_INTERVAL="$(python -c 'import json; print(json.load(open("/data/options.json")).get("sync_interval",300))')"
FULL_UPLOAD="$(python -c 'import json; print(str(json.load(open("/data/options.json")).get("full_upload",False)).lower())')"

export ANKI_COLLECTION_PATH="/share/anki/collection.anki21"
export ANKICONNECT_PORT="8765"
export ANKICONNECT_BIND="0.0.0.0"
export ANKICONNECT_ANKIWEB_USER="$ANKIWEB_USER"
export ANKICONNECT_ANKIWEB_PASS="$ANKIWEB_PASS"
export ANKICONNECT_FULL_UPLOAD="$FULL_UPLOAD"

mkdir -p /share/anki
chmod 777 /share/anki

echo "===== ANKI DEBUG ====="
echo "[DEBUG] PWD:"
pwd

echo "[DEBUG] /app:"
ls -la /app || true

echo "[DEBUG] /share:"
ls -la /share || true

echo "[DEBUG] /share/anki:"
ls -la /share/anki || true

echo "[DEBUG] Collection:"
ls -la "$ANKI_COLLECTION_PATH" || true

echo "[DEBUG] Collection directory:"
ls -ld /share/anki || true

echo "[DEBUG] Collection stat:"
stat "$ANKI_COLLECTION_PATH" || true

echo "[DEBUG] Collection permissions:"
ls -l "$ANKI_COLLECTION_PATH" || true

echo "===== END DEBUG ====="

if [ -f "$ANKI_COLLECTION_PATH" ]; then
    chmod 666 "$ANKI_COLLECTION_PATH"
else
    echo "[ERROR] Collection not found: $ANKI_COLLECTION_PATH"
    exit 1
fi

if [ ! -f "$ANKI_COLLECTION_PATH" ]; then
    echo "[ERROR] Collection not found: $ANKI_COLLECTION_PATH"
    echo "[ERROR] Create /share/anki and place your initial collection.anki21 there."
    exit 1
fi

echo "[INFO] Starting AnkiConnect on 0.0.0.0:8765"
echo "[INFO] Collection: $ANKI_COLLECTION_PATH"
echo "[INFO] AnkiWeb sync interval: ${SYNC_INTERVAL}s"

python -m uvicorn anki_connect_server.api:app --host 0.0.0.0 --port 8765 &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

sleep 3

python /sync_loop.py "$SYNC_INTERVAL" &
SYNC_PID=$!

wait "$SERVER_PID"
kill "$SYNC_PID" 2>/dev/null || true