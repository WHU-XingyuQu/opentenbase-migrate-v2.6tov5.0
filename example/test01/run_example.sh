#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# 加载总配置 & 示例覆盖
# shellcheck source=../../config.env
source "$BASE_DIR/config.env"
# shellcheck source=../smoke-test/config.override.env
source "$BASE_DIR/examples/smoke-test/config.override.env"

echo "仅迁移数据库白名单：$DB_WHITELIST"
echo "预检 + 修复 + 节点注册"
"$BASE_DIR/run.sh" preflight fix-v5-conf register-nodes

echo "导出（仅白名单 DB）"
"$BASE_DIR/run.sh" dump

echo "恢复 → v5.0"
"$BASE_DIR/run.sh" restore

echo "轻量校验"
"$BASE_DIR/run.sh" check

echo "示例完成：如需进一步手动验证，执行 examples/smoke-test/03_verify.sh"
