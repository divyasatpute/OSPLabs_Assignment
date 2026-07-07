# DevOps Assessment: Terraform + Database Reliability

AWS infrastructure design in Terraform, plus a locally-runnable PostgreSQL
setup demonstrating backup, restore, and query optimization.

> Actual AWS deployment is **not** required or performed. Terraform is
> validated locally via `fmt`, `init`, `validate`, and `plan -refresh=false`.
> The database part (Part 4–6) is fully runnable locally with Docker Compose.

---

## Stack

Terraform, AWS (design only), Docker Compose, PostgreSQL, GitHub Actions, Shell scripting.

---

## Repository Structure

```text
devops-assessment/
├── infra/
│   ├── modules/
│   │   ├── network/     # VPC, public/private subnets, IGW, NAT, route tables
│   │   ├── security/    # ALB / ECS / RDS security groups
│   │   ├── iam/         # ECS task execution role
│   │   ├── logs/        # CloudWatch log group
│   │   ├── alb/         # Application Load Balancer, target group, listener
│   │   ├── ecs/         # ECS cluster, task definition, service (Fargate)
│   │   └── rds/         # RDS PostgreSQL instance, subnet group
│   └── envs/
│       ├── dev/          # smaller instance, 1-day backup retention, deletion_protection = false, outputs.tf
│       └── prod/         # larger instance, 7-day backup retention, deletion_protection = true, outputs.tf
│
├── database/
│   ├── docker-compose.yml     # Local PostgreSQL 16 container
│   ├── init/
│   │   ├── 01-schema.sql       # hotel_bookings, booking_events, indexes
│   │   └── 02-seed.sql         # 175 bookings across 8 cities / 6 orgs / 4 statuses + events
│   └── backups/                # Timestamped dumps land here (gitignored)
│
├── queries/
│   └── optimized_query.sql    # The reporting query + index rationale + EXPLAIN steps
│
├── scripts/
│   ├── backup.sh               # Timestamped pg_dump
│   └── restore.sh              # Restores into a FRESH database for verification
│
├── .github/workflows/terraform.yml   # fmt / init / validate / plan on PRs, plan posted as PR comment + artifact
└── README.md
```

---

## Part 1–3: Terraform Infrastructure

### Architecture

```text
Internet → ALB (public subnets) → ECS/Fargate (private app subnets) → RDS PostgreSQL (private db subnets)
```

- **VPC** with public subnets (ALB) and private subnets split into app and db tiers.
- **ALB security group**: allows inbound HTTP from the internet, forwards to ECS.
- **ECS security group**: only accepts traffic from the ALB security group.
- **RDS security group**: only accepts traffic from the ECS security group —
  RDS has `publicly_accessible = false` and lives only in private db subnets,
  so it is unreachable from anywhere except the ECS tasks.
- **ECS Fargate** cluster/task/service run a placeholder `nginx:latest`
  container (as explicitly permitted by the assessment) behind the ALB.
- **RDS PostgreSQL 16**, Multi-AZ, in the private db subnets.

### Environments

| Setting                  | dev                  | prod                 |
|---------------------------|----------------------|-----------------------|
| `instance_class`           | `db.t3.micro`         | `db.t3.small`          |
| `allocated_storage`        | 20 GB                 | 50 GB                  |
| `backup_retention_period`  | 1 day                 | 7 days                 |
| `deletion_protection`      | `false`                | `true`                  |
| Backend state              | local, `infra/envs/dev/terraform.tfstate`  | local, `infra/envs/prod/terraform.tfstate` |

Each environment has its own `variables.tf`, `terraform.tfvars`, `provider.tf`
and `backend.tf`, so they can be planned/applied independently.

### Validate Locally

```bash
cd infra/envs/dev      # or infra/envs/prod
terraform init -backend=false
terraform fmt -recursive -check
terraform validate
terraform plan -refresh=false
```

No AWS credentials or account are required to run `validate`; `plan` will
need valid (even dummy/test) AWS credentials configured, since Terraform's
AWS provider needs to authenticate to build the plan, but no resources are
ever applied.

### GitHub Actions (Part 3)

`.github/workflows/terraform.yml` runs on every pull request against `main`
and, for both `infra/envs/dev` and `infra/envs/prod`:

