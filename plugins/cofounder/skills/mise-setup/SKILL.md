---
name: Mise Setup
description: >
  This skill should be used when the user asks to "set up mise", "initialize mise",
  "create a dev environment", "set up development tools", "install mise",
  "configure development packages", "mise init", or asks about setting up a
  cross-platform development environment for the cofounder project.
version: 0.1.0
---

# Mise Development Environment Setup

Set up cross-platform development tooling using [mise](https://mise.jdx.dev/)
with a predefined set of tools for the cofounder project.

## Overview

Mise is a cross-platform tool version manager that handles Go, Node, Python,
sqlc, jq, and podman. It works on macOS, Linux, and Windows. Tools are
auto-installed on first use and cached locally.

## Setup Procedure

### 1. Detect Platform

Run this command to determine the current platform:

```bash
uname -s 2>/dev/null || echo Windows
```

This returns `Darwin` (macOS), `Linux`, or `Windows`.

### 2. Install Mise and Prerequisites

#### macOS

On macOS, use the bundled init script that handles everything automatically:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mise-setup/scripts/mise-init.sh
```

The script will:
1. Ensure Homebrew is installed (downloads the .pkg if missing)
2. Install mise via Homebrew
3. Pre-install all managed tools
4. Install GH CLI via Homebrew

If running steps manually:

```bash
# Ensure Homebrew is installed
command -v brew || {
  curl -L -o /tmp/Homebrew.pkg https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg
  sudo installer -pkg /tmp/Homebrew.pkg -target /
}

# Install mise
brew install mise

# Install GH CLI
brew install gh
```

#### Linux

On Linux, use the bundled init script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/mise-setup/scripts/mise-init.sh
```

The script will:
1. Install mise via the official installer
2. Add `~/.local/bin` to PATH
3. Pre-install all managed tools
4. Install GH CLI from precompiled binary

If running steps manually:

```bash
# Install mise
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# Install GH CLI (precompiled binary)
# Detect architecture and download from https://github.com/cli/cli/releases
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) GH_ARCH="amd64" ;;
  aarch64|arm64) GH_ARCH="arm64" ;;
esac
GH_VERSION=$(curl -sL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
curl -sL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" | tar xz -C /tmp
install -m 755 "/tmp/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" "$HOME/.local/bin/gh"
```

#### Windows

```powershell
# Install mise
winget install jdx.mise

# Install GH CLI
winget install GitHub.cli
```

**Git on Windows:** Verify git is available with `git --version`. If missing,
guide the user to https://git-scm.com/downloads/win to install it.

### 3. Tools Managed by Mise

The following tools are installed via mise on **all platforms**:

| Tool | Version | Purpose |
|------|---------|---------|
| `go` | `@1` | Backend language |
| `sqlc` | `@1` | SQL code generator |
| `python` | `@3.14` | Scripting and testing |
| `node` | `@24` | Frontend tooling |
| `jq` | `@1` | JSON processing |

The following tool is installed via mise on **macOS and Linux only**:

| Tool | Version | Purpose |
|------|---------|---------|
| `podman` | `@5` | Container runtime |

On Windows, podman must be installed externally (see the **podman-setup** skill).

### 4. Verify the Environment

Run `mise exec <tool>@<version> -- <tool> --version` for each managed tool.
This auto-installs on first use and caches the tool:

```bash
mise exec go@1 -- go version
mise exec sqlc@1 -- sqlc version
mise exec python@3.14 -- python --version
mise exec node@24 -- node --version
mise exec jq@1 -- jq --version
```

On macOS and Linux, also verify podman:

```bash
mise exec podman@5 -- podman --version
```

Verify GH CLI (installed outside mise, directly on PATH):

```bash
gh --version
```

Verify git:

```bash
git --version
```

**Important:** Use `mise exec <tool>@<version> -- <command>` to run commands
with managed tools. Each invocation ensures the correct tool version is active.

## Common Operations

| Operation | Command |
|---|---|
| Run a managed tool | `mise exec <tool>@<version> -- <command>` |
| Check installed tools | `mise ls` |
| Install a specific version | `mise install <tool>@<version>` |
| Upgrade mise | macOS: `brew upgrade mise` / Linux: `curl https://mise.run \| sh` |

## Troubleshooting

- **mise not found after install**: Add `$HOME/.local/bin` to PATH and restart the shell
- **Tool version not found**: Run `mise ls-remote <tool>` to list available versions
- **Permission errors on macOS**: Homebrew may need `sudo` for the initial .pkg install

## Bundled Resources

### Scripts

- **`scripts/mise-init.sh`** — Detects OS, installs mise and prerequisites (Homebrew on Mac), pre-installs all managed tools, and installs GH CLI. Mac and Linux only.
