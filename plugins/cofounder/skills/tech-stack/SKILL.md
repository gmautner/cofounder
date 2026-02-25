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

Ensure the project `.gitignore` includes at least:

```
frontend/dist/
frontend/node_modules/
.venv/
.claude/launch.json
```

`.claude/launch.json` is generated locally by Claude Code Desktop's Preview feature and contains platform-specific commands — it must not be committed.

`mise.toml` should **not** be gitignored — it is committed to the repo so all developers use the same tool versions.

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

Always include `emit_json_tags: true` in `sqlc.yaml` so that generated Go structs include lowercase JSON tags (e.g., `json:"id"` instead of exporting `ID` as-is). Without this, the API returns PascalCase field names that don't match frontend expectations.

### Migrations at startup

Embedded SQL files applied in order before the server accepts traffic. Forward-only, numbered sequentially (`001_create_users.sql`, `002_add_tasks.sql`, …). Each migration should be idempotent where possible (`CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`).

The `go:embed` directive only accepts files in the same directory or subdirectories of the file that declares it — paths with `..` are rejected by the compiler. Place the embed directive in a Go file next to the `migrations/` directory (e.g., `backend/internal/database/migrate.go`), not in `cmd/server/main.go`.

### Database connection retry

The Go backend should retry the database connection at startup (up to 10 attempts, 1-second delay between each). This handles parallel startup — Preview starts all servers simultaneously, so the backend may come up before the database is ready — and is also good practice for production deployments.

```go
var pool *pgxpool.Pool
for i := range 10 {
    pool, err = pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
    if err == nil {
        if err = pool.Ping(ctx); err == nil {
            break
        }
        pool.Close()
    }
    slog.Warn("database not ready, retrying", "attempt", i+1, "err", err)
    time.Sleep(time.Second)
}
if err != nil {
    slog.Error("failed to connect to database", "err", err)
    os.Exit(1)
}
```

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

Multi-stage: (1) build frontend with Node, (2) build Go binary, (3) minimal Alpine runtime with binary + `frontend/dist/` + CA certs. The Go binary embeds migrations; frontend assets are served from `/frontend/dist` on disk. The Node and Go versions in the Dockerfile must match the versions installed locally — run `go version` and `node --version` to check current versions before writing or updating the Dockerfile.

## Local Development

All tools are on PATH via **mise** (set up by **computer-setup**). The database runs as a `supabase/postgres` container via **podman** (also set up by **computer-setup**), matching the production image.

> **Container naming convention:** Each project's database container is named `<repo_name>-db` (e.g., `myapp-db`), where `<repo_name>` is the basename of the project's root directory. This prevents collisions when multiple cofounder projects coexist on the same machine. Derive the name once at the start of the session and use it consistently for all `podman` commands.

> **Critical: `go.mod` lives in `backend/`, not in the project root.** All Go and sqlc commands (`go run`, `go build`, `go test`, `go mod tidy`, `sqlc generate`) **must** execute from the `backend/` directory. Always include `cd backend &&` inside the `bash -c` string. When a command chain involves multiple layers of shell invocation (bash → go), prefer writing a small helper script instead of nesting everything in a single `bash -c` string — this avoids the most common source of repeated build failures.

### Project tool versions

On first setup (when `mise.toml` does not yet exist in the project root), lock the tool versions:

```bash
mise use go@1 sqlc@1 python@3.14 node@24 jq@1
```

This creates a `mise.toml` that is committed to the repo, ensuring all developers use the same versions. If a version upgrade is needed later, re-run `mise use` with the new version.

### 1. Start the database

Before starting the container, check if any podman container is already using
port 5432. If a container from **another project** is occupying the port, do
**not** force-stop it. Instead, inform the user:

> "The container `<other_name>` from another project is currently using port 5432. Could you please stop it with `podman stop <other_name>` so we can start this project's database?"

Wait for the user to confirm before proceeding.

```bash
# Derive the container name from the repo directory
CONTAINER_NAME="$(basename "$(pwd)")-db"

# Start supabase/postgres container (matching production image)
# Important: provide only the POSTGRES_PASSWORD environment variable. The database is started with both user and database name preset to `postgres`.
podman run -d \
  --name "$CONTAINER_NAME" \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  supabase/postgres:17.6.1.084

# Verify it's ready (uses container exec instead of pg_isready)
podman exec "$CONTAINER_NAME" pg_isready -U postgres
```

