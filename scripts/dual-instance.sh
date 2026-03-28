#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DAEMON_SH="$SKILL_DIR/scripts/daemon.sh"

usage() {
  cat <<'EOF'
Usage:
  dual-instance.sh <codex|claude|both> <start|stop|status|logs> [N]

Examples:
  dual-instance.sh codex start
  dual-instance.sh claude status
  dual-instance.sh both status
  dual-instance.sh codex logs 100
EOF
}

instance_home() {
  case "${1:-}" in
    codex) printf '%s/.claude-to-im-codex\n' "$HOME" ;;
    claude) printf '%s/.claude-to-im-claude\n' "$HOME" ;;
    *)
      echo "Unknown instance: $1" >&2
      exit 1
      ;;
  esac
}

run_instance() {
  local instance="$1"
  local action="$2"
  local extra="${3:-}"
  local home_dir
  home_dir="$(instance_home "$instance")"

  echo "== $instance =="
  echo "CTI_HOME=$home_dir"
  case "$action" in
    logs)
      CTI_HOME="$home_dir" bash "$DAEMON_SH" logs "${extra:-50}"
      ;;
    start|stop|status)
      CTI_HOME="$home_dir" bash "$DAEMON_SH" "$action"
      ;;
    *)
      echo "Unsupported action: $action" >&2
      exit 1
      ;;
  esac
}

INSTANCE="${1:-}"
ACTION="${2:-}"
EXTRA="${3:-}"

if [[ -z "$INSTANCE" || -z "$ACTION" ]]; then
  usage
  exit 1
fi

case "$INSTANCE" in
  codex|claude)
    run_instance "$INSTANCE" "$ACTION" "$EXTRA"
    ;;
  both)
    case "$ACTION" in
      start|stop|status)
        run_instance codex "$ACTION"
        echo
        run_instance claude "$ACTION"
        ;;
      logs)
        run_instance codex logs "${EXTRA:-50}"
        echo
        run_instance claude logs "${EXTRA:-50}"
        ;;
      *)
        echo "Unsupported action for both: $ACTION" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    usage
    exit 1
    ;;
esac
