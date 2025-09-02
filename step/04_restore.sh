#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

[[ -f "$DUMP_DIR/DB_LIST.txt" ]] || die "未发现 $DUMP_DIR/DB_LIST.txt，请先执行 dump。"

info "加载全局对象 → v5.0"
psql50 -d postgres -f "$DUMP_DIR/00_globals.sql"

info "逐库创建并恢复（并行度 JOBS=$JOBS）"
while read -r db; do
  [[ -z "$db" ]] && continue
  ensure_db_exists_v5 "$db"
  info "restore $db"
  pg_restore -h "$V50_HOST" -p "$V50_PORT" -U "$V50_USER" -d "$db" -j "$JOBS" \
    --disable-triggers "$DUMP_DIR/db_${db}.dump" \
    |& tee -a "$LOG_DIR/restore_${db}.log"
done < "$DUMP_DIR/DB_LIST.txt"

info "全库 ANALYZE（可能耗时，耐心等待）"
psql50 -d postgres -c "VACUUM FREEZE;" || true
psql50 -d postgres -c "ANALYZE;"

info "恢复完成 ✔"
