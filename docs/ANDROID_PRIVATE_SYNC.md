# Android private sync (Phase 1)

Thorium's Android private-sync client is a pull-only importer for history and
bookmarks. It does not use Google Sync and it does not upload Android browsing
data in Phase 1.

## Configure

1. Create a dedicated Android device in `thorium-syncctl`. Do not reuse the
   desktop extension's client JSON: changes from the requesting device are
   deliberately skipped while their cursor positions are consumed.
2. In Thorium for Android, open **Settings > Private sync**.
3. Paste the dedicated Android client JSON and save it.
4. Tap **Sync now**, or bring Thorium back to the foreground.

The accepted v1 JSON has exactly these fields:

```json
{
  "version": 1,
  "base_url": "https://sync.aeutlook.com/<random-prefix>",
  "device_id": "<32 lowercase hex characters>",
  "device_name": "Thorium Android",
  "device_token": "ts1_<43 unpadded base64url characters>",
  "encryption_key": "<43 unpadded base64url characters>"
}
```

The URL is restricted to HTTPS, the exact `sync.aeutlook.com` host, and one
24-128 character base-path segment. The token and encryption key are never
compiled into the APK.

## Local and transport security

- The canonical client JSON is encrypted as one AES-GCM record with an
  Android Keystore key. SharedPreferences contains only the versioned nonce
  and ciphertext.
- Requests omit cookies, reject redirects, disable cache, and send the device
  token only as a Bearer header over HTTPS.
- Entity payloads use AES-256-GCM with the protocol v1 associated data:
  `thorium-sync-v1\n<kind>\n<entity_id>\n<operation>`.
- Delete tombstones must also carry a valid encrypted payload. Missing,
  malformed, or unauthenticated tombstones are consumed without deleting
  local data.
- A hash of `base_url`, `device_id`, and the account encryption key namespaces
  the local cursor and imported bookmark root. Rotating only the revocable
  device token preserves progress.

## Cursor and retry behavior

Responses are accepted only when their sequence numbers are strictly
increasing and do not exceed `next_cursor`. An in-process per-sequence
checkpoint prevents the successful prefix of a failed batch from being
applied again. The public cursor advances only after the complete response has
been handed to Chromium's History and Bookmark services. `has_more` pages
continue immediately and are not blocked by the normal foreground/manual
request throttle. Pull requests have a 30-second timeout.

## Phase 1 limits

- Imported: history and bookmarks.
- Not imported: passwords, settings, tabs, large blobs, or arbitrary future
  entity kinds.
- Android is pull-only. Desktop producers remain responsible for pushes.
- Imported bookmarks live below a fingerprinted **Private Sync** folder in
  Mobile bookmarks.
- History and bookmark persistence is asynchronous in Chromium. Phase 1 does
  not yet have a transactional local inbox spanning History, Bookmarks, and
  the cursor; a process or power failure inside that persistence window can
  lose a just-imported item, and an interrupted history retry can duplicate a
  visit. A crash-atomic revision needs a dedicated durable inbox plus
  URL-and-visit-time idempotency before cursor commit.
- History delete lookup currently uses a profile preference mapping. A future
  high-volume revision should move the durable inbox, entity mapping, and
  materialization status to a dedicated local database.
