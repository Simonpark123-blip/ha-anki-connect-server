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

if [ -f "$ANKI_COLLECTION_PATH" ]; then
    chmod 666 "$ANKI_COLLECTION_PATH"
fi

if [ ! -f "$ANKI_COLLECTION_PATH" ]; then
    echo "[ERROR] Collection not found: $ANKI_COLLECTION_PATH"
    echo "[ERROR] Create /share/anki and place your initial collection.anki21 there."
    exit 1
fi
echo "[DEBUG] User:"
id

echo "[DEBUG] /share:"
ls -ld /share

echo "[DEBUG] /share/anki:"
ls -ld /share/anki

echo "[DEBUG] Collection:"
ls -l "$ANKI_COLLECTION_PATH"

echo "[DEBUG] Write test:"
touch /share/anki/.anki_write_test
ls -l /share/anki/.anki_write_test
rm -f /share/anki/.anki_write_test

echo "[DEBUG] Python SQLite test:"
python - <<'PY'
import sqlite3

path = "/share/anki/collection.anki21"

print("Opening:", path)

try:
    db = sqlite3.connect(path)
    print("SQLite OPEN OK")
    db.execute("PRAGMA journal_mode")
    print("Journal mode OK")
    db.close()
except Exception as e:
    print("SQLite ERROR:", repr(e))
    raise
PY
echo "[INFO] Starting AnkiConnect on 0.0.0.0:8765"
echo "[INFO] Collection: $ANKI_COLLECTION_PATH"
echo "[INFO] AnkiWeb sync interval: ${SYNC_INTERVAL}s"

cd /share/anki

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