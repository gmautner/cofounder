---
name: tech-stack
description: Go + React full-stack architecture with iterative local development. Use this skill when scaffolding a new app, adding features, fixing bugs, or running the local dev loop. Covers project layout, database migrations, sqlc code generation, local Supabase/Postgres via Podman, and the write-test-repeat feedback cycle.
---

# Tech Stack

Go JSON API + React SPA served from a single binary and deployed as one container.

## Architecture

**Backend:** Go stdlib `net/http` router, `pgx/v5` for Postgres, `sqlc` for query generation, `slog` for logging, embedded SQL migrations via `go:embed`.

**Frontend:** Vite + React + TypeScript, shadcn/ui components, Tailwind CSS, React Router. When making frontend design decisions (layouts, styling, component aesthetics, UI polish), use the **frontend-design** skill for guidance on creating distinctive, production-grade interfaces.

## Project Layout

```
.
├── backend/
│   ├── cmd/server/main.go       # Entrypoint
│   ├── internal/
│   │   ├── config/              # Env var parsing
│   │   ├── database/
│   │   │   ├── migrations/*.sql # Embedded, forward-only
│   │   │   ├── queries/*.sql    # sqlc source
│   │   │   └── sqlc/            # Generated — do not edit
│   │   └── handler/             # HTTP handlers (JSON API)
│   ├── go.mod
│   ├── go.sum
│   └── sqlc.yaml
├── frontend/                    # Vite + React SPA
│   ├── src/
│   │   ├── components/ui/       # shadcn/ui (generated, editable)
│   │   └── pages/               # Route-level components
│   └── dist/                    # Build output (gitignored)
└── Dockerfile
```

## Key Decisions

### Single-binary serving

The Go server handles everything: API routes under `/api/`, static assets under `/assets/`, and a catch-all that returns `index.html` for SPA routing. In development, Vite's dev server proxies API calls to the Go backend.

### Database only — no Redis, no external caches, no message queues

PostgreSQL is the only external service. Use Postgres-backed alternatives for everything:
- **Queues:** `pgmq` extension or `SELECT ... FOR UPDATE SKIP LOCKED`
- **Pub/Sub:** `LISTEN`/`NOTIFY`
- **Caching:** unlogged tables
- **Scheduling:** `pg_cron` + `pg_net`
- **Search:** `pgroonga`
- **Vectors:** `pgvector`

All 60+ bundled extensions from `supabase/postgres` are available. See the **locaweb-cloud-deploy** skill references for extension-specific guides.

### sqlc for all queries

All SQL lives in `backend/internal/database/queries/*.sql`. Run `cd backend && sqlc generate` after changes. **Never write raw SQL strings in Go handler code.**

### Migrations at startup

Embedded SQL files applied in order before the server accepts traffic. Forward-only, numbered sequentially (`001_create_users.sql`, `002_add_tasks.sql`, …). Each migration should be idempotent where possible (`CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`).

### Real-time updates via SSE

The Go backend listens for Postgres `NOTIFY` events and holds open a standard HTTP response with `Content-Type: text/event-stream` for each connected client. The React frontend uses the browser's built-in `EventSource` API. SSE is preferred over WebSockets to avoid adverse proxy configurations.

## Deployment Constraints

These match the **locaweb-cloud-deploy** skill requirements:

- Single container on **port 80** (controlled by `PORT` env var, defaulting to `8080` for local dev)
- Health check: **`GET /up` → HTTP 200**
- Database via `DATABASE_URL` (preferred) or individual `POSTGRES_*` env vars — **fail hard if missing**
- File storage at `BLOB_STORAGE_PATH` (default `/data/blobs`)
- No Redis, no external caches, no message queues — use PostgreSQL for everything
- No ORMs, no JavaScript frameworks beyond React, no CSS preprocessors

## Dockerfile

Multi-stage: (1) build frontend with Node, (2) build Go binary, (3) minimal Alpine runtime with binary + `frontend/dist/` + CA certs. The Go binary embeds migrations; frontend assets are served from `/frontend/dist` on disk. The Node and Go versions in the Dockerfile must match the versions installed locally by the **devbox-setup** skill — check `devbox.json` for the current versions before writing or updating the Dockerfile.

