#!/usr/bin/env bash
#
# run.sh — start the whole local stack.
#
# Starts MySQL if it is not running, waits until it actually answers,
# then starts the app. The wait matters: a container that says "Up"
# is not the same as a database that will accept a connection.
#
# Usage:  ./scripts/run.sh

set -euo pipefail

CONTAINER="shiptrack-mysql"
APP_PORT="${APP_PORT:-8000}"

echo "==> Starting MySQL if it is not already running"
docker start "$CONTAINER"

echo "==> Waiting for MySQL to accept connections"
until docker exec "$CONTAINER" mysqladmin ping -uroot -pdevroot --silent; do
    echo "    not ready yet, waiting..."
    sleep 2
done
echo "    ready"

echo "==> Starting app on port ${APP_PORT}"
echo "    docs: http://127.0.0.1:${APP_PORT}/docs"
echo
uvicorn app.main:app --reload --port "$APP_PORT"
