# 故障排查

## `terraform init` 找不到 Backend

症状：Bucket 不存在、403、KMS AccessDenied。  
检查：账号/Region、Backend Bucket、Key、KMS ARN、AssumeRole、S3 List/Get/Put 和 Lockfile Get/Put/Delete。  
处理：先修正 `backend.hcl`，必要时 `init -reconfigure`；不要指向新空 Key 后直接 Apply。

## State Lock

症状：Error acquiring the state lock。  
检查：是否有 CI/人工操作仍运行，读取 Lock ID。  
处理：等待正常释放。只有确认持有者已终止时才 `terraform force-unlock LOCK_ID`；错误解锁可能产生多个写入者。

## Provider 下载失败

检查代理、TLS Inspection、Registry、Lockfile 平台 Hash。离线环境用 `providers mirror`。不要删除 Lockfile来“修复”供应链校验。

## Module not installed

运行目标根模块的 `terraform init -backend=false`。确认本地 `source` 相对路径以调用模块文件为基准。

## Invalid Provider Configuration

CloudFront ACM/WAF 需要 `aws.us_east_1` Alias。环境根和 Platform/Frontend 模块必须逐层传递 Alias。

## CloudFront/ACM 一直等待

证书必须在 us-east-1，Hosted Zone ID 必须属于域名，DNS Validation Record 需要传播。无域名时保持 `domain_name = null`，使用 CloudFront 默认域名。

## S3 AccessDenied

检查 Public Access Block、OAC Bucket Policy SourceArn、ALB Log Delivery Principal、KMS Key Policy 与对象所有权。不要通过公开 Bucket 临时绕过。

## ECS 无法启动

- 镜像 URI/Tag 不存在或 Repository Immutable 冲突；
- Task Execution Role 缺 ECR/Logs/Secret/SSM 权限；
- 无 NAT 时缺 ECR API/DKR、S3、Logs、Secrets Endpoint；
- App SG、Subnet 或 Target Group 端口不一致；
- 容器 Health Check/ALB Health Check 失败；
- Secret JSON 被整体注入但应用期望 URL。

查看 ECS Service Event、Stopped Reason 和 CloudWatch Logs，不打印 Secret。

## ALB Access Logs 失败

日志 Bucket 必须在同区域，Policy 允许 Log Delivery Service 写入正确 `AWSLogs/account-id` Prefix，S3/KMS/Ownership配置兼容。ALB 启用前先确认 Bucket Policy。

## Lambda ImportModuleError

确认 Zip 根目录包含 `handler.py`，Layer 内为 `python/common_logging.py`，Runtime 为 Python 3.13。修改源码后重新 Plan 以刷新 Archive Hash。

## SQS 重复或 DLQ 增长

SQS 是至少一次交付。检查 Visibility Timeout 大于处理时间、部分批处理失败返回值、Consumer/Step Functions Retry 和幂等条件写。DLQ 告警后先保存证据，再 Redrive。

## Step Functions AccessDenied

检查 State Machine Role 对 Worker Lambda 与 SNS 的精确 ARN权限，以及 CloudWatch Log Delivery API。Consumer Lambda Role 还需 `states:StartExecution`。

## RDS 创建失败

检查 Subnet Group 覆盖 AZ、Instance Class/Engine 可用性、KMS、参数族、配额。增强监控需要专用 Role。Final Snapshot、Deletion Protection 会影响销毁。

## Redis 创建失败

Auth Token 需要 Transit Encryption，Subnet Group 至少跨需要的 AZ；Multi-AZ/Automatic Failover 需要多个节点。检查所选 Node Type 在 Region 可用。

## Config/GuardDuty AlreadyExists

账号可能由 Organizations 管理。不要 Import/接管未知组织资源；关闭开关并与安全团队确认所有权。

## Plan 显示全部新建

立即停止。通常是错误 Backend Key、Workspace、账号或 `init -reconfigure`。对比 `state list`、Backend 配置和受控备份，不要 Apply。

## Drift

先运行完整 Plan。判断远端变更应被代码覆盖、接受为 Refresh-only，还是通过 Import/State迁移纳管。不要用 Target 隐藏差异。

## Docker

`docker compose config` 只验证配置；Docker Engine 未运行时 `docker build`/Compose 不算通过。Windows 确认 Docker Desktop Linux Engine 已启动。

## 调试日志

只在受控终端短时设置 `TF_LOG=DEBUG/TRACE`，日志可能含凭证、State 和请求。解决后清除环境变量并安全删除日志。

