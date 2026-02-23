#!/usr/bin/env bash
set -euo pipefail

# mise-init.sh — Install mise, pre-install managed tools, and install GH CLI.
# Mac and Linux only. Windows uses winget (see SKILL.md).

log()  { echo "[mise-init] $*"; }
fail() { echo "[mise-init] ERROR: $*" >&2; exit 1; }

OS=$(uname -s)
log "Detected OS: $OS"

# ---------- Step 1: Ensure Homebrew (macOS only) ----------

if [ "$OS" = "Darwin" ]; then
  if command -v brew &>/dev/null; then
    log "Homebrew already installed."
  else
    log "Homebrew not found. Installing via .pkg..."
    curl -L -o /tmp/Homebrew.pkg https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg
    sudo installer -pkg /tmp/Homebrew.pkg -target /
    if ! command -v brew &>/dev/null; then
      # Try common Homebrew paths
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"
    fi
    if ! command -v brew &>/dev/null; then
      fail "Homebrew installation failed or is not on PATH."
    fi
    log "Homebrew installed successfully."
  fi
fi

# ---------- Step 2: Install mise ----------

if command -v mise &>/dev/null; then
  log "mise already installed: $(mise --version)"
else
  case "$OS" in
    Darwin)
      log "Installing mise via Homebrew..."
      brew install mise
      ;;
    Linux)
      log "Installing mise via official installer..."
      curl https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
      ;;
    *)
      fail "Unsupported OS '$OS'. Use winget on Windows."
      ;;
  esac

  if ! command -v mise &>/dev/null; then
    fail "mise installation failed or is not on PATH."
  fi
  log "mise installed: $(mise --version)"
fi

# ---------- Step 3: Pre-install managed tools ----------

log "Pre-installing managed tools (auto-installs on first use)..."

mise exec go@1 -- go version
log "  go: OK"

mise exec sqlc@1 -- sqlc version
log "  sqlc: OK"

mise exec python@3.14 -- python --version
log "  python: OK"

mise exec node@24 -- node --version
log "  node: OK"

mise exec jq@1 -- jq --version
log "  jq: OK"

mise exec podman@5 -- podman --version
log "  podman: OK"

# ---------- Step 4: Install GH CLI ----------

if command -v gh &>/dev/null; then
  log "GH CLI already installed: $(gh --version | head -1)"
else
  case "$OS" in
    Darwin)
      log "Installing GH CLI via Homebrew..."
      brew install gh
      ;;
    Linux)
      log "Installing GH CLI from precompiled binary..."
      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64)       GH_ARCH="amd64" ;;
        aarch64|arm64) GH_ARCH="arm64" ;;
        *)            fail "Unsupported architecture: $ARCH" ;;
      esac
      GH_VERSION=$(curl -sL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
      if [ -z "$GH_VERSION" ]; then
        fail "Could not determine latest GH CLI version."
      fi
      curl -sL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" | tar xz -C /tmp
      mkdir -p "$HOME/.local/bin"
      install -m 755 "/tmp/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" "$HOME/.local/bin/gh"
      log "GH CLI installed to ~/.local/bin/gh"
      ;;
  esac

  if ! command -v gh &>/dev/null; then
    fail "GH CLI installation failed or is not on PATH."
  fi
  log "GH CLI installed: $(gh --version | head -1)"
fi

# ---------- Done ----------

log "All tools installed and verified."
echo "MISE_SETUP_PASSED"
exit 0
