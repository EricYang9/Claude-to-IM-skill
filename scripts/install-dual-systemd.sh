#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Please run as root." >&2
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UNIT_SRC="$SKILL_DIR/systemd/claude-to-im-instance@.service"
UNIT_DST="/etc/systemd/system/claude-to-im-instance@.service"

usage() {
  cat <<'EOF'
Usage:
  install-dual-systemd.sh install
  install-dual-systemd.sh status
  install-dual-systemd.sh restart
  install-dual-systemd.sh uninstall
EOF
}

ensure_unit() {
  install -m 0644 "$UNIT_SRC" "$UNIT_DST"
  systemctl daemon-reload
}

service_name() {
  printf 'claude-to-im-instance@%s.service\n' "$1"
}

start_enable_all() {
  systemctl enable --now "$(service_name codex)"
  systemctl enable --now "$(service_name claude)"
}

stop_disable_all() {
  systemctl disable --now "$(service_name codex)" || true
  systemctl disable --now "$(service_name claude)" || true
}

show_status() {
  systemctl --no-pager --full status "$(service_name codex)" "$(service_name claude)" || true
}

case "${1:-install}" in
  install)
    ensure_unit
    start_enable_all
    show_status
    ;;
  status)
    show_status
    ;;
  restart)
    ensure_unit
    systemctl restart "$(service_name codex)" "$(service_name claude)"
    show_status
    ;;
  uninstall)
    stop_disable_all
    rm -f "$UNIT_DST"
    systemctl daemon-reload
    ;;
  *)
    usage
    exit 1
    ;;
esac
