#!/usr/bin/env bash
set -Eeuo pipefail
# shellcheck source=../lib/common.sh
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

cat <<'TXT'
[切换指导]
方案 A（推荐）：修改应用连接串，将 CN 端口由 v2.6 的 OLD_PORT 改为 v5.0 的 NEW_PORT。
  - 修改配置 → 重启应用 → 验证写入仅落到 v5.0 → 观察一段时间再下线 v2.6。
方案 B（仅限本机实验）：启用 iptables 将 OLD_PORT 转发到 NEW_PORT（需 root）。
TXT

if [[ "$CUTOVER_USE_IPTABLES" == "true" ]]; then
  warn "将在本机设置：REDIRECT $CUTOVER_OLD_PORT → $CUTOVER_NEW_PORT（需 sudo）"
  sudo iptables -t nat -A OUTPUT -p tcp --dport "$CUTOVER_OLD_PORT" -j REDIRECT --to-ports "$CUTOVER_NEW_PORT"
  info "已添加转发规则。回滚方式："
  echo "  sudo iptables -t nat -D OUTPUT -p tcp --dport $CUTOVER_OLD_PORT -j REDIRECT --to-ports $CUTOVER_NEW_PORT"
else
  info "未启用本机端口转发。如需启用，请在 config.env 将 CUTOVER_USE_IPTABLES=true 并重跑此步。"
fi
