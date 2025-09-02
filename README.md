# opentenbase-migrate-v2.6tov5.0
This group of .sh files gives a method to migrate opentenbase from v2.6 to v5.0 without changing data.
Official file: https://docs.opentenbase.org/guide/01-quickstart/#_3

If you meet problems when compiling or installing OpenTenBase-v5.0, please visit https://github.com/WHU-XingyuQu/OpenTenBase-v5.0_compile-and-install.

OpenTenBase v2.6 → v5.0 （Ubuntu | single CN=1/DN=1）

- v2.6（端口示例：`50001/30004/40004`）与 v5.0（端口示例：`21010/55432/25432`）并行运行；
- 导出 v2.6 → 恢复至 v5.0 → 对比校验 → 平滑切换；
- 所有个性化参数集中在 [`config.env`](./config.env)，也可用环境变量覆盖。

## 快速开始

git clone <your-repo-url> opentenbase-migrate-26to50
cd opentenbase-migrate-26to50

一次性交互生成/修订配置（或者直接编辑 config.env）
$EDITOR config.env

先做预检与修复（可重复执行）
./run.sh preflight fix-v5-conf register-nodes

若追求强一致，建议短时间将 v2.6 置只读（可跳过）
./run.sh quiesce-v26

导出 v2.6（全局/各数据库）
./run.sh dump

恢复到 v5.0（支持并行；JOBS 在 config.env 可调）
./run.sh restore

轻量校验（对象计数 + 抽样行数）
./run.sh check

# 切换（手动/或启用本机端口转发）
./run.sh cutover

# 解除 v2.6 只读或停掉 v2.6
./run.sh unquiesce-or-stop-v26

