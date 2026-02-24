#!/usr/bin/env bash
set -euo pipefail

# homebrew-install.sh — Ensure Homebrew is installed on macOS.
# Idempotent: skips if brew is already on PATH.

log()  { echo "[homebrew-install] $*"; }
fail() { echo "[homebrew-install] ERROR: $*" >&2; exit 1; }

if command -v brew &>/dev/null; then
  log "Homebrew already installed."
  echo "HOMEBREW_INSTALL_PASSED"
  exit 0
fi

log "Homebrew not found. Installing via .pkg..."
curl -L -o /tmp/Homebrew.pkg https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg
sudo installer -pkg /tmp/Homebrew.pkg -target /

# Set up PATH from common Homebrew locations
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"

if ! command -v brew &>/dev/null; then
  fail "Homebrew installation failed or is not on PATH."
fi

log "Homebrew installed successfully."
echo "HOMEBREW_INSTALL_PASSED"
exit 0
