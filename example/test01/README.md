运行目标：
1. 在 **v2.6** 上创建一个示例库 `migrate_demo` 并写入数据；
2. 仅迁移 `migrate_demo` 到 **v5.0**（通过 DB 白名单，不影响你的其他库）；
3. 自动做对象数量 + 样本行数比对，确认迁移可用。


## 快速跑

```bash
# 1) 在 v2.6 上种数据
psql -h "$V26_HOST" -p "$V26_PORT" -U "$V26_USER" -v ON_ERROR_STOP=1 -f examples/smoke-test/01_seed_v26.sql

# 2) 运行示例
examples/smoke-test/02_run_example.sh

# 3) 额外校验（可重复运行）
examples/smoke-test/03_verify.sh
