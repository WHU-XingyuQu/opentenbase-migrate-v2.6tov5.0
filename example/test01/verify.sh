#!/usr/bin/env bash
set -Eeuo pipefail
# 额外的“肉眼可读”校验：关键表行数、视图内容、节点元数据
# shellcheck source=../../config.env
source "$(cd "$(dirname "$0")/../.." && pwd)/config.env"

psql26(){ psql -h "$V26_HOST" -p "$V26_PORT" -U "$V26_USER" -v ON_ERROR_STOP=1 "$@"; }
psql50(){ psql -h "$V50_HOST" -p "$V50_PORT" -U "$V50_USER" -v ON_ERROR_STOP=1 "$@"; }

echo "== v2.6 计数 =="
psql26 -d migrate_demo -c "table s1.t_regular limit 5;"
psql26 -d migrate_demo -c "select count(*) as cnt_regular from s1.t_regular;"
psql26 -d migrate_demo -c "select count(*) as cnt_parted  from s1.t_parted;"

echo "== v5.0 计数 =="
psql50 -d migrate_demo -c "table s1.t_regular limit 5;"
psql50 -d migrate_demo -c "select count(*) as cnt_regular from s1.t_regular;"
psql50 -d migrate_demo -c "select count(*) as cnt_parted  from s1.t_parted;"

echo "== v5.0 视图检查 =="
psql50 -d migrate_demo -c "table s1.v_regular limit 5;"

echo "== v5.0 节点元数据 =="
psql50 -d postgres -c "select node_name,node_type,node_host,node_port from pgxc_node order by 1;"
