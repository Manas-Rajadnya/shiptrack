#!/usr/bin/env bash
#
# run.sh — bring the whole local stack up.
#
# Starts MySQL if it is not running, WAITS until it actually accepts
# connections, then starts the app. The wait matters: a container
# reporting "Up" is not the same as a database that will answer you.
# That gap is why readiness probes exist.
#
# Usage:  ./scripts/run.sh

set -euo pipefail

CONTAINER="shiptrack-mysql"
APP_PORT="${APP_PORT:-8000}"
MAX_WAIT=30

echo "==> Checking MySQL container"
running="$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "missing")"

if [[ "$running" == "missing" ]]; then
    echo "    ERROR: container '$CONTAINER' does not exist." >&2
    echo "    Create it with:" >&2
    echo "      docker run -d --name $CONTAINER -e MYSQL_ROOT_PASSWORD=devroot \\" >&2
    echo "        -e MYSQL_DATABASE=shiptrack -p 3307:3306 mysql:8" >&2
    exit 1
fi

if [[ "$running" != "true" ]]; then
    echo "    starting $CONTAINER"
    docker start "$CONTAINER" >/dev/null
else
    echo "    already running"
fi

echo "==> Waiting for MySQL to accept connections (max ${MAX_WAIT}s)"
for (( i = 1; i <= MAX_WAIT; i++ )); do
    if docker exec "$CONTAINER" mysqladmin ping -uroot -pdevroot --silent >/dev/null 2>&1; then
        echo "    ready after ${i}s"
        break
    fi
    if (( i == MAX_WAIT )); then
        echo "    ERROR: MySQL did not become ready in ${MAX_WAIT}s" >&2
        exit 1
    fi
    sleep 1
done

echo "==> Starting app on port ${APP_PORT}"
echo "    docs:   http://127.0.0.1:${APP_PORT}/docs"
echo "    Ctrl-C to stop"
echo

# exec replaces this shell with uvicorn, so Ctrl-C and SIGTERM reach
# the app directly instead of being swallowed by the wrapper script.
exec uvicorn app.main:app --reload --port "$APP_PORT"
