# AnkiConnect Server for Home Assistant OS

This is a local Home Assistant OS app wrapping `anki-connect-server` 0.2.0.

## What it provides

- AnkiConnect v6 REST API on TCP 8765
- Headless operation; Anki Desktop is not required
- AnkiWeb credentials configured from the HA app UI
- Automatic periodic `sync` calls (default: every 5 minutes)
- Persistent collection stored in `/share/anki/collection.anki21`

## Initial collection

The server requires an existing `.anki21` collection. Before first start, sync Anki Desktop with AnkiWeb and copy a copy of the collection to:

`/share/anki/collection.anki21`

Do not use a collection that is currently open by Anki Desktop.

## API

POST to:

`http://<HA-IP>:8765/api`

Example:

`{"action":"deckNames","version":6}`

## Important

The app is marked experimental because `anki-connect-server` is a young third-party project. Back up your Home Assistant installation and your Anki collection before using it.
