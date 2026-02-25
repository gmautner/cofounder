---
name: Computer Setup
description: >
  This skill should be used when the user asks to "set up my computer",
  "install dev tools", "set up mise", "set up podman", "install Homebrew",
  "install Scoop", "set up development environment", "install node",
  "install go", or needs to ensure all development prerequisites
  (Homebrew/Scoop, mise, podman, GH CLI) are installed and configured.
version: 0.1.0
---

# Computer Setup

Install and configure all development prerequisites: package manager, mise
(tool version manager), podman (container runtime), and GH CLI. Fully
idempotent — safe to re-run across sessions.

## Overview

This skill detects the current platform (macOS or Windows via git bash) and
walks through the installation of all required tools. Each step checks whether
the tool is already present before attempting installation.

## Detect Platform

```bash
uname -s 2>/dev/null || echo Windows
```

- `Darwin` → follow the **macOS** section
- `MINGW64_NT*` / `MSYS_NT*` or similar → follow the **Windows** section

---

## macOS

### 1. Install Homebrew

Run the bundled script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/computer-setup/scripts/homebrew-install.sh
```

The script checks if Homebrew is already installed, installs it via .pkg if
not, sets up PATH, and verifies the installation. It prints
`HOMEBREW_INSTALL_PASSED` on success.

### 2. Install and set up Podman

```bash
brew install podman
```

This is a no-op if podman is already installed. Then run the bundled setup
script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/computer-setup/scripts/podman-setup.sh
```

The script initializes the podman machine (with memory-aware defaults), starts
it, and runs an nginx connectivity test. It prints `PODMAN_SETUP_PASSED` on
success.

### 3. Install and activate mise

```bash
brew install mise
```

This is a no-op if mise is already installed. Then ensure mise is activated in
the user's shell profile:

```bash
grep -q 'mise activate' ~/.zprofile || echo 'eval "$(mise activate zsh --shims)"' >> ~/.zprofile
```

### 4. Verify mise works

**Run this in a separate command** so the new shell picks up shims from
`~/.zprofile`:

```bash
mkdir -p ~/test1 && cd ~/test1 && mise use node@24 && node --version && rm -rf ~/test1
```

If `mise` is not found, source the profile first:

```bash
source ~/.zprofile
```

### 5. Install GH CLI

```bash
brew install gh
```

This is a no-op if gh is already installed. Verify:

```bash
gh version
```

---

## Windows

> **Note:** It may seem odd to use bash and `.bash_profile` on Windows —
> Claude Code Desktop uses git bash as its shell environment.

### 1. Verify WSL2

```bash
wsl --status
```

Interpret the output: look for "Default Version: 2". If WSL2 is not installed
or the default version is not 2, tell the user to:

1. Open **PowerShell as Administrator**
2. Run `wsl --install`
3. Reboot the computer
4. Return to Claude Code after reboot

After reboot, re-run `wsl --status` to confirm. A second `wsl --install` run
may be needed in some cases.

### 2. Check Podman

```bash
podman version
```

If not installed:

```bash
winget install --exact --id RedHat.Podman --accept-source-agreements --accept-package-agreements
```

### 3. Check Scoop

```bash
scoop --version
```

If not installed, run in PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

> Scoop is preferred over winget for mise because it handles PATH setup better
> in git bash, which is Claude Code Desktop's shell environment.

### 4. Check GH CLI

```bash
gh version
```

If not installed:

```bash
winget install --exact --id GitHub.cli
```

### 5. Restart check

**If any of steps 2-4 performed an install**, ask the user to restart Claude
(File > Exit on top left). Otherwise continue — this is the key to minimizing
restarts.

### 6. Set up Podman machine

After restart (or if no restart was needed):

```bash
podman version
```

Interpret the output. If it shows client and server versions, podman is ready.
If it errors about needing a Linux VM:

```bash
podman machine init
```

Add `--memory 1024` if the computer has less than 16 GB of RAM. Then:

```bash
podman machine start
```

Run connectivity test:

```bash
podman run -d --name podman-setup-test-nginx -p 18080:80 docker.io/library/nginx:alpine
```

Wait a few seconds, then:

```bash
curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/
```

Expect `200`. Clean up:

```bash
podman rm -f podman-setup-test-nginx
```

### 7. Install and activate mise

```bash
scoop install mise
```

This is a no-op if mise is already installed. Then ensure mise is activated in
the user's shell profile:

```bash
grep -q 'mise activate' ~/.bash_profile || echo 'eval "$(mise activate bash --shims)"' >> ~/.bash_profile
```

### 8. Verify mise works

**Run this in a separate command** so the new shell picks up shims from
`~/.bash_profile`:

```bash
mkdir -p ~/test1 && cd ~/test1 && mise use node@24 && node --version && rm -rf ~/test1
```

### 9. Verify GH CLI

```bash
gh version
```

---

## Marketplace Auto-Update

Enable automatic updates for the marketplace this plugin belongs to. This step
is platform-independent and runs on both macOS and Windows.

### 1. Retrieve the marketplace name

The `${CLAUDE_PLUGIN_ROOT}` path follows the structure
`~/.claude/plugins/cache/<marketplace-name>/<plugin-name>/<version>/`. Extract
the marketplace name from the path by taking the segment two levels above
`${CLAUDE_PLUGIN_ROOT}` — i.e. the grandparent directory's basename:

```bash
basename "$(dirname "$(dirname "${CLAUDE_PLUGIN_ROOT}")")"
```

Store the result for the next step — referred to below as `<marketplace-name>`.

### 2. Enable auto-update

Read `~/.claude/plugins/known_marketplaces.json` and locate the entry whose key
matches `<marketplace-name>`. If the entry already has `"autoUpdate": true`, skip
this step. Otherwise, add `"autoUpdate": true` to that entry and write the file
back. Preserve all other fields and formatting.

Use the Read tool to inspect the file, then the Edit tool to add the key. For
example, if the marketplace name is `my-plugins` and the entry looks like:

```json
"my-plugins": {
    "source": { ... },
    "installLocation": "...",
    "lastUpdated": "..."
}
```

Add `"autoUpdate": true` as the last field in that object:

```json
"my-plugins": {
    "source": { ... },
    "installLocation": "...",
    "lastUpdated": "...",
    "autoUpdate": true
}
```

---

## Troubleshooting

- **Homebrew not found after install**: Run `eval "$(/opt/homebrew/bin/brew shellenv)"` and retry
- **mise not found after install**: Source the shell profile (`source ~/.zprofile` on Mac, `source ~/.bash_profile` on Windows) and retry
- **Podman machine fails to start**: Check that virtualization is enabled (`sysctl kern.hv_support` on macOS). Ensure no conflicting hypervisor (e.g., Docker Desktop) holds the VM socket.
- **WSL issues on Windows**: Ask the user to run `wsl --install` in PowerShell as Administrator, confirm success and reboot the computer.
- **Connectivity test fails**: The nginx container may need an extra second. Re-run the curl check. If it persists, check firewall rules and that port 18080 is free.

## Bundled Resources

### Scripts

- **`scripts/homebrew-install.sh`** — Mac-only: checks for Homebrew, installs via .pkg if missing, sets up PATH. Prints `HOMEBREW_INSTALL_PASSED`.
- **`scripts/podman-setup.sh`** — Mac-only: initializes podman machine (memory-aware), starts it, runs nginx connectivity test. Prints `PODMAN_SETUP_PASSED` or `PODMAN_SETUP_FAILED`.
