---
name: Devbox Setup
description: >
  This skill should be used when the user asks to "set up devbox", "initialize devbox",
  "create a dev environment with devbox", "set up development shell", "install devbox",
  "configure devbox packages", "add packages to devbox", "devbox init", or asks about
  setting up a reproducible development environment for the cofounder project.
version: 0.1.0
---

# Devbox Development Environment Setup

Set up an isolated, reproducible development shell using
[Devbox](https://www.jetify.com/docs/devbox) with a predefined set of packages
for the cofounder project.

## Overview

Devbox provides isolated development environments powered by Nix without requiring
direct Nix knowledge — per-project package management with deterministic,
reproducible builds across machines.

## Setup Procedure

### 1. Ensure Devbox Is Installed

Check whether `devbox` is available on PATH. If not, install it:

```bash
curl -fsSL https://get.jetify.com/devbox | bash
```

Alternatively, run the bundled init script that handles detection, installation,
and project initialization in one step:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/devbox-setup/scripts/devbox-init.sh
```

After installation, verify with `devbox version`.

### 2. Configure Packages

Copy the template directly into the project root as `devbox.json`:

```bash
cp ${CLAUDE_PLUGIN_ROOT}/skills/devbox-setup/scripts/devbox.json.template devbox.json
```

The template at `scripts/devbox.json.template` is the single source of truth for
the standard package set. Inspect it for the full list of packages and versions.

There is no need to run `devbox init` separately — the template file is a complete
`devbox.json`.

**Important notes on packages:**
- `postgresql@17` is for the `psql` client tool only — do NOT enable the PostgreSQL service plugin
- Version constraints use major versions (e.g., `go@1.26`) to allow patch-level updates
- Packages are resolved from the Nixpkgs registry via Devbox

Alternatively, add packages one-by-one using `devbox add <package>`:

```bash
devbox add go@1.26 sqlc@1 python@3.14 git@2 curl@8 openssl@3 jq@1 yq@3 gh@2 postgresql@17 nodejs@24 podman@5 podman-compose@1
```

### 3. Verify the Environment

Use `devbox run --` to execute commands inside the devbox environment. Each
`devbox run -- <command>` runs the given command with access to all configured
packages, without needing an interactive shell session:

```bash
devbox run -- go version
devbox run -- sqlc version
devbox run -- python3 --version
devbox run -- node --version
devbox run -- psql --version
devbox run -- gh --version
```

**Important:** Do not use `devbox shell` when running commands from the agent,
since each Bash tool invocation is a separate session. Always use
`devbox run -- <command>` to ensure the command executes inside the devbox
environment. `devbox shell` is only useful for interactive terminal sessions.

## Common Operations

| Operation | Command |
|---|---|
| Add a package | `devbox add <pkg>@<version>` |
| Remove a package | `devbox rm <pkg>` |
| List packages | `devbox list` |
| Run a command | `devbox run -- <command>` |
| Enter interactive shell | `devbox shell` (interactive use only) |
| Update packages | `devbox update` |
| Search packages | `devbox search <query>` |

## Troubleshooting

- **devbox not found after install**: Add `$HOME/.local/bin` to PATH and restart the shell
- **Package version not found**: Use `devbox search <pkg>` to list available versions
- **Nix store errors**: Run `devbox doctor` to diagnose environment issues

## Bundled Resources

### Scripts

- **`scripts/devbox-init.sh`** — Detects and installs devbox if missing, initializes the project, and applies the standard package template
- **`scripts/devbox.json.template`** — Canonical devbox.json with the standard package set (single source of truth)
