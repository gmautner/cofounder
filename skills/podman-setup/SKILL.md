---
name: Podman Setup
description: >
  This skill should be used when the user asks to "set up podman", "initialize podman",
  "start the podman VM", "prepare the podman environment", "check if podman is ready",
  "test container connectivity", "podman machine won't start", or needs to ensure the
  podman machine is initialized and running before spinning up containers.
version: 0.1.0
---

# Podman Machine Setup

Ensure the podman virtual machine is initialized, running, and able to serve
containers — all within the devbox environment.

## Overview

Podman runs containers through a lightweight VM (podman machine). Before any
container workload can run, the VM must exist and be started. This skill
handles that setup idempotently: it is safe to run on a fresh system or on one
where the podman machine is already configured.

## Prerequisites

Devbox must already be set up with `podman` in the package list. The devbox-setup
skill handles this. All commands in this skill run through `devbox run --`.

## Setup Procedure

Run the bundled setup script, which performs all steps automatically:

```bash
devbox run -- bash ${CLAUDE_PLUGIN_ROOT}/skills/podman-setup/scripts/podman-setup.sh
```

The script prints `PODMAN_SETUP_PASSED` on success or `PODMAN_SETUP_FAILED` with
an error description on failure.

### What the Script Does

1. **Check for an existing podman machine** — If none exists, initialize one.
   On systems with less than 8 GB of RAM, the VM memory is set to 1024 MB
   instead of the default 2048 MB.
2. **Start the machine** — If the machine exists but is not running, start it.
3. **Connectivity test** — Pull and run an `nginx:alpine` container, verify
   HTTP 200 from localhost, then remove the container.

### Idempotency

The operation is idempotent and non-destructive:

- An already-initialized machine is left untouched.
- An already-running machine is not restarted.
- The test container is cleaned up regardless of outcome.

## Manual Steps (Reference)

If running the steps individually rather than through the script:

```bash
# List existing machines
devbox run -- podman machine ls

# Initialize (low-memory variant)
devbox run -- podman machine init --memory 1024

# Initialize (default, 8 GB+ systems)
devbox run -- podman machine init

# Start
devbox run -- podman machine start

# Quick connectivity test
devbox run -- podman run -d --name test-nginx -p 18080:80 docker.io/library/nginx:alpine
curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/
devbox run -- podman rm -f test-nginx
```

## Troubleshooting

- **"machine already exists"** — Expected when re-running; the script handles this.
- **Machine fails to start** — Check that virtualization is enabled (`sysctl kern.hv_support` on macOS). Also ensure no conflicting hypervisor (e.g., Docker Desktop) holds the VM socket.
- **Connectivity test fails** — The nginx container may need an extra second to start. Re-run the script. If it persists, check firewall rules and that port 18080 is free.
- **Low disk space** — `podman machine init` downloads a VM image. Ensure at least 2 GB of free disk.

## Bundled Resources

### Scripts

- **`scripts/podman-setup.sh`** — Idempotent setup: initializes the podman machine (with memory-aware defaults), starts it, and validates connectivity via an nginx container test. Prints `PODMAN_SETUP_PASSED` or `PODMAN_SETUP_FAILED`.
