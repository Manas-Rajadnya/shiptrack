# ShipTrack AWS network

Built by hand in the console on **20 Aug 2026**, region **eu-north-1** (Stockholm).
Codified as Terraform on Day 12 — this document is the design it implements.

---

## The design

```
┌─ VPC  vpc-01f8601ef72b3fe4d   10.0.0.0/16 ─────────────────────────┐
│                                                                    │
│   AZ eu-north-1a                    AZ eu-north-1b                 │
│  ┌──────────────────────┐          ┌──────────────────────┐        │
│  │ PUBLIC               │          │ PUBLIC               │        │
│  │ 10.0.0.0/20          │          │ 10.0.16.0/20         │        │
│  │                      │          │                      │        │
│  │  [ EC2 — Day 11 ]    │          │                      │        │
│  └──────────────────────┘          └──────────────────────┘        │
│              │                                                     │
│         route table: 0.0.0.0/0 → igw                               │
│                                                                    │
│  ┌──────────────────────┐          ┌──────────────────────┐        │
│  │ PRIVATE              │          │ PRIVATE              │        │
│  │ 10.0.128.0/20        │          │ 10.0.144.0/20        │        │
│  │                      │          │                      │        │
│  │  [ RDS — Day 14 ]    │          │                      │        │
│  └──────────────────────┘          └──────────────────────┘        │
│         route table: local only — NO route to the internet         │
│                                                                    │
└──────────────────[ internet gateway  igw-043d54d1... ]─────────────┘
                            │
                        internet
```

## What makes a subnet public

**Its route table sends `0.0.0.0/0` to an internet gateway.** That is the entire definition — there is no "public" flag.

Visible in the console without opening anything:

| Route table | Routes |
|---|---|
| `shiptrack-rtb-public` | **2** — `local` + `0.0.0.0/0 → igw` |
| `shiptrack-rtb-private1` | **1** — `local` only |
| `shiptrack-rtb-private2` | **1** — `local` only |

One extra route is the whole difference.

## Design decisions

| Decision | Why |
|---|---|
| **2 Availability Zones** | RDS requires a DB subnet group spanning 2 AZs, **even for a single-AZ database**. Doing it now avoids rebuilding on Day 14. |
| **Private subnets with no NAT gateway** | A NAT gateway costs **~$32/month**. The database only talks to the app *inside* the VPC and needs no outbound internet, so no route out is correct — and free. See ADR-007. |
| **App in a public subnet** | Needs to be reachable. Protected by a security group rather than by network isolation. |
| **`10.0.0.0/16`** | Private range. 65,536 addresses — far more than needed, but the standard choice and it leaves room. |
| **DNS resolution + hostnames enabled** | Without them the instance can't resolve `github.com`, and RDS endpoints (which are names, not IPs) don't work. |

## Security group — `sg-09b94733fc0e74eeb`

| Direction | Port | Source | Why |
|---|---|---|---|
| Inbound | **22** (SSH) | **`152.58.14.153/32` — my IP only** | SSH open to the world is brute-forced within minutes of an instance existing |
| Inbound | **8000** | `0.0.0.0/0` | The app has to be publicly reachable to be useful |
| Outbound | all | all | Default. The instance needs to pull images and packages. |

**Security groups are stateful** — the reply to an allowed inbound connection is permitted automatically. A NACL is stateless and would need an explicit outbound rule for ephemeral ports (1024-65535).

## Debugging this network

| Symptom | Almost always |
|---|---|
| **Timeout** | **Security group** or a missing `0.0.0.0/0` route. Packets are being dropped silently. |
| **Connection refused** | Network is fine. **The app isn't running** on that port. |
| Can't resolve a hostname on the instance | DNS resolution disabled on the VPC |
| RDS unreachable from the app | The DB's security group doesn't allow the app's security group on 3306 |

**Refused means something said no. Timeout means nobody said anything.**

## What is NOT here, deliberately

| Not built | Cost | Instead |
|---|---|---|
| NAT gateway | ~$32/mo | Private subnets with no egress |
| VPC endpoints | ~$7/mo each | Not needed at this scale |
| Elastic IP | $3.60/mo if unattached | Auto-assigned public IP on the instance |
| Route 53 hosted zone | $0.50/mo | `nip.io` for a hostname |
