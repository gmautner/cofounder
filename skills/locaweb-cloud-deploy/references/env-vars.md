# Environment Variables and Secrets Configuration

## Table of Contents

- [Environment Variables and Secrets Configuration](#environment-variables-and-secrets-configuration)
  - [Table of Contents](#table-of-contents)
  - [Platform-Provided Variables](#platform-provided-variables)
  - [Custom Clear Variables (ENV\_VARS)](#custom-clear-variables-env_vars)
  - [Custom Secret Variables (SECRET\_ENV\_VARS)](#custom-secret-variables-secret_env_vars)
  - [Passing Variables in Caller Workflows](#passing-variables-in-caller-workflows)
  - [Database Connection Variables](#database-connection-variables)
  - [Blob Storage Path](#blob-storage-path)

## Platform-Provided Variables

The platform automatically injects these into the application container. Do not set them manually.

| Variable | Type | Condition | Value |
|----------|------|-----------|-------|
| `POSTGRES_HOST` | clear | `db_enabled: true` | DB VM internal (private) IP |
| `POSTGRES_DB` | clear | `db_enabled: true` | Hardcoded to `postgres` |
| `POSTGRES_USER` | clear | `db_enabled: true` | Hardcoded to `postgres` |
| `POSTGRES_PASSWORD` | secret | `db_enabled: true` | From `POSTGRES_PASSWORD` secret |
| `DATABASE_URL` | secret | `db_enabled: true` | `postgres://postgres:<password>@<host>:5432/postgres` |
| `BLOB_STORAGE_PATH` | clear | always | `/data/blobs` |

## Custom Clear Variables (ENV_VARS)

Pass non-sensitive configuration as the `env_vars` workflow input. Uses dotenv format.

```yaml
# In the caller workflow
with:
  env_vars: |-
    APP_ENV=production
    LOG_LEVEL=info
    MAX_UPLOAD_SIZE=50MB
    FEATURE_FLAG_NEW_UI=true
```

These become clear (non-secret) environment variables in the container.

Dotenv format rules:
- One `KEY=VALUE` per line
- Supports quoting: `MY_VAR="value with spaces"`
- Comments with `#`: `# This is a comment`
- Supports `=` in values: `CONNECTION_STRING="host=localhost;port=5432"`

## Custom Secret Variables (SECRET_ENV_VARS)

Pass sensitive configuration as the `SECRET_ENV_VARS` workflow secret. Same dotenv format.

Store each secret **individually** as a GitHub Secret. **Never** create a single `SECRET_ENV_VARS` GitHub Secret containing all values — this makes it impossible to update one secret without rewriting them all.

Ask the user to set these via the GitHub UI (see [setup-and-deploy.md — Secrets the user must set via GitHub UI](setup-and-deploy.md#secrets-the-user-must-set-via-github-ui)). **Never** accept secret values through the chat.

Then compose `SECRET_ENV_VARS` in the caller workflow from individual secret references:

```yaml
# In the caller workflow
secrets:
  SECRET_ENV_VARS: |-
    STRIPE_KEY=${{ secrets.STRIPE_KEY }}
    SENDGRID_API_KEY=${{ secrets.SENDGRID_API_KEY }}
    ENCRYPTION_KEY=${{ secrets.ENCRYPTION_KEY }}
```

These become secret environment variables in the container (never logged).

## Passing Variables in Caller Workflows

Complete example showing both clear and secret custom variables for a production environment. Note how environment-scoped secrets use the `_PRODUCTION` suffix, while common secrets (`CLOUDSTACK_*`) are shared across all environments:

```yaml
jobs:
  deploy:
    uses: gmautner/locaweb-cloud-deploy/.github/workflows/deploy.yml@v0
    with:
      env_name: "production"
      zone: "ZP01"
      db_enabled: true
      env_vars: |-
        APP_ENV=production
        LOG_LEVEL=warn
        ALLOWED_HOSTS=myapp.example.com
    secrets:
      CLOUDSTACK_API_KEY: ${{ secrets.CLOUDSTACK_API_KEY }}
      CLOUDSTACK_SECRET_KEY: ${{ secrets.CLOUDSTACK_SECRET_KEY }}
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY_PRODUCTION }}
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD_PRODUCTION }}
      SECRET_ENV_VARS: |-
        API_KEY=${{ secrets.API_KEY_PRODUCTION }}
        JWT_SECRET=${{ secrets.JWT_SECRET_PRODUCTION }}
```

## Database Connection Variables

When `db_enabled: true`, the application source code must use these env vars:

```python
# Python example
import os
host = os.environ["POSTGRES_HOST"]
db = os.environ["POSTGRES_DB"]
user = os.environ["POSTGRES_USER"]
password = os.environ["POSTGRES_PASSWORD"]
# Or use the composite URL:
database_url = os.environ["DATABASE_URL"]
# database_url = "postgres://user:password@host:5432/dbname"
```

```javascript
// Node.js example
const connectionString = process.env.DATABASE_URL;
// Or individual variables:
const config = {
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  port: 5432
};
```

```ruby
# Ruby/Rails example (config/database.yml)
production:
  url: <%= ENV["DATABASE_URL"] %>
```

The port is always 5432.

## Blob Storage Path

All containers have `/data/blobs` mounted as persistent storage (backed by a dedicated disk). Use the `BLOB_STORAGE_PATH` env var (always set to `/data/blobs`) for file storage paths.

The `/data/blobs` directory may contain a `lost+found` entry from the ext4 filesystem -- filter this out when listing files.
