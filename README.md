# DevOps Assessment — Terraform + Database Reliability

AWS infrastructure designed with Terraform (module-based, multi-environment) plus
a locally runnable PostgreSQL setup demonstrating migrations, seeding, query
optimization, and backup/restore.

> AWS deployment is **not** required. Terraform is validated with
> `fmt` / `init` / `validate` / `plan`. Database tasks run locally via Docker Compose.

---

## Architecture

```
Internet
   │
   ▼
 ┌──────────────┐   public subnets
 │     ALB      │   (HTTP :80)
 └──────┬───────┘
        │ forward
        ▼
 ┌──────────────┐   private subnets
 │ ECS/Fargate  │   (app container, e.g. nginx)
 └──────┬───────┘
        │ :5432 (allowed by SG)
        ▼
 ┌──────────────┐   private subnets
 │  RDS (Postgres)  private, no public IP
 └──────────────┘
```

Security-group chain (least privilege):

| SG      | Inbound                          |
| ------- | -------------------------------- |
| ALB SG  | `0.0.0.0/0` on :80               |
| ECS SG  | container port **from ALB SG only** |
| RDS SG  | :5432 **from ECS SG only**       |

RDS has `publicly_accessible = false`, lives in private subnets, and only the
ECS security group can reach its port — it is unreachable from the internet.

---

## Repository layout

```
.
├── infra/                         # Part 1 & 2 — Terraform
│   ├── modules/
│   │   ├── network/               # VPC, public/private subnets, IGW, NAT, routes
│   │   ├── ecs/                   # ALB + SGs + ECS cluster/task/service
│   │   └── rds/                   # RDS Postgres + DB subnet group + SG
│   └── envs/
│       ├── dev/                   # small, cheap, deletion protection OFF
│       └── prod/                  # larger, Multi-AZ, deletion protection ON
├── db/                            # Part 4 & 5 — local database
│   ├── docker-compose.yml
│   ├── migrations/
│   │   ├── 001_schema.sql         # hotel_bookings, booking_events
│   │   └── 002_indexes.sql        # optimization index
│   └── seed/
│       └── seed.sql               # 200 bookings + events
├── scripts/                       # Part 6 — backup / restore
│   ├── backup.sh
│   └── restore.sh
├── .github/workflows/terraform.yml  # Part 3 — CI (fmt/init/validate/plan)
└── README.md
```

---

## Part 1 & 2 — Terraform

### Modules

- **network** — VPC, 2 public + 2 private subnets across 2 AZs, Internet Gateway,
  NAT Gateway(s), and route tables. `single_nat_gateway` toggles one shared NAT
  (dev, cheaper) vs. one-per-AZ (prod, highly available).
- **ecs** — ALB (public), ALB/ECS security groups, ECS Fargate cluster, task
  definition, and service. Exposes `ecs_security_group_id` so RDS can allow it in.
- **rds** — Private PostgreSQL instance, DB subnet group, and an RDS security
  group that only permits the ECS security group on :5432.

### Environment differences

| Setting                 | dev            | prod            |
| ----------------------- | -------------- | --------------- |
| VPC CIDR                | `10.10.0.0/16` | `10.20.0.0/16`  |
| NAT Gateway             | single (shared)| one per AZ      |
| ECS task size           | 256 / 512      | 512 / 1024      |
| ECS desired count       | 1              | 3               |
| RDS instance class      | `db.t3.micro`  | `db.t3.medium`  |
| RDS Multi-AZ            | false          | true            |
| Backup retention (days) | 1              | 30              |
| Deletion protection     | false          | true            |
| Final snapshot on destroy | skipped      | taken           |

Each environment has its own `variables.tf`, `terraform.tfvars`, `backend.tf`
(S3 backend, commented for local review), and `providers.tf`.

### Review / run

```bash
cd infra/envs/dev        # or infra/envs/prod

# The DB password is a sensitive var; a placeholder default is set so plan
# works offline, but you can override it:
export TF_VAR_db_password='SomeStrongPassword123!'

terraform fmt -recursive
terraform init -backend=false      # -backend=false: no AWS creds needed for review
terraform validate
terraform plan -refresh=false
```

