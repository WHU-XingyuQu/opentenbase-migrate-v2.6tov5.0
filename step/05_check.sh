#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

[[ -f "$DUMP_DIR/DB_LIST.txt" ]] || die "未发现 $DUMP_DIR/DB_LIST.txt，请先执行 dump。"

FAIL=0
while read -r db; do
  [[ -z "$db" ]] && continue
  info "== 校验库：$db =="

  QCOUNT="select
    sum((relkind in ('r','p'))::int) as tables,
    sum((relkind='i')::int) as indexes,
    sum((relkind='S')::int) as sequences,
    sum((relkind in ('v','m'))::int) as views
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname not in ('pg_catalog','information_schema');"

  C26=$(psql26 -d "$db" -Atc "$QCOUNT")
  C50=$(psql50 -d "$db" -Atc "$QCOUNT")
  echo "  v2.6: $C26"
  echo "  v5.0: $C50"
  [[ "$C26" == "$C50" ]] || { warn "对象数量不一致"; FAIL=1; }

  QTABLES="select quote_ident(n.nspname)||'.'||quote_ident(c.relname)
           from pg_class c join pg_namespace n on n.oid=c.relnamespace
           where c.relkind in ('r','p') and n.nspname not in ('pg_catalog','information_schema')
           order by greatest(c.reltuples,0) desc nulls last limit $SAMPLE_TABLES;"
  TABLES=$(psql26 -d "$db" -Atc "$QTABLES")

  while read -r tbl; do
    [[ -z "$tbl" ]] && continue
    CNT26=$(psql26 -d "$db" -Atc "select count(*) from $tbl;") || CNT26="ERR"
    CNT50=$(psql50 -d "$db" -Atc "select count(*) from $tbl;") || CNT50="ERR"
    echo "  [$tbl] v2.6=$CNT26 | v5.0=$CNT50"
    [[ "$CNT26" == "$CNT50" ]] || { warn "  行数不一致：$tbl"; FAIL=1; }
  done <<< "$TABLES"

done < "$DUMP_DIR/DB_LIST.txt"

[[ $FAIL -eq 0 ]] && info "校验通过 ✔" || die "存在不一致，请检查日志。"
