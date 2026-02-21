# Caller Workflow Reference

## Table of Contents

- [Preview Workflow (Default)](#preview-workflow-default)
- [Additional Environments](#additional-environments)
- [Deploy Input Reference](#deploy-input-reference)
- [Complete Example (All Inputs)](#complete-example-all-inputs)
- [Workflow Permissions](#workflow-permissions)
- [Passing Outputs to Downstream Jobs](#passing-outputs-to-downstream-jobs)

## Preview Workflow (Default)

The default preview environment is triggered on push, immediately reflecting changes to the main branch — matching a typical developer workflow. No domain needed, uses nip.io for immediate access. Since `"preview"` is the default `env_name`, secrets use unsuffixed names.

```yaml
# .github/workflows/deploy-preview.yml
name: Deploy Preview
on:
  push:
    branches: [main]
    paths-ignore: [".claude/**"]

permissions:
  contents: read
  packages: write

jobs:
  deploy:
    uses: gmautner/locaweb-cloud-deploy/.github/workflows/deploy.yml@v0
    with:
      env_name: "preview"
      zone: "ZP01"
      db_enabled: true
      db_plan: "medium"
    secrets:
      CLOUDSTACK_API_KEY: ${{ secrets.CLOUDSTACK_API_KEY }}
      CLOUDSTACK_SECRET_KEY: ${{ secrets.CLOUDSTACK_SECRET_KEY }}
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
```

After this runs successfully, the app is accessible at `http://<web_ip>.nip.io`. The `web_ip` is visible in the workflow run summary.

## Additional Environments

Other environments can be created depending on your processes, changing the triggers and workflow inputs as needed. Each `env_name` creates fully isolated infrastructure.

### Secret naming convention

Since `"preview"` is the default environment, its secrets use **unsuffixed** names:

- `SSH_PRIVATE_KEY`, `POSTGRES_PASSWORD`
- Custom secrets: `API_KEY`, `SMTP_PASSWORD`

For additional environments, suffix secret names that are **scoped to that environment** with the environment name (uppercased):

- `SSH_PRIVATE_KEY_PRODUCTION`, `POSTGRES_PASSWORD_PRODUCTION`
- Custom secrets: `API_KEY_PRODUCTION`, `SMTP_PASSWORD_PRODUCTION`

Secrets **common to all environments** (e.g., `CLOUDSTACK_API_KEY`, `CLOUDSTACK_SECRET_KEY`) don't need suffixes — just pass them in every caller workflow.

The caller workflow maps the suffixed secrets to the reusable workflow's standard secret names (see example below).

### Production workflow example

A recommended additional environment is **"production"**, triggered on version tags (`v*`). A tag signals that the pointed commit is ready for production. Uses a custom domain with automatic HTTPS.

```yaml
# .github/workflows/deploy-production.yml
name: Deploy Production
on:
  push:
    tags: ["v*"]  # Triggered by version tags (e.g., git tag v1.0.0 && git push --tags)

permissions:
  contents: read
  packages: write

jobs:
  deploy:
    uses: gmautner/locaweb-cloud-deploy/.github/workflows/deploy.yml@v0
    with:
      env_name: "production"
      zone: "ZP01"
      domain: "myapp.example.com"
      web_plan: "medium"
      db_enabled: true
      db_plan: "medium"
      db_disk_size_gb: 50
      blob_disk_size_gb: 50
    secrets:
      CLOUDSTACK_API_KEY: ${{ secrets.CLOUDSTACK_API_KEY }}
      CLOUDSTACK_SECRET_KEY: ${{ secrets.CLOUDSTACK_SECRET_KEY }}
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY_PRODUCTION }}
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD_PRODUCTION }}
```

To deploy to production: `git tag v1.0.0 && git push --tags`. The workflow checks out the tagged commit, so the Dockerfile and source code match the tag exactly.

## Deploy Input Reference

All inputs, their types, defaults, and when to use them:

| Input | Type | Default | When to set |
|-------|------|---------|-------------|
| `env_name` | string | `"preview"` | Name of the environment. Each env_name creates fully isolated infrastructure. Defaults to `"preview"` if omitted. |
| `zone` | string | `"ZP01"` | CloudStack zone. Usually leave as default. Use `ZP02` for geographic redundancy. |
| `domain` | string | `""` (empty) | Set for production environments where HTTPS is needed. Leave empty for preview/dev (uses nip.io). See SKILL.md for the DNS setup procedure. |
| `web_plan` | string | `"small"` | Choose based on runtime footprint and environment. See [scaling.md](scaling.md) for plan specs. |
| `blob_disk_size_gb` | number | `20` | Increase if the app stores files (uploads, media). Consider environment: preview can use smaller, production may need more. Can only grow, never shrink. |
| `workers_enabled` | boolean | `false` | Set `true` when the app needs background processing. |
| `workers_replicas` | number | `1` | Number of worker VMs. Only relevant when `workers_enabled: true`. |
| `workers_cmd` | string | `"sleep infinity"` | Command to run in worker containers. e.g., `"celery -A tasks worker --loglevel=info"` or `"python worker.py"`. |
| `workers_plan` | string | `"small"` | VM size for workers. Choose based on worker workload intensity. See [scaling.md](scaling.md). |
| `db_enabled` | boolean | `false` | Set `true` when the app needs PostgreSQL. Requires `POSTGRES_PASSWORD` secret. |
| `db_plan` | string | `"medium"` | VM size for the database. Choose based on expected data size and query complexity. See [scaling.md](scaling.md). |
| `db_disk_size_gb` | number | `20` | PostgreSQL data disk size. Consider environment and expected data growth. Can only grow, never shrink. |
| `automatic_reboot` | boolean | `true` | Enable automatic reboot after unattended security upgrades. Usually leave as default. |
| `automatic_reboot_time_utc` | string | `"05:00"` | When automatic reboots happen. Usually leave as default. |
| `recover` | boolean | `false` | Reserved for future disaster recovery workflows. Do not use. |
| `env_vars` | string | `""` | Dotenv-formatted clear environment variables. See [env-vars.md](env-vars.md). |

### Inputs to leave at defaults

For most deployments, omit these (let defaults apply):
- `automatic_reboot` / `automatic_reboot_time_utc` -- security auto-updates are good defaults
- `recover` -- reserved for future use
- `blob_disk_size_gb` -- 20 GB is sufficient for most apps unless heavy file storage

## Complete Example (All Inputs)

Full-stack example with web, database, and workers. Every input is shown with required/optional and default value annotations.

```yaml
# .github/workflows/deploy-preview.yml
name: Deploy Preview
on:
  push:
    branches: [main]
    paths-ignore: [".claude/**"]

permissions:
  contents: read
  packages: write

jobs:
  deploy:
    uses: gmautner/locaweb-cloud-deploy/.github/workflows/deploy.yml@v0
    with:
      env_name: "preview"                    # Optional, default: "preview"
      zone: "ZP01"                           # Optional, default: "ZP01" (options: ZP01, ZP02)
      domain: ""                             # Optional, default: "" (empty = nip.io, no HTTPS)
      web_plan: "small"                      # Optional, default: "small"
      blob_disk_size_gb: 20                  # Optional, default: 20 (grow only, never shrink)
      workers_enabled: true                  # Optional, default: false
      workers_replicas: 2                    # Optional, default: 1 (only when workers_enabled: true)
      workers_cmd: "python worker.py"        # Optional, default: "sleep infinity"
      workers_plan: "small"                  # Optional, default: "small"
      db_enabled: true                       # Optional, default: false
      db_plan: "medium"                      # Optional, default: "medium"
      db_disk_size_gb: 20                    # Optional, default: 20 (grow only, never shrink)
      automatic_reboot: true                 # Optional, default: true
      automatic_reboot_time_utc: "05:00"     # Optional, default: "05:00"
      recover: false                         # Optional, default: false (reserved for future DR)
      env_vars: |-                           # Optional, default: "" (dotenv format)
        APP_ENV=preview
        LOG_LEVEL=debug
    secrets:
      CLOUDSTACK_API_KEY: ${{ secrets.CLOUDSTACK_API_KEY }}       # Required
      CLOUDSTACK_SECRET_KEY: ${{ secrets.CLOUDSTACK_SECRET_KEY }} # Required
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}             # Required
      POSTGRES_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}         # Required when db_enabled: true
      SECRET_ENV_VARS: |-                                        # Optional (dotenv format)
        API_KEY=${{ secrets.API_KEY }}
        SMTP_PASSWORD=${{ secrets.SMTP_PASSWORD }}
```

## Workflow Permissions

The deploy caller workflow **must** include:

```yaml
permissions:
  contents: read
  packages: write
```

`packages: write` is required because the reusable deploy workflow pushes the container image to ghcr.io internally via Kamal. The teardown workflow does not need `packages: write`.

## No Docker Build Steps in Caller Workflows

Do **not** add any of these to the caller workflow:

- `docker/build-push-action` or `docker/login-action` actions
- `docker build`, `docker push`, or `docker login` commands
- Any step that builds or pushes a container image

The reusable deploy workflow handles the entire Docker lifecycle internally: it checks out the application code, generates a Kamal configuration pointing to ghcr.io, and runs `kamal setup`, which builds the image from the Dockerfile at the repo root, pushes it to ghcr.io, and deploys it to the VMs — all in a single step. The `GITHUB_TOKEN` (provided automatically by GitHub Actions) is used as the registry credential, so no separate registry login is needed either.

## Passing Outputs to Downstream Jobs

The deploy workflow exposes outputs that can be consumed by subsequent jobs:

```yaml
jobs:
  deploy:
    uses: gmautner/locaweb-cloud-deploy/.github/workflows/deploy.yml@v0
    with:
      # ... inputs
    secrets:
      # ... secrets

  notify:
    needs: deploy
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Web IP: ${{ needs.deploy.outputs.web_ip }}"
          echo "Worker IPs: ${{ needs.deploy.outputs.worker_ips }}"
          echo "DB IP: ${{ needs.deploy.outputs.db_ip }}"
          echo "DB Internal IP: ${{ needs.deploy.outputs.db_internal_ip }}"
```

Available outputs:
- `web_ip` -- Public IP of the web VM
- `worker_ips` -- JSON array of worker VM public IPs (e.g., `["1.2.3.4","5.6.7.8"]`)
- `db_ip` -- Public IP of the database VM (SSH access only)
- `db_internal_ip` -- Private IP of the database VM (used by the app internally)
