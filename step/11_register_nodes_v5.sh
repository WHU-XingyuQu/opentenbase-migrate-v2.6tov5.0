#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

# 读取现状
nodes=$(psql50 -d postgres -Atc "select node_name,node_type,node_port from pgxc_node order by 1;")
echo "$nodes"

has_cn=$(psql50 -d postgres -Atc "select 1 from pgxc_node where node_type='C' limit 1;")
has_dn=$(psql50 -d postgres -Atc "select 1 from pgxc_node where node_type='D' limit 1;")

# 仅在缺失时创建（不使用 FORWARD 子句）
if [[ -z "$has_cn" ]]; then
  info "创建 coordinator 节点元数据（不使用 FORWARD）"
  psql50 -d postgres -c "CREATE NODE cn001 WITH (TYPE='coordinator', HOST='$V50_HOST', PORT=$V50_PORT);"
fi

# DN 端口默认取 25432；如非默认，可由环境变量覆盖（V50_DN_PORT）
V50_DN_PORT="${V50_DN_PORT:-25432}"
if [[ -z "$has_dn" ]]; then
  info "创建 datanode 节点元数据（不使用 FORWARD）"
  psql50 -d postgres -c "CREATE NODE dn001 WITH (TYPE='datanode', HOST='$V50_HOST', PORT=$V50_DN_PORT, PRIMARY, PREFERRED);"
fi

info "刷新连接池"
psql50 -d postgres -c "SELECT pgxc_pool_reload();"

info "pgxc_node 现状："
psql50 -d postgres -c "select node_name,node_type,node_host,node_port from pgxc_node order by 1;"
