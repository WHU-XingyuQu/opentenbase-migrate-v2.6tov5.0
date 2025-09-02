#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

warn "将 v2.6 置为只读，踢出非本会话连接（建议在低峰时执行）"
psql26 -d postgres -c "ALTER SYSTEM SET default_transaction_read_only = on;"
psql26 -d postgres -c "SELECT pg_reload_conf();"
psql26 -d postgres -c "SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND usename <> current_user;"

info "当前只读状态："
psql26 -d postgres -c "SHOW default_transaction_read_only;"
