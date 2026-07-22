# 灾难恢复

## 范围与目标

本实现是单区域、多 AZ 基线，不是多区域主动-主动。RTO/RPO 必须由业务定义并通过演练测量；不能仅凭“已开启备份”宣称达标。

## 数据保护

| 数据 | 机制 | 恢复路径 |
| --- | --- | --- |
| Terraform State | S3 Versioning、KMS、受控备份 | 恢复正确 Version，核对 lineage/serial |
| 前端/上传 S3 | Versioning、Lifecycle | 恢复对象版本或从复制/备份恢复 |
| RDS | Automated Backup、Final Snapshot、AWS Backup | PITR/快照恢复到新实例并切换配置 |
| DynamoDB | PITR、可选 Backup | 恢复为新 Table，验证 GSI/TTL/Stream |
| Redis | Snapshot | 恢复新 Replication Group；缓存可重建优先 |
| ECR | 镜像保留 | 从受信任 Registry/构建产物重推 |
| 配置与代码 | Git、Lockfile、CI Artifact | 从已签名/受审查 Commit 重建 |
| 审计日志 | Versioned Audit S3 | 只读调查，不覆盖原始证据 |

## 故障场景

### 单 AZ

ALB/ECS 跨 AZ；prod NAT 每 AZ；RDS/Redis Multi-AZ。验证 Task 重调度、连接重建、Queue 积压和告警。

### 主区域不可用

当前代码可用新 Region Provider/变量重建，但 Route 53 切换、数据跨区复制、证书、服务配额和镜像可用性没有自动实现。需要独立多区域方案和数据复制预算。

### 错误变更

停止 Apply、保存 State/日志、回滚代码后重新 Plan。对数据资源优先恢复到新对象并验证，不直接覆盖唯一副本。

### State 损坏

冻结所有写入，下载当前和历史 S3 Version，比较 lineage/serial，在隔离副本验证。只有双人复核后才考虑 `state push`；先备份远端。

### 凭证泄露

撤销 Session/Role 信任或密钥，审查 CloudTrail/GuardDuty，轮换受影响 Secret，检查 State/CI Artifact/日志，按事件响应流程留证。

## 恢复演练

每次演练记录：

- 故障时间线、负责人、批准；
- 目标与实际 RTO/RPO；
- 使用的 Backup/Snapshot/State Version；
- 完整命令和输出位置（不含敏感值）；
- 应用、数据完整性、安全和性能验证；
- DNS/客户端切换；
- 清理临时恢复资源；
- 差距、Owner 和截止日期。

## 恢复顺序

1. 身份、KMS、Backend 可访问。
2. 网络与 Endpoint。
3. 持久数据恢复到新资源。
4. Secret/Parameter 更新。
5. 消息和 Serverless。
6. ECR/Compute/ALB。
7. CloudFront/DNS。
8. 监控、审计、备份重新验证。
9. Smoke/集成/数据一致性检查。
10. 经批准切流并持续观察。

## 定期任务

- 每月检查 Backup Job、PITR、S3 Versioning 和 State Version；
- 每季度恢复非生产副本；
- 每半年 AZ 故障演练；
- 每年区域恢复桌面演练或按业务要求实际演练；
- Provider/Engine升级前后各做恢复验证。