### 2. Start the Go API (terminal 1)

```bash
bash -c 'cd backend && DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable" go run ./cmd/server'
```

### 3. Start the Vite dev server (terminal 2)

```bash
bash -c 'cd frontend && npm install && npm run dev'
```

Access the app at `http://localhost:5173` during development. Vite proxies `/api/*` and `/auth/*` to the Go backend.

### Stopping the database

```bash
CONTAINER_NAME="$(basename "$(pwd)")-db"
podman stop "$CONTAINER_NAME" && podman rm "$CONTAINER_NAME"
```

## Preview (Claude Code Desktop)

When `preview_*` tools are available (Claude Code Desktop), Preview manages the dev servers automatically — you do not need to start or stop them manually. Use `preview_screenshot`, `preview_click`, and `preview_snapshot` for quick visual checks during development. Reserve Playwright (via the **webapp-testing** skill) for comprehensive E2E test suites.

### Windows: do NOT use Preview

**Preview is not supported on Windows.** Do not generate `.claude/launch.json` or attempt to use `preview_*` tools on Windows. Instead, start the servers manually in the session chat (podman, `go run`, `npm run dev`) and give the user the `http://localhost:5173` link. This works perfectly and is also compatible with Playwright-based testing via the **webapp-testing** skill.

## Local Development Feedback Loop

> **Preview mode:** If you have access to `preview_*` tools (Claude Code Desktop), Preview manages the dev servers — **do not start them manually**. Use `preview_screenshot`, `preview_snapshot`, and `preview_click` for visual verification instead of Playwright for quick checks. Use Playwright (via the **webapp-testing** skill) for comprehensive E2E test suites.

The core workflow is: **write code → spin up local instance → run tests → repeat until the feature works → commit & push.**

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Write / Edit Code                                  │
│        │                                             │
│        ▼                                             │
│   preview_* tools available?                         │
│     Yes ──► Preview manages servers automatically    │
│     No  ──► Start services manually                  │
│             (podman supabase, go run, npm dev)        │
│        │                                             │
│        ▼                                             │
│   Run Backend Tests (Go)                             │
│        │                                             │
│        ▼                                             │
│   Visual / E2E Verification                          │
│     Preview mode: preview_screenshot + preview_click │
│     CLI mode: Playwright (webapp-testing skill)      │
│        │                                             │
│        ▼                                             │
│   Tests pass? ──No──► Fix & repeat from top          │
│        │                                             │
│       Yes                                            │
│        │                                             │
│        ▼                                             │
│   Commit & push ──► Done                             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

After committing and pushing, ask the user if they want to deploy to the cloud. If yes, use the **locaweb-cloud-deploy** skill to run the **Deployment Feedback Loop**, which monitors the GitHub Actions workflow, verifies the health check, and handles deployment-specific failures.

### Backend testing (Go)

Run unit tests against the local database:

```bash
bash -c 'cd backend && DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable" go test ./...'
```

- Test files live next to the code they test (`handler/todo_test.go` tests `handler/todo.go`).
- Use table-driven tests. Each test case gets a descriptive name.
- For database tests, use a test helper that runs migrations and wraps each test in a transaction that rolls back.
- Test the HTTP handlers via `httptest.NewServer` — send real HTTP requests, assert on status codes and JSON bodies.

### Frontend testing (Playwright)

Use the **webapp-testing** skill for Playwright-based end-to-end testing. The `with_server.py` helper manages the full stack:

```bash
python skills/webapp-testing/scripts/with_server.py \
  --server "podman start $(basename $(pwd))-db || true" --port 5432 \
  --server "cd backend && DATABASE_URL='postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable' go run ./cmd/server" --port 8080 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python test_script.py
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
bash -c 'cd backend && sqlc generate'
```

Then update the Go code that calls the generated functions. Never hand-write SQL in Go files.

## Conventions

- **Thin handlers:** parse request → call database → return JSON. No business logic in handlers.
- **Logging:** `slog` exclusively. Never `fmt.Println` or `log.Println`.
- **Validation:** Server-side validation for all inputs. Never trust client-side validation alone.
- **Authorization:** Checks in every handler, not just middleware.
- **Frontend components:** `bash -c 'cd frontend && npx shadcn@latest add <component>'`
- **No ORMs.** SQL through sqlc only.
- **No CSS preprocessors.** Tailwind CSS only.
- **No additional JavaScript frameworks.** React + React Router only.
