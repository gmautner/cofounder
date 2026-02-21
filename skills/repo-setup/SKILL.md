---
name: Repository Setup
description: >
  This skill should be used when the user asks to "set up a repo", "create a GitHub repo",
  "initialize git", "create a remote repository", "push to GitHub", "log in to GitHub",
  "gh auth", "set up GitHub", or asks about initializing a local and remote repository
  and pushing it to GitHub.
version: 0.1.0
---

# Repository Setup

Initialize a local git repository and create a matching remote on GitHub using
the GH CLI, with device-code authentication that works reliably in all
environments.

## Authentication

### Device Code Flow

The GH CLI supports a device code flow that does not depend on automatically
opening a browser window. This is the preferred method because the agent cannot
guarantee browser access.

**Before running the auth command, display a message to the user** telling
them to watch for the one-time code.
Example message to display before the tool call:

> **GitHub login required.** Look for your one-time code (`XXXX-XXXX`)
> in the command output below. Open **https://github.com/login/device**
> in your browser and enter the code.

Then run the auth script:

```bash
devbox run -- bash ${CLAUDE_PLUGIN_ROOT}/skills/repo-setup/scripts/gh-auth.sh
```

The script checks if already authenticated first. If not, it starts
`gh auth login` using the device code flow (no `--web` flag). The command
prints a one-time code and URL, then blocks until the user authorizes in
the browser. After authorization, credentials are stored automatically.
Requested scopes are `repo`, `read:org`, and `workflow`.

### Verifying Authentication

Confirm the session is active:

```bash
devbox run -- gh auth status
```

## Repository Initialization

### Full Setup

**Before running the init script, check if a remote is already configured:**

```bash
git remote get-url origin 2>/dev/null
```

If `origin` is already set, the repo is fully configured — **do not ask the
user for a name or visibility, and skip the init script entirely.**

If no remote is configured, ask the user for:
- **Repository name** — suggest the current folder name (basename of the
  working directory) as the default. Do not suggest the plugin name.
- **Visibility** — `private` (default) or `public`.

Then run the init script:

```bash
devbox run -- bash ${CLAUDE_PLUGIN_ROOT}/skills/repo-setup/scripts/repo-init.sh <repo-name> [private|public]
```

The script will:
1. Initialize a local git repo if `.git/` does not exist
2. Create an initial empty commit if the repo has no commits
3. Skip remote creation if `origin` is already configured locally
4. If the repo already exists on GitHub, add it as `origin` and push
5. Otherwise, create the GitHub repository with the given name and visibility (default: `private`), add it as `origin`, and push

### Manual Steps

If finer control is needed, run each step individually:

```bash
# Initialize local repo
git init

# Create remote and link it (from the project directory)
devbox run -- gh repo create <repo-name> --private --source=. --remote=origin --push
```

## Important Notes

- **All `gh` and `git` commands require devbox.** Prefix with `devbox run --` when
  calling from the agent (e.g., `devbox run -- gh auth status`). The bundled scripts
  call `gh` and `git` directly, so execute them via `devbox run -- bash <script>`.
- **Authentication must happen before repo creation.** Run `gh-auth.sh` first
  if `devbox run -- gh auth status` fails.
- **Do not use `--web` flag** for `gh auth login` — it attempts to open a browser
  which may not work. The device code flow (default when `--web` is omitted) is
  more reliable.
- **Default visibility is private.** Always confirm with the user before creating
  a public repository.

## Bundled Resources

### Scripts

- **`scripts/gh-auth.sh`** — Authenticates with GitHub using the device code flow; prints the one-time code and URL for the user
- **`scripts/repo-init.sh`** — Initializes local git repo and creates the matching GitHub remote in one step
