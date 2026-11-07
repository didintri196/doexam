#!/usr/bin/env bash
# Smoke test of a running DoExam (binary, Docker image or Helm release):
#   scripts/smoke.sh http://localhost:8080 [aio|api]
# aio (default): API and the embedded frontend; api: API only (distributed server image).
set -euo pipefail

BASE=${1:?usage: scripts/smoke.sh BASE_URL [aio|api]}
MODE=${2:-aio}
fail=0

# check NAME URL WANT_STATUS [GREP_IN_BODY] [HEADER_REGEX] [ACCEPT_ENCODING]
# The body is fetched uncompressed (no decoding needed); pass ACCEPT_ENCODING to check
# that a precompressed copy is offered (headers only).
check() {
  local name=$1 url=$2 want=$3 body_re=${4:-} header_re=${5:-} enc=${6:-identity}
  local hdr body status
  hdr=$(mktemp) body=$(mktemp)
  status=$(curl -s -o "$body" -D "$hdr" -w '%{http_code}' -H "Accept-Encoding: $enc" "$BASE$url") || status=000
  local ok=1
  [[ "$status" =~ ^($want)$ ]] || ok=0
  if [[ -n "$body_re" ]] && ! grep -qiE "$body_re" "$body"; then ok=0; fi
  if [[ -n "$header_re" ]] && ! grep -qiE "$header_re" "$hdr"; then ok=0; fi
  if [[ $ok == 1 ]]; then
    printf '  ok    %-34s %s\n' "$name" "$status"
  else
    printf '  FAIL  %-34s got %s (want %s %s %s)\n' "$name" "$status" "$want" "$body_re" "$header_re"
    fail=1
  fi
  rm -f "$hdr" "$body"
}

echo "smoke test $BASE ($MODE)"
for i in $(seq 1 60); do
  curl -sf "$BASE/healthz" >/dev/null && break
  [[ $i == 60 ]] && { echo "  FAIL  server did not become healthy"; exit 1; }
  sleep 1
done

check "healthz"                 /healthz 200
check "readyz (database)"       /readyz 200
check "public tenant (API)"     /api/v1/public/tenant '(200|404)' '"success"'
check "unknown API route"       /api/v1/does-not-exist 404

if [[ "$MODE" == "aio" ]]; then
  check "/ redirects to /exam/"   / 302 '' '^location: */exam/'
  check "/exam redirects"         /exam 302 '' '^location: */exam/'
  check "exam client"             /exam/ 200 '<html' 'content-security-policy:.*worker-src'
  check "exam deep link"          /exam/attempt/00000000-0000-0000-0000-000000000000 200 '<html'
  check "staff panel"             /app/ 200 '<html' '^cache-control: *no-cache'
  check "panel deep link"         /app/sessions/x/monitor 200 '<html'
  check "service worker"          /exam/sw.js 200 '' '^service-worker-allowed: */exam/'
  asset=$(curl -s "$BASE/exam/" | grep -oE '/assets/[^"]+\.js' | head -1 || true)
  if [[ -n "$asset" ]]; then
    check "hashed asset (immutable)" "$asset" 200 '' 'immutable'
    check "asset precompressed (br)" "$asset" 200 '' '^content-encoding: *br' 'br, gzip'
  else
    echo "  FAIL  no /assets/*.js referenced by /exam/"; fail=1
  fi
  check "missing asset is 404"    /assets/missing-000.js 404
else
  check "no frontend (API only)"  /exam/ 404
fi

if [[ $fail == 0 ]]; then echo "smoke test passed"; else echo "smoke test FAILED"; fi
exit $fail
