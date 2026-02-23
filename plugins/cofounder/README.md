# Cofounder Plugin

A technical cofounder that helps you build and deploy web applications using Go, React, and Postgres — even if you have no programming experience.

## Installation

After adding the plugin to Claude Code, run the install command in your project:

```
/cofounder:install
```

This activates the cofounder agent as the main thread for your project. From that point on, every Claude Code session in the project will automatically start with the cofounder managing your environment, requirements, and development workflow.

The setting is saved in `.claude/settings.json`, which you can commit to git so all collaborators get the same experience (they need the cofounder plugin installed too).

## What it does

- Sets up your development environment automatically (Devbox, Podman, Git, GitHub)
- Helps you describe what you want to build and creates a product requirements document
- Builds your web app with a modern stack (Go backend, React frontend, Postgres database)
- Tests your app locally and helps you iterate on feedback
- Deploys to the cloud when you're ready

## Commands

| Command | Description |
|---------|-------------|
| `/cofounder:install` | Install the cofounder as the main thread for this project (recommended) |
| `/cofounder:run` | Run the cofounder agent once without installing (advanced) |
