#!/usr/bin/env bash
#
# healthcheck.sh — is ShipTrack ready to serve traffic?
#
# Exits 0 if healthy, 1 if not. The EXIT CODE is the interface here:
# it is exactly what a Kubernetes `exec` probe, a systemd Restart=
# policy, or a `&&` in a deploy script all read.
#
# Usage:  ./scripts/healthcheck.sh [url]

set -euo pipefail

URL="${1:-http://127.0.0.1:8000/readyz}"
TIMEOUT=5

# -s   silent
# -o   throw the body away, we only want the status
# -w   print the status code instead
# || echo 000  — curl exits non-zero if it cannot connect at all,
#                and `set -e` would kill us here. 000 means "no answer".
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" "$URL" || echo "000")"

if [[ "$code" == "200" ]]; then
    echo "OK    $URL -> $code"
    exit 0
fi

if [[ "$code" == "000" ]]; then
    echo "FAIL  $URL -> no response (connection refused or timed out)" >&2
else
    echo "FAIL  $URL -> $code" >&2
fi

exit 1