1. `terraform fmt -recursive -check`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan -refresh=false -out=tfplan`
5. Uploads the plan as a workflow artifact (`terraform-plan-dev` / `terraform-plan-prod`)
6. Posts the plan output as a comment on the pull request

---

## Deploying to Real AWS

The assessment doesn't require this, but if you want to actually stand the
infrastructure up in your own AWS account, here's the full path.

### 1. Prerequisites

- An AWS account, and an IAM user or role with programmatic access
  (Access Key ID + Secret Access Key) with permissions for VPC, EC2
  (subnets/NAT/IGW), ECS, RDS, IAM, ELB, and CloudWatch Logs. For a
  personal/test account, attaching `AdministratorAccess` is the simplest
  option; for anything shared, scope it down.
- AWS CLI installed and configured:
  ```bash
  aws configure
  # AWS Access Key ID, Secret Access Key, region (ap-south-1), output format
  ```
- Terraform >= 1.5 installed locally.

### 2. Cost warning

This creates **billable** resources the moment you `apply` — a NAT Gateway,
an Application Load Balancer, an RDS instance (Multi-AZ, so effectively two
instances), and ECS Fargate tasks. None of these are in the AWS Free Tier
except (partially) the smallest RDS tier, and Multi-AZ specifically is not
free. Expect a few dollars a day if left running. **Destroy it when you're
done** (step 6).

### 3. Review the tfvars before applying

`infra/envs/dev/terraform.tfvars` currently has a hardcoded demo password
(`Password@123`). For a real deployment, change it to something private,
and avoid committing real secrets to Git — either edit the `.tfvars` file
locally and keep it out of version control, or pass it at plan/apply time
instead:

```bash
terraform apply -var="db_password=<your-own-password>"
```

### 4. Initialize and apply

```bash
cd infra/envs/dev

terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. This takes roughly 10–15 minutes — RDS Multi-AZ
provisioning is the slowest part.

### 5. Verify it's running

```bash
terraform output alb_dns_name
```

Open that DNS name in a browser (`http://<alb_dns_name>`) — you should see
the default `nginx` welcome page, since `container_image = "nginx:latest"`
is the placeholder app. To run something real instead:

1. Build and push your own image to an ECR repository in the same region.
2. Update `container_image` in `infra/envs/dev/main.tf` to that ECR image URI.
3. `terraform apply` again — ECS will roll out the new task definition.

To check RDS came up (the endpoint is only reachable from inside the VPC,
i.e. from ECS tasks — not from your laptop, by design):

```bash
terraform output rds_endpoint
```

### 6. Deploy prod the same way (optional)

```bash
cd ../prod
terraform init
terraform plan
terraform apply
```

### 7. Tear it down when you're finished

```bash
cd infra/envs/dev
terraform destroy

cd ../prod
terraform destroy
```

`prod` has `deletion_protection = true` on RDS, so `destroy` will fail on
the database until you either set `deletion_protection = false` and
`apply` that change first, or delete the RDS instance manually in the
console, then re-run `destroy`.

---

## Part 4: Local Database

```bash
cd database
docker compose up -d
docker ps                                          # confirm bookingapp-postgres is healthy
docker exec -it bookingapp-postgres psql -U postgres -d bookingdb
```

`hotel_bookings` and `booking_events` are created automatically from
`database/init/01-schema.sql`, and `database/init/02-seed.sql` seeds data,
the first time the container starts (via Postgres's
`docker-entrypoint-initdb.d` mechanism).

### Schema

