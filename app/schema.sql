-- ShipTrack schema
-- Two tables: orders (current state) + order_events (append-only audit log)

CREATE TABLE IF NOT EXISTS orders (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tracking_id     VARCHAR(20)  NOT NULL UNIQUE,
    customer_email  VARCHAR(255) NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'CREATED',
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- NOTE: `status` is deliberately NOT indexed.
-- GET /api/v1/orders?status=X will do a full table scan.
-- This becomes INC-006 (p99 blowup) on Day 26. See DECISIONS.md ADR-009.

CREATE TABLE IF NOT EXISTS order_events (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id     BIGINT UNSIGNED NOT NULL,
    from_status  VARCHAR(20)     NULL,
    to_status    VARCHAR(20)     NOT NULL,
    actor        VARCHAR(100)    NOT NULL DEFAULT 'system',
    created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_events_order
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,

    INDEX idx_order_events_order_id (order_id)
) ENGINE=InnoDB;
