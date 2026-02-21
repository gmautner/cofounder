#!/usr/bin/env bash
set -euo pipefail

# Ensure devbox is installed, then initialize the environment with the standard packages.
# Usage: bash devbox-init.sh [project-dir]
# If a second argument is provided, it is used as the path to devbox.json.template.

PROJECT_DIR="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${2:-$SCRIPT_DIR/devbox.json.template}"

# Check if devbox is installed
if ! command -v devbox &>/dev/null; then
  echo "devbox not found. Installing..."
  curl -fsSL https://get.jetify.com/devbox | bash
  # Refresh PATH
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v devbox &>/dev/null; then
    echo "ERROR: devbox installation failed or is not on PATH." >&2
    exit 1
  fi
  echo "devbox installed successfully: $(devbox version)"
else
  echo "devbox already installed: $(devbox version)"
fi

cd "$PROJECT_DIR"

# Set up devbox.json with the standard package template
if [ -f "$TEMPLATE" ]; then
  echo "Writing devbox.json from template ($TEMPLATE)..."
  cp "$TEMPLATE" devbox.json
  echo "devbox.json configured with standard packages."
else
  echo "WARNING: Template not found at $TEMPLATE. Falling back to devbox init." >&2
  devbox init
fi

echo "devbox environment ready in $PROJECT_DIR"
