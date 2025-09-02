#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

warn "解除 v2.6 只读（若之前执行过 quiesce）"
psql26 -d postgres -c "ALTER SYSTEM SET default_transaction_read_only = off;" || true
psql26 -d postgres -c "SELECT pg_reload_conf();" || true
psql26 -d postgres -c "SHOW default_transaction_read_only;" || true

info "如需下线 v2.6，请使用你 v2.6 的 pgxc_ctl 环境执行 stop all。"
