#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

fix_one() {
  local f="$1"
  [[ -f "$f" ]] || { warn "未找到 $f，跳过"; return; }
  info "清理不兼容 GUC：$f"
  sed -i -e "/^[[:space:]]*gtm_host[[:space:]]*=.*/d" \
         -e "/^[[:space:]]*gtm_port[[:space:]]*=.*/d" \
         -e "s|^include_if_exists *= *'/data/opentenbase/global/global_opentenbase.conf'||" \
         "$f"
}

fix_one "$V50_CN_DATA_DIR/postgresql.conf"
fix_one "$V50_DN1_DATA_DIR/postgresql.conf"

warn "请手动重启 v5.0（或使用你的 pgxc_ctl 环境），然后再执行 preflight。"
