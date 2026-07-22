# Data 模块

创建可选 RDS PostgreSQL、始终启用的按需 DynamoDB Jobs Table，以及可选 ElastiCache Redis。

- RDS 与 Redis 仅位于 Private Database Subnet，RDS 明确 `publicly_accessible = false`。
- 三类数据都加密；RDS 自动备份、日志导出、Multi-AZ、Enhanced Monitoring、Performance Insights 和删除保护可配置。
- DynamoDB 使用 PAY_PER_REQUEST、PITR、TTL、SSE、GSI 与可选 Stream。
- Redis 强制静态/传输加密与 Auth Token，并支持 Multi-AZ/Automatic Failover。

RDS 与 Redis 持续计费，dev 默认关闭。密码来自 Identity 模块的 Secrets Manager，但因 Terraform 要把值交给服务，仍会存在于加密 State。

