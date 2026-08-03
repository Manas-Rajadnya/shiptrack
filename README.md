# ShipTrack

An order tracking and delivery status service, built to carry a complete DevOps lifecycle end to end.

The application is deliberately small — roughly 200 lines of Python. The engineering around it is not.

## What it does

| Endpoint | Purpose |
|---|---|
| `GET /api/v1/track/{tracking_id}` | Public tracking lookup. The high-volume read path. |
| `POST /api/v1/orders` | Create an order, returns a tracking ID |
| `PATCH /api/v1/orders/{tracking_id}/status` | Advance an order through its status state machine |
| `GET /api/v1/orders?status=X` | Operations list view |
| `GET /healthz` | Liveness — is the process alive |
| `GET /readyz` | Readiness — can it reach the database |
| `GET /metrics` | Prometheus metrics |

Order status transitions are validated: `CREATED → PACKED → SHIPPED → OUT_FOR_DELIVERY → DELIVERED`, with `CANCELLED` and `RETURNED` as terminal exits. An invalid transition returns `409 Conflict`.

## Stack

Python 3.12 · FastAPI · SQLAlchemy · MySQL 8

## Service level objective

**99.5% of tracking lookups complete in under 300 ms.** This drives the alerting and dashboard work rather than being decoration — the error budget is what makes a latency regression actionable instead of merely visible.

## Where this is going

The deployment path follows how real systems actually evolve, one stage at a time:

```
docker compose on a laptop
  → docker compose on EC2
    → EC2 provisioned by Terraform, configured by Ansible
      → Kubernetes
        → Helm releases across dev / QA / prod
```

CI/CD runs on GitHub Actions with environment promotion and a manual approval gate in front of production. Observability is Prometheus and Grafana for metrics, Loki for logs.

## Repository layout

| Path | Contents |
|---|---|
| `app/` | The FastAPI application |
| `tests/` | Tests |
| `scripts/` | Operational shell scripts — seed, healthcheck, load generation |
| `infra/terraform/` | AWS infrastructure as code |
| `ansible/` | Host configuration |
| `k8s/` | Raw Kubernetes manifests |
| `helm/` | Helm chart with per-environment values |
| `monitoring/` | Prometheus rules, Grafana dashboards |
| `docs/` | Architecture notes and the operational runbook |
