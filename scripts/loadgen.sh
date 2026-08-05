#!/usr/bin/env bash
#
# loadgen.sh — generate traffic against ShipTrack.
#
# Why this exists: on Day 22-23 you build Grafana dashboards and alerts.
# With no traffic they are flat lines and nothing ever fires. Real
# latency and error-rate signal has to be MANUFACTURED on a laptop.
#
# Usage:  ./scripts/loadgen.sh [requests] [concurrency]     default 200 10

set -euo pipefail

REQUESTS="${1:-200}"
CONCURRENCY="${2:-10}"
BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

if ! command -v hey >/dev/null 2>&1; then
    echo "ERROR: 'hey' is not installed. brew install hey" >&2
    exit 1
fi

# Fail fast if the app is not up — otherwise you get 200 confusing
# connection errors instead of one clear message.
if ! ./scripts/healthcheck.sh "${BASE_URL}/readyz" >/dev/null 2>&1; then
    echo "ERROR: app is not ready at ${BASE_URL}. Start it with ./scripts/run.sh" >&2
    exit 1
fi

echo "==> ${REQUESTS} requests, ${CONCURRENCY} concurrent, against ${BASE_URL}"

echo
echo "--- /healthz — liveness, touches nothing ---"
hey -n "$REQUESTS" -c "$CONCURRENCY" "${BASE_URL}/healthz"

echo
echo "--- /readyz — readiness, hits MySQL every request ---"
hey -n "$REQUESTS" -c "$CONCURRENCY" "${BASE_URL}/readyz"

echo
echo "==> Compare the two latency distributions."
echo "    /readyz is slower because every request makes a database round trip."
echo "    That difference is what a p95 latency panel shows you."
