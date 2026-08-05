#!/usr/bin/env bash
#
# seed.sh — put sample orders in the database.
#
# Inserts directly via SQL for now. Once POST /api/v1/orders exists
# (Day 4) this switches to driving the real API, which is better —
# seeding through the app exercises validation and the state machine.
#
# Usage:  ./scripts/seed.sh [count]        default 10

set -euo pipefail

COUNT="${1:-10}"
CONTAINER="shiptrack-mysql"

# ${1:-10} is "use $1, or 10 if it is unset". Without a default,
# `set -u` would abort the script when called with no arguments.

if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    echo "ERROR: count must be a number, got '$COUNT'" >&2
    exit 1
fi

echo "==> Seeding ${COUNT} orders into shiptrack"

statuses=(CREATED PACKED SHIPPED OUT_FOR_DELIVERY DELIVERED)

for (( i = 1; i <= COUNT; i++ )); do
    tracking_id="ST$(printf '%08d' "$i")"
    status="${statuses[$(( RANDOM % ${#statuses[@]} ))]}"

    docker exec "$CONTAINER" mysql -uroot -pdevroot shiptrack -e \
        "INSERT IGNORE INTO orders (tracking_id, customer_email, status)
         VALUES ('${tracking_id}', 'customer${i}@example.com', '${status}');" 2>/dev/null
done

echo "==> Done. Current contents:"
docker exec "$CONTAINER" mysql -uroot -pdevroot shiptrack -e \
    "SELECT status, COUNT(*) AS orders FROM orders GROUP BY status;" 2>/dev/null
