#!/usr/bin/env bash
#
# seed.sh — put sample orders in the database.
#
# Connects over the network rather than with `docker exec`, so it works
# whether the database was started by hand or by docker compose. Container
# names change; the published port does not.
#
# Usage:  ./scripts/seed.sh 25        (default 10)

set -euo pipefail

COUNT="${1:-10}"
DB_HOST="127.0.0.1"
DB_PORT="3307"

echo "==> Adding ${COUNT} orders"

for i in $(seq 1 "$COUNT"); do
    mysql -h "$DB_HOST" -P "$DB_PORT" -uroot -pdevroot shiptrack -e \
        "INSERT IGNORE INTO orders (tracking_id, customer_email, status)
         VALUES ('ST${i}', 'customer${i}@example.com', 'CREATED');" 2>/dev/null
done

echo "==> Done. Orders in the database:"
mysql -h "$DB_HOST" -P "$DB_PORT" -uroot -pdevroot shiptrack -e \
    "SELECT COUNT(*) AS total FROM orders;" 2>/dev/null
