#!/bin/bash
#
# Pipe stdin to mudge's pastebin door (POST /api/pastebin) and print (and
# pbcopy) the omg.lol paste URL. Mudge holds the omg.lol API key so it
# doesn't have to be copied onto every machine; tailnet only, same bearer
# token as the runner report (see clients/mac/README.md in
# mudge.samhuri.net).
#
# Reading one back doesn't touch mudge at all: omg.lol serves a paste's raw
# content with no auth, so `-r` fetches it straight from paste.lol.
#
#   caddy fmt Caddyfile | pb
#   zfs list | pb tank-snapshot
#   pb -r https://sjs.paste.lol/tank-snapshot
#   pb -r tank-snapshot

set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "usage: pb [TITLE] < content"
  echo "       pb -r URL|TITLE"
  exit 0
fi

if [[ "${1:-}" == "-r" || "${1:-}" == "--read" ]]; then
  REF="${2:-}"
  if [[ -z "$REF" ]]; then
    echo "usage: pb -r URL|TITLE" >&2
    exit 1
  fi
  case "$REF" in
    http://* | https://*)
      RAW_URL="${REF%/raw}"
      RAW_URL="${RAW_URL%/}/raw"
      ;;
    *)
      RAW_URL="https://${PB_ADDRESS:-sjs}.paste.lol/${REF}/raw"
      ;;
  esac

  BODY_FILE=$(mktemp)
  trap 'rm -f "$BODY_FILE"' EXIT
  HTTP_STATUS=$(curl -sS -o "$BODY_FILE" -w '%{http_code}' "$RAW_URL")
  if [[ "$HTTP_STATUS" != 2* ]]; then
    echo "pb: $RAW_URL answered $HTTP_STATUS" >&2
    exit 1
  fi
  cat "$BODY_FILE"
  exit 0
fi

URL="${PB_URL:-http://mudge/api/pastebin}"
TOKEN_PATH="${PB_TOKEN_PATH:-$HOME/Library/Application Support/mudge-report/token}"
TITLE="${1:-}"

if [[ ! -f "$TOKEN_PATH" ]]; then
  echo "pb: no token at $TOKEN_PATH" >&2
  exit 1
fi
TOKEN=$(<"$TOKEN_PATH")

CONTENT=$(cat)
if [[ -z "$CONTENT" ]]; then
  echo "pb: nothing on stdin" >&2
  exit 1
fi

BODY_FILE=$(mktemp)
trap 'rm -f "$BODY_FILE"' EXIT

HTTP_STATUS=$(jq -n --arg title "$TITLE" --arg content "$CONTENT" '{title: $title, content: $content}' |
  curl -sS -o "$BODY_FILE" -w '%{http_code}' -X POST "$URL" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    --data @-)

if [[ "$HTTP_STATUS" != 2* ]]; then
  echo "pb: mudge answered $HTTP_STATUS: $(cat "$BODY_FILE")" >&2
  exit 1
fi

PASTE_URL=$(jq -r '.url // empty' "$BODY_FILE")
if [[ -z "$PASTE_URL" ]]; then
  echo "pb: mudge answered 2xx with no url: $(cat "$BODY_FILE")" >&2
  exit 1
fi

echo "$PASTE_URL"
printf '%s' "$PASTE_URL" | pbcopy
