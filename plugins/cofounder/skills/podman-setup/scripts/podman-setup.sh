#!/usr/bin/env bash
set -euo pipefail

# podman-setup.sh — Ensure podman machine is initialized, started, and functional.
# Idempotent: safe to run on pre-existing installations.
# Assumes podman is on PATH (run via: mise exec podman@5 -- bash <this-script>)

PASS="PODMAN_SETUP_PASSED"
FAIL="PODMAN_SETUP_FAILED"

log()  { echo "[podman-setup] $*"; }
fail() { echo "$FAIL: $*" >&2; exit 1; }

# ---------- Step 1: Ensure a podman machine exists ----------

machine_exists() {
  # "podman machine ls" always succeeds; check if any machine is listed
  podman machine ls --format '{{.Name}}' 2>/dev/null | grep -q .
}

if machine_exists; then
  log "Podman machine already exists."
else
  log "No podman machine found. Initializing..."

  # Detect total physical memory (MB)
  case "$(uname -s)" in
    Darwin)
      mem_mb=$(( $(sysctl -n hw.memsize) / 1048576 ))
      ;;
    Linux)
      mem_mb=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
      ;;
    *)
      mem_mb=8192  # assume sufficient on unknown OS
      ;;
  esac

  if [ "$mem_mb" -lt 16384 ]; then
    log "System has ${mem_mb} MB RAM (< 16 GB). Setting VM memory to 1024 MB."
    podman machine init --memory 1024
  else
    log "System has ${mem_mb} MB RAM. Using default VM memory (2048 MB)."
    podman machine init
  fi

  if ! machine_exists; then
    fail "podman machine init succeeded but no machine found."
  fi
  log "Podman machine initialized."
fi

# ---------- Step 2: Ensure the machine is running ----------

machine_running() {
  # Use inspect to check the machine state reliably across podman versions
  local state
  state=$(podman machine inspect --format '{{.State}}' 2>/dev/null || true)
  [ "$state" = "running" ]
}

if machine_running; then
  log "Podman machine is already running."
else
  log "Starting podman machine..."
  podman machine start
  if ! machine_running; then
    fail "podman machine start completed but machine is not running."
  fi
  log "Podman machine started."
fi

# ---------- Step 3: Connectivity test with nginx ----------

TEST_CONTAINER="podman-setup-test-nginx"
TEST_PORT=18080

cleanup_test() {
  podman rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
}

# Clean up any leftover test container from a previous run
cleanup_test

log "Launching nginx test container on port ${TEST_PORT}..."
podman run -d --name "$TEST_CONTAINER" -p "${TEST_PORT}:80" docker.io/library/nginx:alpine >/dev/null

# Wait for nginx to become ready (retry up to 3 times)
log "Testing HTTP connectivity..."
http_code=""
for attempt in 1 2 3; do
  sleep 2
  http_code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${TEST_PORT}/" 2>/dev/null || true)
  [ "$http_code" = "200" ] && break
done

cleanup_test

if [ "$http_code" = "200" ]; then
  log "Connectivity test passed (HTTP ${http_code})."
else
  fail "Connectivity test failed (expected HTTP 200, got '${http_code}')."
fi

# ---------- Done ----------

log "All checks passed."
echo "$PASS"
exit 0
