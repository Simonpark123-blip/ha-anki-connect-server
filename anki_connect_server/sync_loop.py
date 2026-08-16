import json
import sys
import time
import urllib.request
import urllib.error

interval = int(sys.argv[1])

def sync():
    payload = json.dumps({
        "action": "sync",
        "version": 6
    }).encode("utf-8")
    req = urllib.request.Request(
        "http://127.0.0.1:8765/api",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as response:
            body = response.read().decode("utf-8")
            print(f"[INFO] AnkiWeb sync: {body}", flush=True)
    except Exception as exc:
        print(f"[WARN] AnkiWeb sync failed: {exc}", flush=True)

while True:
    sync()
    time.sleep(interval)