## Local Development

All commands run through **devbox** as established by the **devbox-setup** skill. The database runs as a `supabase/postgres` container via **podman** (set up by the **podman-setup** skill), matching the production image.

### 1. Start the database

```bash
# Start supabase/postgres container (matching production image)
devbox run -- podman run -d \
  --name supabase-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=postgres \
  -p 5432:5432 \
  supabase/postgres:17.6.1.084

# Verify it's ready
devbox run -- pg_isready -h localhost -p 5432 -U postgres
```

### 2. Start the Go API (terminal 1)

```bash
devbox run -- bash -c 'cd backend && DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable" go run ./cmd/server'
```

### 3. Start the Vite dev server (terminal 2)

```bash
devbox run -- bash -c 'cd frontend && npm install && npm run dev'
```

Access the app at `http://localhost:5173` during development. Vite proxies `/api/*` and `/auth/*` to the Go backend.

### Stopping the database

```bash
devbox run -- podman stop supabase-postgres && devbox run -- podman rm supabase-postgres
```

## Local Development Feedback Loop

The core workflow is: **write code → spin up local instance → run tests → repeat until the feature works → commit & push.**

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   Write / Edit Code                             │
│        │                                        │
│        ▼                                        │
│   Start Local Services                          │
│   (podman supabase, go run, npm dev)            │
│        │                                        │
│        ▼                                        │
│   Run Backend Tests (Go)                        │
│        │                                        │
│        ▼                                        │
│   Run Frontend Tests (Playwright)               │
│        │                                        │
│        ▼                                        │
│   Tests pass? ──No──► Fix & repeat from top     │
│        │                                        │
│       Yes                                       │
│        │                                        │
│        ▼                                        │
│   Commit & push ──► Done                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

After committing and pushing, ask the user if they want to deploy to the cloud. If yes, use the **locaweb-cloud-deploy** skill to run the **Deployment Feedback Loop**, which monitors the GitHub Actions workflow, verifies the health check, and handles deployment-specific failures.

### Backend testing (Go)

Run unit tests against the local database:

```bash
devbox run -- bash -c 'cd backend && DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable" go test ./...'
```

- Test files live next to the code they test (`handler/todo_test.go` tests `handler/todo.go`).
- Use table-driven tests. Each test case gets a descriptive name.
- For database tests, use a test helper that runs migrations and wraps each test in a transaction that rolls back.
- Test the HTTP handlers via `httptest.NewServer` — send real HTTP requests, assert on status codes and JSON bodies.

### Frontend testing (Playwright)

Use the **webapp-testing** skill for Playwright-based end-to-end testing. The `with_server.py` helper manages the full stack:

```bash
devbox run -- python skills/webapp-testing/scripts/with_server.py \
  --server "devbox run -- podman start supabase-postgres || true" --port 5432 \
  --server "cd backend && DATABASE_URL='postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable' devbox run -- go run ./cmd/server" --port 8080 \
  --server "cd frontend && devbox run -- npm run dev" --port 5173 \
  -- devbox run -- python test_script.py
```

Or, if services are already running, write a standalone Playwright script:

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')
    # ... test interactions
    browser.close()
```

Follow the reconnaissance-then-action pattern: screenshot → identify selectors → execute actions → assert results.

### sqlc workflow

Whenever SQL queries change:

```bash
devbox run -- bash -c 'cd backend && sqlc generate'
```

Then update the Go code that calls the generated functions. Never hand-write SQL in Go files.

## Conventions

- **Thin handlers:** parse request → call database → return JSON. No business logic in handlers.
- **Logging:** `slog` exclusively. Never `fmt.Println` or `log.Println`.
- **Validation:** Server-side validation for all inputs. Never trust client-side validation alone.
- **Authorization:** Checks in every handler, not just middleware.
- **Frontend components:** `cd frontend && devbox run -- pnpm dlx shadcn@latest add <component>`
- **No ORMs.** SQL through sqlc only.
- **No CSS preprocessors.** Tailwind CSS only.
- **No additional JavaScript frameworks.** React + React Router only.
