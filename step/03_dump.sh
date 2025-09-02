#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

info "导出全局对象 → $DUMP_DIR/00_globals.sql"
pg_dumpall -h "$V26_HOST" -p "$V26_PORT" -U "$V26_USER" --globals-only > "$DUMP_DIR/00_globals.sql"

info "枚举数据库（排除 template0）"
DBS=$(psql26 -Atc "select datname from pg_database where datallowconn and datname not in ('template0');")
printf "%s\n" $DBS | sed '/^$/d' > "$DUMP_DIR/DB_LIST.txt"
info "数据库列表：$(tr '\n' ' ' < "$DUMP_DIR/DB_LIST.txt")"

info "逐库导出（-Fc，自包含归档；单会话保证一致性）"
while read -r db; do
  [[ -z "$db" ]] && continue
  info "dump $db"
  pg_dump -h "$V26_HOST" -p "$V26_PORT" -U "$V26_USER" -d "$db" -Fc > "$DUMP_DIR/db_${db}.dump"
done < "$DUMP_DIR/DB_LIST.txt"

info "导出完成 ✔ 目录：$DUMP_DIR"
