#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DUAL_SH="$SKILL_DIR/scripts/dual-instance.sh"

instance="${1:-}"
action="${2:-}"

if [[ -z "$instance" || -z "$action" ]]; then
  echo "Usage: systemd-instance.sh <codex|claude> <start|stop>" >&2
  exit 1
fi

is_running() {
  bash "$DUAL_SH" "$instance" status 2>/dev/null | grep -q '"running"[[:space:]]*:[[:space:]]*true'
}

case "$action" in
  start)
    if is_running; then
      echo "Instance $instance already running"
      exit 0
    fi
    exec bash "$DUAL_SH" "$instance" start
    ;;
  stop)
    if ! is_running; then
      echo "Instance $instance already stopped"
      exit 0
    fi
    exec bash "$DUAL_SH" "$instance" stop
    ;;
  *)
    echo "Unsupported action: $action" >&2
    exit 1
    ;;
esac