```sql
CREATE TABLE hotel_bookings (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID NOT NULL,
    hotel_id       VARCHAR(100) NOT NULL,
    city           VARCHAR(100) NOT NULL,
    checkin_date   DATE NOT NULL,
    checkout_date  DATE NOT NULL,
    amount         NUMERIC(12,2) NOT NULL,
    status         VARCHAR(50) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE booking_events (
    id          BIGSERIAL PRIMARY KEY,
    booking_id  UUID NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
    event_type  VARCHAR(100) NOT NULL,
    payload     JSONB,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## Part 5: Seed Data & Query Optimization

`database/init/02-seed.sql` inserts:

- **175 `hotel_bookings` rows** total (150 randomized + 25 guaranteed recent
  Delhi rows so the optimized query always has data to demonstrate against)
- **8 cities**: delhi, mumbai, bengaluru, pune, goa, jaipur, hyderabad, chennai
- **6 organizations** (fixed `org_id` UUIDs, so results are stable across runs)
- **4 statuses**: CONFIRMED, CANCELLED, COMPLETED, PENDING
- **`booking_events`** for the majority of bookings (`BOOKING_CREATED`,
  `PAYMENT_PROCESSED`, and `BOOKING_CANCELLED` where applicable)

### The query to optimize

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

### Index added

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

**Why this index:**

1. `city` is filtered by equality and `created_at` by a range. Standard
   B-tree composite index design puts equality columns before range
   columns, so `(city, created_at)` lets PostgreSQL seek directly to the
   `'delhi'` rows and then scan only the last-30-days slice of that range,
   instead of a sequential scan over the whole table.
2. `org_id`, `status`, and `amount` are attached with `INCLUDE` rather than
   as extra key columns, because the query only ever *reads* them — it
   doesn't filter or sort by them. `INCLUDE` keeps the index's key portion
   narrow (cheaper to maintain on every write) while still letting
   PostgreSQL answer the entire query from the index alone (an
   index-only scan), avoiding a heap fetch for every matching row.

**To verify the plan yourself:**

```bash
docker exec -it bookingapp-postgres psql -U postgres -d bookingdb -c \
  "EXPLAIN ANALYZE
   SELECT org_id, status, COUNT(*), SUM(amount)
   FROM hotel_bookings
   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
   GROUP BY org_id, status;"
```

Before the index (or with it dropped via `DROP INDEX idx_hotel_bookings_city_created_at;`),
this plans as a `Seq Scan` over `hotel_bookings` with a `Filter` on both
conditions, scanning every row. With the index in place, the plan switches
to an `Index Only Scan using idx_hotel_bookings_city_created_at`, with an
`Index Cond` of `(city = 'delhi'::text) AND (created_at >= ...)`, touching
only the matching subset of the index.

See `queries/optimized_query.sql` for the same query and explanation inline.

---

## Part 6: Backup & Restore

### Backup

```bash
./scripts/backup.sh
```

Creates `database/backups/bookingdb_<timestamp>.sql` using `pg_dump --clean --if-exists`.

### Restore (into a fresh database, for verification)

```bash
./scripts/restore.sh database/backups/bookingdb_20260707_101500.sql
```

This does **not** touch the live `bookingdb`. Instead it:

1. Drops (if present) and recreates a separate database called
   `bookingdb_restore_verify` inside the same running container.
2. Restores the dump into that fresh database.
3. Runs a row-count check against `hotel_bookings` and `booking_events` in
   the restored database and prints the results.

You can also restore into a custom-named database:

```bash
./scripts/restore.sh database/backups/bookingdb_20260707_101500.sql my_test_db
```

### How to verify the restore worked

1. Run `./scripts/backup.sh`, then note the row counts in the source DB:
   ```bash
   docker exec -it bookingapp-postgres psql -U postgres -d bookingdb -c \
     "SELECT (SELECT COUNT(*) FROM hotel_bookings) AS bookings, (SELECT COUNT(*) FROM booking_events) AS events;"
   ```
2. Run `./scripts/restore.sh <backup-file>` — it automatically prints the
   row counts from the restored `bookingdb_restore_verify` database at the
   end.
3. Compare the two counts: matching numbers confirm the dump captured all
   data and the restore reproduced it correctly.
4. Optionally connect directly and spot-check a row:
   ```bash
   docker exec -it bookingapp-postgres psql -U postgres -d bookingdb_restore_verify -c \
     "SELECT * FROM hotel_bookings LIMIT 5;"
   ```

---

## Full Local Walkthrough

```bash
# Database
cd database
docker compose up -d
cd ..

# Backup
./scripts/backup.sh

# Restore into a fresh DB and verify
./scripts/restore.sh database/backups/bookingdb_<timestamp>.sql

# Terraform (per environment)
cd infra/envs/dev
terraform init -backend=false
terraform fmt -recursive -check
terraform validate
terraform plan -refresh=false
```

---

## Submission Checklist

- [x] Terraform infrastructure code (`infra/modules`)
- [x] `dev` and `prod` Terraform environments (`infra/envs`)
- [x] Docker Compose database setup (`database/docker-compose.yml`)
- [x] SQL migration files (`database/init/01-schema.sql`)
- [x] Seed data script (`database/init/02-seed.sql`)
- [x] Database backup script (`scripts/backup.sh`)
- [x] Database restore script (`scripts/restore.sh`)
- [x] README.md with setup and verification steps (this file)
- [x] GitHub Actions Terraform plan workflow (`.github/workflows/terraform.yml`)
