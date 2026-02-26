---
name: locaweb-cloud-deploy
description: >
  This skill should be used when the user asks to "deploy to Locaweb Cloud", "set up GitHub Actions
  deployment workflows", "create a preview environment", "add a production environment", "tear down
  an environment", "configure a custom domain", "connect to the database", "check deployment logs",
  "scale the VM", or asks about architecture decisions (monolith vs microservices, vertical vs
  horizontal scaling), choosing Postgres-backed alternatives to Redis/Kafka/cron (pgmq, pg_cron,
  LISTEN/NOTIFY, pgroonga, pgvector, pg_jsonschema), managing secrets and environment variables,
  Dockerfile requirements, database migrations, or performing operations and troubleshooting on
  live infrastructure (SSH access, container logs, health checks).
---

# Locaweb Cloud Deploy

**Always respond in the same language the user is using.**

Deploy web applications to Locaweb Cloud by calling reusable workflows from `gmautner/locaweb-cloud-deploy`. The platform provisions CloudStack VMs, networks, disks, and firewall rules, then deploys containers via Kamal 2 with zero-downtime proxy.

## Platform Constraints (Read First)

These constraints apply to **every** application deployed to this platform. Communicate these upfront when starting any deployment work:

- **Single Dockerfile at repo root**, web app **must listen on port 80**
- **Health check at `GET /up`** returning HTTP 200 when healthy
- **Postgres only** (with 60+ bundled extensions via `supabase/postgres`): No Redis, Kafka, or other services. If the app framework expects these features, find or implement a Postgres-backed alternative using the bundled extensions:
  - **Queues**: `pgmq` extension — lightweight message queue with visibility timeout, archive, and batch operations. See [references/pgmq.md](references/pgmq.md)
  - **Pub/sub**: Native `LISTEN`/`NOTIFY` — no extension needed. Producers call `NOTIFY channel, 'payload'` (max 8 KB payload), consumers hold a connection with `LISTEN channel` and receive events asynchronously. Not durable on its own — messages are lost if no listener is connected. Combine with a persistence layer (`pgmq` for job queues, or a regular table for data that's already stored) so consumers can recover missed events via polling. See [references/notify-patterns.md](references/notify-patterns.md)
  - **Scheduling**: `pg_cron` extension — in-database cron using background workers. Combine with `pg_net` to fire HTTP requests to the app on a schedule (e.g., trigger a cleanup endpoint every 5 minutes). **Do not use container-level cron** (`apt-get install cron`, crontab files) — use `pg_cron` + `pg_net` for all scheduled tasks. See [references/pg-cron.md](references/pg-cron.md)
  - **Search**: Native full-text search (`tsvector`/`tsquery`) for well-supported languages, or `pgroonga` extension for multilingual/CJK support. See [references/pgroonga.md](references/pgroonga.md)
  - **Vector database**: `pgvector` extension — embeddings storage and similarity search with HNSW and IVFFlat indexes. See [references/pgvector.md](references/pgvector.md)
  - **JSON validation**: `pg_jsonschema` extension — validate `json`/`jsonb` columns against JSON Schema via CHECK constraints. See [references/pg-jsonschema.md](references/pg-jsonschema.md)
  - **Geospatial**: `postgis` extension — geometry types, spatial indexes, and geographic functions. See <https://postgis.net/>
  - **HTTP from SQL**: `pg_net` extension — asynchronous HTTP/HTTPS requests from SQL. Used with `pg_cron` to call app endpoints on a schedule, or from triggers to fire webhooks. See [references/pg-cron.md](references/pg-cron.md)
  - Other notable extensions: `pgjwt`, `pg_stat_statements`, `pgaudit`, `pg_hashids`
- **Single web VM**: No horizontal web scaling. Scale vertically with larger `web_plan`. Prefer runtimes and frameworks that scale well vertically.
- **No TLS without a domain**: nip.io URLs are HTTP only. Use a custom domain for HTTPS.
- **Single PostgreSQL instance**: No read replicas or multiple databases.
- **Workers use the same Docker image** with a different command (`workers_cmd`).
- **No Docker build in the caller workflow**: The reusable deploy workflow builds, pushes, and deploys the Docker image internally via Kamal. The caller workflow must **not** include any Docker build or push steps (no `docker/build-push-action`, no `docker build`, no `docker push`, no login to ghcr.io). The caller just calls the reusable workflow — Kamal handles the entire build-push-deploy lifecycle using the Dockerfile at the repo root.

If the application's current design conflicts with any of these (e.g., depends on Redis, listens on port 3000, uses multiple Dockerfiles), resolve the conflict **before** proceeding with deployment setup.

## Workflow Overview

```
Caller repo                          gmautner/locaweb-cloud-deploy
+-----------------------+            +-----------------------------+
| .github/workflows/    |  calls     | .github/workflows/          |
|   deploy.yml        -------->      |   deploy.yml (provisions    |
|   teardown.yml      -------->      |     infra + deploys app)    |
+-----------------------+            |   teardown.yml (destroys    |
| Dockerfile (root)     |            |     all resources)          |
| Source code           |            +-----------------------------+
+-----------------------+
```

## Setup Procedure

Follow these steps in order. Each step is idempotent -- safe to re-run across agent sessions. See [references/setup-and-deploy.md](references/setup-and-deploy.md) for detailed commands and procedures for each step.

### Step 1: Prepare the application

- Meet all [Dockerfile Requirements](#dockerfile-requirements) — single Dockerfile at root, port 80, health check at `/up`, env vars for database connection
- If using workers: ensure the same Docker image supports a separate command for the worker process

### Step 2: Ensure a GitHub repository is configured

- Check if a git remote is configured: `git remote -v`
- If `origin` is already set, skip this step
- If no remote is configured, set one up using the **repo-setup** skill before continuing

### Step 3: Generate SSH key

- If `~/.ssh/<repo-name>` already exists, skip generation and reuse the existing key
- Otherwise, generate an Ed25519 SSH key locally at `~/.ssh/<repo-name>` with no passphrase
- Set permissions to 0600
- This key is used for the preview environment

### Step 4: Collect CloudStack credentials

- Check if `CLOUDSTACK_API_KEY` and `CLOUDSTACK_SECRET_KEY` are already set in the repo (`gh secret list`)
- If not set: ask the user to set them via the GitHub UI. **Never** accept secret values through the chat — they would be stored in conversation history
- If the user doesn't have a Locaweb Cloud account yet, recommend they go to https://www.locaweb.com.br/locaweb-cloud/ and look for the "Contratar" button to sign up

Tell the user where to find their API keys:

| Name | Where to find the value |
|------|------------------------|
| `CLOUDSTACK_API_KEY` | [painel-cloud.locaweb.com.br](https://painel-cloud.locaweb.com.br/) → Contas → *(sua conta)* → Visualizar usuários → *(seu usuário)* → Copiar Chave da API |
| `CLOUDSTACK_SECRET_KEY` | Same page → Copiar Chave secreta |

> **Note:** Warn that the keys may take some time to show up after page has loaded. If the user has never generated keys before, they should click the **"Gerar novas chaves"** icon on the top right corner of the user page.

### Step 5: Set up Postgres credentials

- Check if `POSTGRES_PASSWORD` is already set in the repo (`gh secret list`)
- If not set: generate a random password for each environment
- The database user and database name are set by the platform via the env vars above — no manual configuration needed
- The default preview environment uses unsuffixed names: `POSTGRES_PASSWORD`
- Additional environments use suffixed names matching the environment name: e.g., `POSTGRES_PASSWORD_PRODUCTION` for the "production" environment

### Step 6: Create GitHub secrets

- Use `gh secret list` to check which secrets already exist in the repo
- Only create secrets that are missing: `CLOUDSTACK_API_KEY`, `CLOUDSTACK_SECRET_KEY`, `SSH_PRIVATE_KEY` (from the generated key), `POSTGRES_PASSWORD` (if database is enabled)
- Secrets common to all environments (e.g., `CLOUDSTACK_API_KEY`, `CLOUDSTACK_SECRET_KEY`) don't need suffixes — pass them to every caller workflow
- Secrets scoped to additional environments use a suffix matching the environment name (see Step 8)
- If the app has custom env vars or secrets, ask the user to store each secret **individually** via the GitHub UI (see [references/setup-and-deploy.md](references/setup-and-deploy.md#secrets-the-user-must-set-via-github-ui)). Configure clear env vars via `gh variable set ENV_VARS`. **Never** accept secret values through the chat. **Never** store `SECRET_ENV_VARS` as a single GitHub Secret — compose it in the caller workflow from individual secret references (see [references/env-vars.md](references/env-vars.md))

### Step 7: Create caller workflows

- Start with a preview deploy workflow (triggered on push, no domain)
- Create matching teardown workflow
- See [references/workflows.md](references/workflows.md) for templates and input reference

### Step 8: Add additional environments (when ready)

The preview workflow (triggered on push) gives immediate feedback on every change to the main branch, matching a typical developer flow. Other environments can be added depending on the team's processes.

A common choice is a **"production" environment** triggered on version tags (`v*`), where a tag signals that the pointed commit is ready for production. Feel free to create other environments with different triggers and workflow inputs to match your needs.

For each additional environment:

- Generate a separate SSH key: `~/.ssh/<repo-name>-<env_name>` (same procedure as Step 3)
- Store it as a suffixed GitHub secret matching the environment name: e.g., `SSH_PRIVATE_KEY_PRODUCTION`
- If using a database, create a separate Postgres password with the same suffix: e.g., `POSTGRES_PASSWORD_PRODUCTION`
- If the app has custom secrets scoped to the environment, suffix them the same way: e.g., `API_KEY_PRODUCTION`, `SMTP_PASSWORD_PRODUCTION`
- Secrets common to all environments (e.g., `CLOUDSTACK_API_KEY`, `CLOUDSTACK_SECRET_KEY`) don't need to be recreated — just pass them in every caller workflow
- Create a caller deploy workflow for the environment (see [references/workflows.md](references/workflows.md))
- The caller workflow maps the suffixed secrets to the workflow's standard secret names
- For production with a custom domain, see [DNS Configuration](#dns-configuration-for-custom-domains)

## Deployment Feedback Loop

After setup is complete, use this loop to deploy and verify the application. See [references/setup-and-deploy.md](references/setup-and-deploy.md) for detailed commands.

> **Prerequisite:** Before entering this loop, all changes — including the workflow files created during setup and any application code — must be **committed and pushed** to the remote repository. The deploy is triggered by `git push`. If the code has not been committed and pushed yet, do that first:
>
> ```bash
> git add -A && git commit -m "Add deployment workflows" && git push
> ```
>
> The tech-stack skill normally handles this, but if there was a handoff gap, ensure it happens now before proceeding.

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   Push triggers GitHub Actions workflow         │
│        │                                        │
│        ▼                                        │
│   Monitor workflow run (gh run watch)           │
│        │                                        │
│        ▼                                        │
│   Workflow succeeds? ──No──► Read logs, fix,    │
│        │                     commit/push,       │
│       Yes                    repeat             │
│        │                                        │
│        ▼                                        │
│   Health check: curl /up → HTTP 200?            │
│        │                                        │
│       Yes ──► Done (deployment verified)        │
│        │                                        │
│       No                                        │
│        │                                        │
│        ▼                                        │
│   SSH debug (logs, container state)             │
│        │                                        │
│        ▼                                        │
│   Return to tech-stack Local Development        │
│   Feedback Loop to diagnose and fix             │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Workflow monitoring

- After push, **before starting to monitor**, give the user a prominent clickable link to the workflow run so they can follow along in the GitHub UI:

  > **Your deploy is running! Follow it live here:**
  >
  > **\<workflow run URL\>**

  Get the URL with `gh run list --limit=1 --json databaseId,url -q '.[0].url'`
- Then monitor the run with `gh run watch`
- If the workflow fails: read the error from the run logs, fix the issue, commit/push, repeat
- Continue until the workflow succeeds

### Health check verification

- Run `curl -s -o /dev/null -w "%{http_code}" http://<web_ip>.nip.io/up` (get `web_ip` from the workflow run summary)
- If the health check returns HTTP 200, the deployment is verified and complete
- If the health check fails or the app doesn't respond: SSH into the VMs to check logs (use the locally saved SSH key and the public IPs from the workflow output), then return to the **tech-stack** skill's Local Development Feedback Loop to diagnose and fix the issue

## Operations (Post-Deployment)

Quick reference for interacting with deployed infrastructure. See [references/operations.md](references/operations.md) for full details.

| Task | Command pattern |
|---|---|
| Get deployment IPs | `rm -rf /tmp/provision-output && gh run download <run-id> --name provision-output --dir /tmp/provision-output` |
| SSH into a VM | `ssh -i ~/.ssh/<repo-name>[-<env_name>] root@<ip>` |
| Connect to database | SSH into DB VM → `docker exec -it <repo-name>-db psql -U postgres` |
| View app logs | SSH into web VM → `docker logs $(docker ps -q --filter "label=service=<repo-name>") --tail 100` |
| Check app health | `curl -s http://<web_ip>.nip.io/up` |
| Shell into app container | SSH into web VM → `docker exec -it $(docker ps -q --filter "label=service=<repo-name>") sh` |

## Dockerfile Requirements

- Single `Dockerfile` at repository root
- Web app **must listen on port 80** (hardcoded in platform proxy config)
- Default `CMD`/entrypoint serves the web application
- If using workers, the same image must support a separate command passed via `workers_cmd` input
- Health check endpoint at `GET /up` returning HTTP 200 when healthy
- If connecting to a database, read connection from env vars: `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, and/or `DATABASE_URL`. The workflow provides all of these automatically. The app must **fail with a clear error** if it needs the database but these variables are missing -- do not silently skip database functionality.

Example minimal Dockerfile:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 80
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "2", "app:app"]
```

## Database Migrations

The platform runs a single web VM, so running migrations at container startup is the correct approach. This avoids race conditions (no concurrent instances), requires no separate migration container, and keeps migrations synchronized with the deployment lifecycle — a new code push triggers a redeploy, which restarts the container, which runs migrations before serving traffic.

Include migrations in the container entrypoint, before the web server starts:

```dockerfile
CMD ["sh", "-c", "python manage.py migrate && exec gunicorn --bind 0.0.0.0:80 --workers 2 app:app"]
```

Ensure that:

1. **Migration commands run in the entrypoint** — before the web server process starts. The app should not serve requests until migrations complete.
2. **All migration dependencies are bundled in the Docker image** — SQL scripts, migration files, and any libraries used by the migration tool (e.g., `alembic`, `django`, `knex`, `ActiveRecord`) must be installed in the image. Verify that the `COPY` and `RUN pip install` (or equivalent) steps include everything the migration command needs.

## Deployment Outputs and URLs

After a deploy workflow completes, extract information from:

1. **Workflow outputs**: `web_ip`, `worker_ips` (JSON array), `db_ip`, `db_internal_ip`
2. **GitHub Actions step summary**: visible in the workflow run UI, shows IP table and app URL
3. **`provision-output` artifact**: JSON file retained for 90 days

### Determining the app URL

- **No domain (preview)**: `http://<web_ip>.nip.io` -- works immediately, no DNS needed, no HTTPS
- **With domain**: `https://<domain>` -- requires DNS A record pointing to `web_ip`, automatic SSL via Let's Encrypt

### DNS Configuration for Custom Domains

The web VM's public IP is not known until the first deployment completes. To set up a custom domain:

1. **Deploy without a domain first** (leave `domain` empty). The app will be accessible at `http://<web_ip>.nip.io`.
2. **Note the `web_ip`** from the workflow output or step summary.
3. **Create a DNS A record** pointing the domain to that IP:
   ```
   Type: A
   Name: myapp.example.com (or @ for apex)
   Value: <web_ip from step 2>
   TTL: 300
   ```
4. **Re-run the deploy workflow** with the `domain` input set. kamal-proxy will provision a Let's Encrypt certificate automatically.

Let's Encrypt HTTP-01 challenge requires the domain to resolve to the server before the certificate can be issued. The IP is stable across re-deployments to the same environment -- it only changes if the environment is torn down and recreated.

## Scaling

See [references/scaling.md](references/scaling.md) for VM plans, worker scaling, and disk size configuration.

## Teardown

See [references/teardown.md](references/teardown.md) for tearing down environments, inferring zone/env_name from existing workflows, and reading last run outputs.

## Development Without Local Environment

When the developer cannot run the language runtime or database locally, the Deployment Feedback Loop becomes the primary iteration cycle:

1. Commit and push changes
2. Monitor the workflow run until it succeeds
3. Run the health check (`curl /up`) to verify
4. If the health check fails, SSH debug, fix, and repeat from step 1

**Recommendation**: Start with the default `preview` environment triggered on push, without a domain. This gives immediate feedback on every change, with no DNS configuration needed during development. When the app is mature, add additional environments (e.g., `production` with a custom domain, triggered on version tags).

## References

- **[references/operations.md](references/operations.md)** -- Post-deployment operations: finding IPs, SSH access, database access, container debugging
- **[references/setup-and-deploy.md](references/setup-and-deploy.md)** -- Detailed commands for each setup step, development routine, and SSH debugging
- **[references/workflows.md](references/workflows.md)** -- Complete caller workflow examples (deploy + teardown) with all inputs documented
- **[references/env-vars.md](references/env-vars.md)** -- Environment variables and secrets configuration
- **[references/scaling.md](references/scaling.md)** -- VM plans, worker scaling, disk sizes
- **[references/teardown.md](references/teardown.md)** -- Teardown process, inferring parameters, reading outputs
- **[references/notify-patterns.md](references/notify-patterns.md)** -- LISTEN/NOTIFY + persistence: pgmq for job queues, regular tables for data updates, polling fallback
- **[references/pgmq.md](references/pgmq.md)** -- pgmq message queue: SQL examples for send, read, archive, delete
- **[references/pg-cron.md](references/pg-cron.md)** -- pg_cron + pg_net: scheduled jobs, HTTP triggers, common patterns
- **[references/pgroonga.md](references/pgroonga.md)** -- PGroonga full-text search: operators, ranking, highlighting, CJK support
- **[references/pgvector.md](references/pgvector.md)** -- pgvector similarity search: distance operators, HNSW/IVFFlat indexes, tuning
- **[references/pg-jsonschema.md](references/pg-jsonschema.md)** -- pg_jsonschema validation: CHECK constraint pattern, core functions
