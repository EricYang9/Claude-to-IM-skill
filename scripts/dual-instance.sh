#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DAEMON_SH="$SKILL_DIR/scripts/daemon.sh"
DOCTOR_SH="$SKILL_DIR/scripts/doctor.sh"

usage() {
  cat <<'EOF'
Usage:
  dual-instance.sh <codex|claude|both> <start|stop|status|logs|doctor> [N]

Examples:
  dual-instance.sh codex start
  dual-instance.sh claude status
  dual-instance.sh both status
  dual-instance.sh codex logs 100
  dual-instance.sh both doctor
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
    doctor)
      CTI_HOME="$home_dir" bash "$DOCTOR_SH"
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

run_both() {
  local action="$1"
  local extra="${2:-}"
  local rc=0

  set +e
  run_instance codex "$action" "$extra"
  local rc1=$?
  echo
  run_instance claude "$action" "$extra"
  local rc2=$?
  set -e

  if [[ "$rc1" -ne 0 || "$rc2" -ne 0 ]]; then
    rc=1
  fi
  return "$rc"
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
      start|stop|status|doctor)
        run_both "$ACTION"
        ;;
      logs)
        run_both logs "${EXTRA:-50}"
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
