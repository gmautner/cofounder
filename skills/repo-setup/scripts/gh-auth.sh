#!/usr/bin/env bash
set -euo pipefail

# Authenticate with GitHub using the device code flow.
#
# Usage: bash gh-auth.sh [scopes]
# Example: bash gh-auth.sh "repo,read:org,workflow"

SCOPES="${1:-repo,read:org,workflow}"

# Check if already authenticated
if gh auth status &>/dev/null; then
  echo "Already authenticated with GitHub."
  exit 0
fi

# Omitting --web forces the device code flow, which prints the
# one-time code (XXXX-XXXX) and the URL https://github.com/login/device.
# The command blocks until the user completes authorization in the browser.
gh auth login \
  --hostname github.com \
  --git-protocol https \
  --scopes "$SCOPES"
