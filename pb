#!/bin/bash
#
# Pipe stdin to mudge's pastebin door (POST /api/pastebin) and print (and
# pbcopy) the omg.lol paste URL. Mudge holds the omg.lol API key so it
# doesn't have to be copied onto every machine; tailnet only, same bearer
# token as the runner report (see clients/mac/README.md in
# mudge.samhuri.net).
#
#   caddy fmt Caddyfile | pb
#   zfs list | pb tank-snapshot

set -euo pipefail

URL="${PB_URL:-http://mudge/api/pastebin}"
TOKEN_PATH="${PB_TOKEN_PATH:-$HOME/Library/Application Support/mudge-report/token}"
TITLE="${1:-}"

if [[ ! -f "$TOKEN_PATH" ]]; then
  echo "pb: no token at $TOKEN_PATH" >&2
  exit 1
fi
TOKEN=$(<"$TOKEN_PATH")

CONTENT=$(cat)

RESPONSE=$(jq -n --arg title "$TITLE" --arg content "$CONTENT" '{title: $title, content: $content}' |
  curl -sS -X POST "$URL" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-)

PASTE_URL=$(jq -r '.url // empty' <<<"$RESPONSE")
if [[ -z "$PASTE_URL" ]]; then
  echo "pb: failed to create paste" >&2
  echo "$RESPONSE" >&2
  exit 1
fi

echo "$PASTE_URL"
printf '%s' "$PASTE_URL" | pbcopy
