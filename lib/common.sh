#!/usr/bin/env bash
set -Eeuo pipefail

# 加载用户配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../config.env
source "$SCRIPT_DIR/config.env"

export PATH="$V50_BIN:$V26_BIN:$PATH"

color() { local c="$1"; shift; printf "\033[%sm%s\033[0m\n" "$c" "$*"; }
info()  { color "1;34" "[INFO] $*"; }
warn()  { color "1;33" "[WARN] $*"; }
err()   { color "1;31" "[ERR ] $*"; }

need() { command -v "$1" >/dev/null || { err "缺少命令：$1"; exit 1; }; }
psql26(){ PGPASSWORD="${PGPASSWORD:-}" psql -h "$V26_HOST" -p "$V26_PORT" -U "$V26_USER" -v ON_ERROR_STOP=1 "$@"; }
psql50(){ PGPASSWORD="${PGPASSWORD:-}" psql -h "$V50_HOST" -p "$V50_PORT" -U "$V50_USER" -v ON_ERROR_STOP=1 "$@"; }

die() { err "$*"; exit 1; }

logwrap() {
  # 用法：logwrap CMD...    → 将 stdout+stderr 同时 tee 到日志目录
  local base="$1"; shift || true
  local log="$LOG_DIR/${base}_$STAMP.log"
  "$@" 2>&1 | tee "$log"
}

ensure_db_exists_v5() {
  local db="$1"
  local exists
  exists=$(psql50 -Atc "select 1 from pg_database where datname='$db'")
  if [[ -z "$exists" ]]; then
    info "创建 v5.0 数据库 $db"
    psql50 -d postgres -c "CREATE DATABASE \"$db\""
  fi
}

license_writable_check() {
  # 尝试最小写入，判断 v5 是否只读；出现错误即视为只读
  info "检查 v5.0 写入许可（最小写入探测）"
  set +e
  psql50 -d postgres -c "create temp table if not exists _wtest(x int); insert into _wtest values (1);" >/dev/null 2>&1
  local rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    warn "检测到 v5.0 可能处于只读（license 未激活或权限不足）。"
    warn "请先完成 license 激活后再继续迁移（见发行包文档/pg_license 工具）。"
    return 1
  fi
  info "v5.0 可写 ✔"
  return 0
}
