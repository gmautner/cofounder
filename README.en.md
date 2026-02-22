# Cofounder

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin that acts as your technical cofounder — guiding you from idea to deployed web app, even if you've never written a line of code.

[Clique aqui para a versao em Portugues](README.md)

## What it does

Cofounder is an AI-powered technical partner that helps you:

- **Describe your idea** in plain language and get a structured Product Requirements Document
- **Build a full-stack web app** (Go + React + PostgreSQL) with guided development
- **Test your app** with automated end-to-end testing via Playwright
- **Deploy to the cloud** on Locaweb Cloud with GitHub Actions CI/CD

It handles environment setup, dependency management, Git/GitHub workflows, database containers, and deployment — explaining everything in accessible language along the way.

## Requirements

- macOS or Linux (WSL2 supported on Windows)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and configured

## Installation

Add the marketplace and install the plugin:

```
/plugin marketplace add gmautner/marketplace
/plugin install cofounder
```

## Usage

Once installed, create a new project directory and start Claude Code:

```bash
mkdir my-app && cd my-app
claude
```

The cofounder agent activates automatically. It will:

1. Set up your development environment (devbox, podman, GitHub repo)
2. Ask what you want to build
3. Create a PRD, generate tasks, and start building
4. Guide you through testing and deployment

Just describe what you want in your own words — no technical knowledge required.

## Skills included

| Skill | Purpose |
|-------|---------|
| `pre-flight-check` | Validates environment prerequisites |
| `devbox-setup` | Isolated, reproducible dev environment via Nix |
| `podman-setup` | Container runtime for local databases |
| `repo-setup` | Git + GitHub repository initialization |
| `github-account` | Guides GitHub account creation |
| `tech-stack` | Full-stack app development (Go, React, PostgreSQL) |
| `frontend-design` | Distinctive UI/UX design guidance |
| `webapp-testing` | Playwright-based end-to-end testing |
| `locaweb-cloud-deploy` | Deploy to Locaweb Cloud infrastructure |

## Tech stack

Applications built with this plugin use:

- **Backend:** Go stdlib (`net/http`), `pgx/v5`, `sqlc`
- **Frontend:** Vite + React + TypeScript, shadcn/ui, Tailwind CSS
- **Database:** PostgreSQL (via Supabase Postgres image with extensions)
- **Deployment:** Single Docker container, GitHub Actions CI/CD

## License

Apache 2.0 — see [LICENSE](LICENSE).
