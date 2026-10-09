# shellcheck shell=bash
# Shared state and helpers for the grow-legion-root steps. Sourced, not run.
STATE_DIR=/root/grow-legion-root
STATE_FILE=$STATE_DIR/state.env

fail() { printf 'REFUSING: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null || fail "missing command: $1"; }
require_root() { [ "$(id -u)" = 0 ] || fail "run as root: sudo bash $0"; }

load_state() {
  [ -f "$STATE_FILE" ] || fail "no state at $STATE_FILE; run 01-preflight.sh first"
  # shellcheck source=/dev/null
  . "$STATE_FILE"
}
