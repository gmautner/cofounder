# Post-Deployment Operations

Reference for interacting with deployed infrastructure: finding IPs, SSH access, database access, container debugging.

## Finding Deployment IPs

Every deploy workflow run produces a `provision-output` artifact containing a JSON file with all IPs. **Always clean up before downloading** to avoid reading stale data from a previous run:

```bash
# 1. Find the run ID for the environment you need
gh run list --workflow=deploy.yml --limit=5

# 2. Clean up any previous artifact, then download
rm -rf /tmp/provision-output
gh run download <run-id> --name provision-output --dir /tmp/provision-output

# 3. Read the IPs
cat /tmp/provision-output/provision-output.json
```

The JSON contains:

| Key              | Description                                                        |
|------------------|--------------------------------------------------------------------|
| `web_ip`         | Public IP of the web VM — used for SSH and app URL (`<web_ip>.nip.io`) |
| `worker_ips`     | JSON array of public worker VM IPs — used for SSH                  |
| `db_ip`          | **Public** IP of the database VM — used for **SSH only**           |
| `db_internal_ip` | **Private** IP of the database VM — used by the app to connect to Postgres (set automatically via `POSTGRES_HOST`) |

### Fallback: get IPs from the workflow run summary

If you don't need the full JSON, the workflow run summary includes an IP table:

```bash
gh run view <run-id>
```

## SSH Access

**User is always `root`.** Use the SSH key that matches the environment.

### Key locations

| Environment | Key path |
|---|---|
| preview (default) | `~/.ssh/<repo-name>` |
| production | `~/.ssh/<repo-name>-production` |
| other `<env_name>` | `~/.ssh/<repo-name>-<env_name>` |

`<repo-name>` is the name of the GitHub repository (not the owner/org prefix).

### Connection commands

```bash
# Preview environment
ssh -i ~/.ssh/<repo-name> root@<web_ip>
ssh -i ~/.ssh/<repo-name> root@<db_ip>
ssh -i ~/.ssh/<repo-name> root@<worker_ip>

# Production (or other named environment)
ssh -i ~/.ssh/<repo-name>-production root@<web_ip>
ssh -i ~/.ssh/<repo-name>-production root@<db_ip>
ssh -i ~/.ssh/<repo-name>-production root@<worker_ip>
```

## Database Access

The database VM runs PostgreSQL inside a Docker container. There is **no externally exposed psql port** — you must SSH into the DB VM first, then connect locally.

### Connect to the database

```bash
# 1. SSH into the database VM
ssh -i ~/.ssh/<repo-name> root@<db_ip>

# 2. Connect to Postgres via the container
docker exec -it <repo-name>-db psql -U postgres
```

### Understanding `db_ip` vs `db_internal_ip`

- **`db_ip`** — public IP, used for **SSH access** to the DB VM
- **`db_internal_ip`** — private IP on the CloudStack network, used by the app containers to connect to Postgres. The deploy workflow sets this automatically via the `POSTGRES_HOST` env var. You never need to use `db_internal_ip` for manual access.

### Run a one-off query

```bash
# From outside the DB VM (combines SSH + docker exec)
ssh -i ~/.ssh/<repo-name> root@<db_ip> \
  'docker exec <repo-name>-db psql -U postgres -c "SELECT version();"'
```

## Container Debugging

After SSHing into a VM, use these commands to inspect running containers:

```bash
# List running containers
docker ps

# View web app logs (last 100 lines)
docker logs $(docker ps -q --filter "label=service=<repo-name>") --tail 100

# Follow logs in real time
docker logs $(docker ps -q --filter "label=service=<repo-name>") -f

# Check if the app responds locally
curl -s localhost:80/up

# View kamal-proxy logs (web VM only)
docker logs kamal-proxy --tail 50

# Check Postgres container logs (database VM only)
docker logs <repo-name>-db --tail 100

# Check disk mounts
df -h /data/blobs    # web VM — blob/file storage
df -h /data/db       # database VM — Postgres data

# Check container environment variables
docker exec $(docker ps -q --filter "label=service=<repo-name>") env

# Open a shell inside the app container
docker exec -it $(docker ps -q --filter "label=service=<repo-name>") sh
```

## Common Pitfalls

### Stale artifact files

`gh run download` **does not** clean the target directory — it merges files, and existing files cause a collision error or are silently kept. **Always** `rm -rf /tmp/provision-output` before downloading.

### Wrong SSH key for the environment

Each environment has its own SSH key. Using the preview key to SSH into a production VM (or vice versa) will fail with `Permission denied (publickey)`. Double-check the key path matches the environment.

### Database VM has no direct psql port

You cannot `psql -h <db_ip>` from your local machine. The DB VM's firewall only allows SSH (port 22). You must SSH in first, then use `docker exec` to reach Postgres.

### Getting the repo name

The repo name used in SSH key paths and container labels is the GitHub repository name (without the owner prefix). To confirm:

```bash
gh repo view --json name -q .name
```
