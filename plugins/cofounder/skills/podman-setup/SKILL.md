---
name: Podman Setup
description: >
  This skill should be used when the user asks to "set up podman", "initialize podman",
  "start the podman VM", "prepare the podman environment", "check if podman is ready",
  "test container connectivity", "podman machine won't start", "set up WSL",
  "install podman on Windows", or needs to ensure the podman machine is initialized
  and running before spinning up containers.
version: 0.2.0
---

# Podman Machine Setup

Ensure the podman virtual machine is initialized, running, and able to serve
containers.

## Overview

Podman runs containers through a lightweight VM (podman machine). Before any
container workload can run, the VM must exist and be started. This skill
handles that setup idempotently: it is safe to run on a fresh system or on one
where the podman machine is already configured.

## Prerequisites

The **mise-setup** skill must have been run first. On macOS and Linux, podman is
managed by mise. On Windows, podman is installed externally.

## Platform-Specific Setup

### macOS and Linux

Run the bundled setup script through mise:

```bash
mise exec podman@5 -- bash ${CLAUDE_PLUGIN_ROOT}/skills/podman-setup/scripts/podman-setup.sh
```

The script prints `PODMAN_SETUP_PASSED` on success or `PODMAN_SETUP_FAILED` with
an error description on failure.

#### What the Script Does

1. **Check for an existing podman machine** — If none exists, initialize one.
   On systems with less than 16 GB of RAM, the VM memory is set to 1024 MB
   instead of the default 2048 MB.
2. **Start the machine** — If the machine exists but is not running, start it.
3. **Connectivity test** — Pull and run an `nginx:alpine` container, verify
   HTTP 200 from localhost, then remove the container.

#### Idempotency

The operation is idempotent and non-destructive:

- An already-initialized machine is left untouched.
- An already-running machine is not restarted.
- The test container is cleaned up regardless of outcome.

#### Manual Steps (Reference)

If running the steps individually rather than through the script:

```bash
# List existing machines
mise exec podman@5 -- podman machine ls

# Initialize (low-memory variant)
mise exec podman@5 -- podman machine init --memory 1024

# Initialize (default, 16 GB+ systems)
mise exec podman@5 -- podman machine init

# Start
mise exec podman@5 -- podman machine start

# Quick connectivity test
mise exec podman@5 -- podman run -d --name test-nginx -p 18080:80 docker.io/library/nginx:alpine
curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/
mise exec podman@5 -- podman rm -f test-nginx
```

### Windows (Podman via WSL)

On Windows, podman cannot be installed via mise. Follow these steps:

#### 1. WSL Pre-Check

Run in PowerShell:

```powershell
wsl --status
```

Or:

```powershell
wsl -l -v
```

#### 2. Install WSL (if not present)

If WSL is not installed, tell the user to open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

**Important:** The user must restart their computer after WSL installation.
Stop and wait — the user must come back after restarting before proceeding.

#### 3. Install Podman

Podman cannot be scripted on Windows. Guide the user to install
**Podman Desktop** or **Podman CLI** from https://podman.io/.

Wait for the user to confirm the installation is complete before continuing.

#### 4. Verify Podman

Once podman is installed:

```powershell
podman machine ls
podman machine start
```

Then run a connectivity test:

```powershell
podman run -d --name test-nginx -p 18080:80 docker.io/library/nginx:alpine
curl -s -o /dev/null -w "%{http_code}" http://localhost:18080/
podman rm -f test-nginx
```

## Troubleshooting

- **"machine already exists"** — Expected when re-running; the script handles this.
- **Machine fails to start** — Check that virtualization is enabled (`sysctl kern.hv_support` on macOS). Also ensure no conflicting hypervisor (e.g., Docker Desktop) holds the VM socket.
- **Connectivity test fails** — The nginx container may need an extra second to start. Re-run the script. If it persists, check firewall rules and that port 18080 is free.
- **Low disk space** — `podman machine init` downloads a VM image. Ensure at least 2 GB of free disk.
- **WSL issues on Windows** — Ensure Windows is up to date and virtualization is enabled in BIOS/UEFI.

## Bundled Resources

### Scripts

- **`scripts/podman-setup.sh`** — Idempotent setup (macOS/Linux): initializes the podman machine (with memory-aware defaults), starts it, and validates connectivity via an nginx container test. Prints `PODMAN_SETUP_PASSED` or `PODMAN_SETUP_FAILED`.
