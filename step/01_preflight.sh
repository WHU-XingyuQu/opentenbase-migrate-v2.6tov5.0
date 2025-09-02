#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

info "检查必需命令"
need psql; need pg_dump; need pg_restore

info "连接 v2.6($V26_HOST:$V26_PORT)"
psql26 -d postgres -c "select version();"

info "连接 v5.0($V50_HOST:$V50_PORT)"
psql50 -d postgres -c "select version();"

info "检查 v5.0 写入许可（若失败请先处理 license）"
license_writable_check || die "v5.0 处于只读，停止。"

info "检查 v5.0 目标库是否为空（用户表计数）"
USER_REL_CNT=$(psql50 -d postgres -Atc "select count(*)
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname not in ('pg_catalog','information_schema') and c.relkind in ('r','p');")
[[ "$USER_REL_CNT" -eq 0 ]] || die "v5.0 非空（用户表数=$USER_REL_CNT），请使用全新实例或清空后再试。"

info "预检完成 ✔"