`-backend=false` and `-refresh=false` keep this a pure plan-only review with no
AWS calls or credentials required. Formatting across the whole tree can be
checked from the repo root with `terraform fmt -recursive -check infra`.

---

## Part 4, 5 & 6 — Local database

### Prerequisites
- Docker + Docker Compose
- A Bash shell for the scripts (Git Bash / WSL on Windows)

### Start the database

```bash
cd db
docker compose up -d
```

On first startup the container automatically runs, in order:
`001_schema.sql` → `002_indexes.sql` → `seed.sql`. Wait for the health check to
report healthy (`docker compose ps`), then verify:

```bash
docker compose exec postgres \
  psql -U appuser -d appdb -c \
  "SELECT 'hotel_bookings', count(*) FROM hotel_bookings
   UNION ALL SELECT 'booking_events', count(*) FROM booking_events;"
```

Expect **200** hotel_bookings and booking_events attached to every 3rd booking.

Connection details: host `localhost`, port `5432`, db `appdb`, user `appuser`,
password `appsecret`.

### Query optimization (Part 5)

Target query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Index added ([`002_indexes.sql`](db/migrations/002_indexes.sql)):

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

**Why this shape:**

1. **`city` first** — the query filters `city = 'delhi'` (equality). Equality
   predicates belong on the leading column so the index can seek straight to the
   matching range.
2. **`created_at` second** — this is a range filter (`>= NOW() - 30 days`). A
   range column must come *after* all equality columns in a B-tree; placed here,
   the index returns the last-30-days rows for `delhi` as one contiguous scan.
3. **`INCLUDE (org_id, status, amount)`** — these are every remaining column the
   query touches (grouped on / summed). Carrying them in the index leaf pages
   lets PostgreSQL answer entirely from the index — an **index-only scan** with
   no heap lookups.

Verify the planner uses it:

```bash
docker compose exec postgres psql -U appuser -d appdb -c \
"EXPLAIN ANALYZE
 SELECT org_id, status, COUNT(*), SUM(amount)
 FROM hotel_bookings
 WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
 GROUP BY org_id, status;"
```

You should see the plan use `idx_hotel_bookings_city_created_at` (a
`Bitmap Index Scan` / `Index Scan`) with the full predicate pushed into the
`Index Cond`, rather than a `Seq Scan`. On only 200 rows the planner may prefer
a seq scan because the table is tiny — force the comparison with
`SET enable_seqscan = off;`. At production scale the `INCLUDE` columns let an
ordered index scan satisfy the whole query from the index without heap fetches
(an index-only scan); that is the payoff the covering index is built for.

### Backup & restore (Part 6)

```bash
# 1. Create a timestamped dump -> backups/appdb_YYYYmmdd_HHMMSS.dump
./scripts/backup.sh

# 2. Restore it into a fresh database (drops + recreates appdb, then restores)
./scripts/restore.sh                 # newest backup
./scripts/restore.sh backups/appdb_20260706_101500.dump   # a specific file
```

**How to verify the restore worked:** `restore.sh` recreates the database from
scratch and, on completion, prints the row counts of both tables. A successful
restore shows the same counts as before the backup (200 hotel_bookings + the
seeded events). To prove it end-to-end:

```bash
./scripts/backup.sh
# delete some data
docker compose -f db/docker-compose.yml exec -T postgres \
  psql -U appuser -d appdb -c "DELETE FROM hotel_bookings WHERE city='delhi';"
# restore and confirm the deleted rows are back
./scripts/restore.sh
```

The scripts use `pg_dump -Fc` (compressed custom format) and `pg_restore`, both
executed *inside* the container, so no local Postgres client is required.

---

## CI (Part 3 — optional, included)

[`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) runs on any
PR touching `infra/`. For both `dev` and `prod` it runs `fmt → init → validate →
plan`, then publishes the plan **both** as a PR comment and as a downloadable
workflow artifact (`tfplan-dev` / `tfplan-prod`). It uses `-backend=false` and
`-refresh=false` with a dummy `TF_VAR_db_password`, so it needs no AWS
credentials.

---

## Notes on secrets

`db_password` is a `sensitive` variable. The env `terraform.tfvars` files carry
a **placeholder** default purely so `plan` renders offline — real deployments
should inject it via `TF_VAR_db_password` or AWS Secrets Manager and never commit
a real value.
