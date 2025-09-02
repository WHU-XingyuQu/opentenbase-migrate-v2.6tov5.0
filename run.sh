#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/common.sh
source "$BASE_DIR/lib/common.sh"

usage() {
cat <<EOF
用法: ./run.sh <step1> [step2 ...]
可用步骤:
  preflight            预检（二进制/连通性/目标库为空/许可探测）
  fix-v5-conf          一次性移除 v5 不兼容 GUC（gtm_host/gtm_port/include_if_exists）
  register-nodes       确保 v5 的 pgxc_node 注册齐全（不使用 FORWARD SQL）
  quiesce-v26          (可选) 将 v2.6 置为只读并踢出连接
  dump                 导出 v2.6（全局+逐库 -Fc）
  restore              恢复到 v5.0（并行度 JOBS 可在 config.env 调整）
  check                轻量校验（对象计数 + 抽样表行数）
  cutover              切换指导（可选启用端口转发）
  unquiesce-or-stop-v26  解除 v2.6 只读或停掉 v2.6
示例:
  ./run.sh preflight dump restore check
  ./run.sh quiesce-v26 dump restore check cutover
EOF
}

[[ $# -ge 1 ]] || { usage; exit 1; }

for step in "$@"; do
  case "$step" in
    preflight)              bash "$BASE_DIR/steps/01_preflight.sh" ;;
    fix-v5-conf)            bash "$BASE_DIR/steps/10_fix_v5_conf.sh" ;;
    register-nodes)         bash "$BASE_DIR/steps/11_register_nodes_v5.sh" ;;
    quiesce-v26)            bash "$BASE_DIR/steps/02_quiesce_v26.sh" ;;
    dump)                   bash "$BASE_DIR/steps/03_dump.sh" ;;
    restore)                bash "$BASE_DIR/steps/04_restore.sh" ;;
    check)                  bash "$BASE_DIR/steps/05_check.sh" ;;
    cutover)                bash "$BASE_DIR/steps/06_cutover.sh" ;;
    unquiesce-or-stop-v26)  bash "$BASE_DIR/steps/07_unquiesce_or_stop_v26.sh" ;;
    *) err "未知步骤：$step"; usage; exit 1 ;;
  esac
done
