#!/usr/bin/env bash
#
# seed.sh — put sample orders in the database.
#
# Usage:  ./scripts/seed.sh 25        (default 10)

set -euo pipefail

COUNT="${1:-10}"
CONTAINER="shiptrack-mysql"

echo "==> Adding ${COUNT} orders"

for i in $(seq 1 "$COUNT"); do
    docker exec "$CONTAINER" mysql -uroot -pdevroot shiptrack -e \
        "INSERT IGNORE INTO orders (tracking_id, customer_email, status)
         VALUES ('ST${i}', 'customer${i}@example.com', 'CREATED');"
done

echo "==> Done. Orders in the database:"
docker exec "$CONTAINER" mysql -uroot -pdevroot shiptrack -e \
    "SELECT COUNT(*) AS total FROM orders;"
