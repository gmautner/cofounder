# Marketplace

A plugin marketplace for [Claude Code](https://code.claude.com/docs/en/overview).

[Clique aqui para a versão em Português](README.md)

## Requirements

### macOS

1. Open Terminal and run:

   ```
   xcode-select --install
   ```

   This installs Git and other required command-line tools.

2. Install Claude:
   - [Claude Code Desktop](https://code.claude.com/docs/en/desktop-quickstart) (recommended) — or
   - [Claude Code](https://code.claude.com/docs/en/overview) (command line)

### Windows

1. Install [Claude Code Desktop](https://code.claude.com/docs/en/desktop-quickstart) (recommended) or [Claude Code](https://code.claude.com/docs/en/overview) (command line).

2. Install Git: Claude Code Desktop will display a message with a link to install Git for Windows. Follow the link and accept all defaults (the famous Next/Next/.../Finish).

3. Enable WSL2 (Windows Subsystem for Linux):
   1. Open **PowerShell as Administrator**
   2. Run `wsl --install`
   3. Reboot the computer

   After rebooting, run `wsl --status` and verify it shows "Default Version: 2". A second `wsl --install` run may be needed in some cases.

## Installation

<!-- [TODO] Add Claude Code Desktop installation instructions -->

```
/plugin marketplace add gmautner/marketplace
```

## Available plugins

| Plugin | Description |
|--------|-------------|
| [cofounder](plugins/cofounder/) | An AI-powered co-founder that guides you from idea to deployed web app. See the [plugin documentation](plugins/cofounder/) for installation and usage instructions. |

## License

Apache 2.0 — see [LICENSE](LICENSE).
