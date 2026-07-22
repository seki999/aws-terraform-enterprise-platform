# Checkov 例外登记

本文件登记 `.tf` 资源内的精确 `#checkov:skip`。例外不是全局关闭：每条都绑定检查编号与资源，并在代码旁保留原因。新增、扩大或长期保留例外时，必须经过安全与成本审查。

## 本次直接修复

- S3 生命周期统一在 7 天后中止未完成的 multipart upload；访问日志 Bucket 启用版本控制，上传 Bucket 启用访问日志，审计 Bucket 增加 7 年生命周期。
- ECR、前端 S3、SSM SecureString、VPC Flow Logs、Lambda/API Gateway/Step Functions 日志使用客户管理 KMS Key；KMS Key 明确定义 Key Policy。
- 应用 Security Group 移除全协议公网出站，只保留 HTTPS、VPC Resolver DNS、PostgreSQL 与 Redis 的定向规则；默认 Security Group 由 Terraform 接管并保持无规则。
- RDS PostgreSQL 设置 `rds.force_ssl=1`；CloudFront 使用 AWS 托管安全响应头策略；WAF 增加 Known Bad Inputs 托管规则组。
- Lambda 设置并发上限与 X-Ray Active Tracing，Step Functions 启用 X-Ray Tracing。

## 已批准例外

| 检查 | 资源范围 | 当前理由 | 生产升级动作 |
| --- | --- | --- | --- |
| `CKV_AWS_109`、`CKV_AWS_111`、`CKV_AWS_356` | Backend、Data、Logs KMS Key Policy | `Resource="*"` 只用于挂载到 Key 自身的标准 KMS 根账号 IAM 委派；Logs 语句另有 Service Principal 与 Encryption Context 限制 | 保留根委派，按组织角色进一步拆分管理与使用权限 |
| `CKV_AWS_18` | State、Artifact、Audit Bucket | State/Artifact 模块没有独立日志目标；Audit 本身是日志汇聚点，不能递归记录到自己 | 写入独立日志账号的集中 Bucket |
| `CKV_AWS_144` | State、Artifact、Frontend、Uploads、Logs、Audit Bucket | 当前是单区域实验平台，跨区域复制需要第二 Region、Key 与明确数据驻留治理 | 建立 DR 账号/Region、复制 Key、复制角色与恢复演练 |
| `CKV_AWS_145` | Access Logs、Audit Bucket | 日志投递兼容性优先使用 SSE-S3；业务与上传 Bucket 已使用 KMS | 建立 CloudTrail/Config/日志服务专用 KMS Policy 后迁移 |
| `CKV2_AWS_62` | 全部 S3 Bucket | 这些 Bucket 没有真实的事件驱动消费者；添加空通知会制造无效资源 | 只有出现明确消费者时才添加精确事件过滤与目标 |
| `CKV2_AWS_65` | Access Logs Ownership Controls | `BucketOwnerPreferred` 与 `log-delivery-write` ACL 配套使用 | 日志源全部支持无 ACL 投递后迁移到 BucketOwnerEnforced |
| `CKV_AWS_150` | ALB | dev/staging 需要可销毁；当前模块没有环境级删除保护输入 | 生产入口启用删除保护并加入变更审批 |
| `CKV_AWS_2`、`CKV_AWS_103`、`CKV2_AWS_20` | ALB Listener/ALB | 可选实验 ALB 当前为 HTTP，默认关闭 | 配置主 Region ACM、TLS 1.2+ HTTPS Listener 与 HTTP-to-HTTPS Redirect |
| `CKV2_AWS_28` | ALB | Regional WAF 会持续计费；CloudFront 启用时已有边缘 WAF | 互联网生产 API 关联 Regional WAF 并配置日志 |
| `CKV_AWS_378` | ALB Target Group | TLS 在 ALB 终止；后端 HTTP 仅在私有子网且由 SG 限制 | 有端到端加密要求时为任务引入证书与 HTTPS Target Group |
| `CKV_AWS_161` | RDS | prod 已通过环境逻辑启用 Multi-AZ，非生产保持 Single-AZ 控制成本 | 保持生产 Multi-AZ，部署前核对实际变量 |
| `CKV2_AWS_31` | CloudFront WAF | WAF 日志需要 Firehose 与独立保留目标，实验默认关闭 WAF | 生产启用 Firehose、加密日志 Bucket、保留期与告警 |
| `CKV2_AWS_47` | CloudFront Distribution | 已关联含 Known Bad Inputs 的 WAF；Checkov 无法解析 `count` 与跨 Provider 关联 | 保持规则更新，并在 AWS Plan 中复核实际关联 |
| `CKV2_AWS_57` | Database/Redis Secret | 自动轮换需要应用专用 Lambda、双凭证/双 Token 切换流程，不能只创建空轮换声明 | 完成轮换函数、Runbook、回滚与集成测试后启用 |
| `CKV2_AWS_1` | Private DB NACL | `subnet_ids` 已直接关联私有 DB Subnet，属于图解析误判 | 在 Plan 中核对 Association，不添加重复资源 |
| `CKV_AWS_352` | Private DB NACL ingress | 全协议规则只允许 VPC CIDR；真正端口边界由 Database/Redis SG 执行 | 若组织要求双层端口控制，拆分数据库、Redis 与临时端口规则 |
| `CKV_AWS_260` | ALB Security Group | 公网 80 与当前实验 HTTP Listener 对应 | 完成 HTTPS 后仅把 80 用于 Redirect，或完全关闭 80 |
| `CKV2_AWS_5` | ALB、App、Database、Redis SG | SG 通过 Platform 的跨模块变量连接到 ALB/ECS/RDS/ElastiCache，Checkov 未解析该边 | 在 Terraform Plan 与 AWS Config 中核对实际附加关系 |
| `CKV_AWS_338` | Flow、Lambda、API、States Log Group | 保留期由环境变量控制，非生产短保留控制日志费用 | 生产设置 365 天或转储到合规归档 Bucket |
| `CKV_AWS_35`、`CKV_AWS_252`、`CKV2_AWS_10` | CloudTrail | 实验版写入版本化 S3；告警由现有 SNS/CloudWatch 模块处理，未接 SIEM | 使用服务感知 KMS Policy、CloudWatch Logs Role、直接 SNS/SIEM 集成 |
| `CKV2_AWS_3` | GuardDuty | 仓库只负责单账号；组织级委派管理员应由 Security Account 管理 | 在 AWS Organizations 中启用 Delegated Administrator 与成员自动注册 |
| `CKV_AWS_116` | 三个 Lambda | Validator/Worker 为同步调用；Consumer 使用 SQS Redrive/DLQ，Lambda 自身异步 DLQ 不适用 | 若改为异步 Invoke，再配置 Lambda Destination/DLQ |
| `CKV_AWS_117` | 三个 Lambda | 函数只访问 AWS 托管 API，不需要 VPC 资源；放入 VPC 会引入 NAT/Endpoint 成本 | 需要私有 RDS/Redis 访问时加入 Private Subnet、SG 与 Endpoint |
| `CKV_AWS_272` | 三个 Lambda | Code Signing 依赖组织 Signer Profile 与签名发布流水线 | 生产供应链建立签名、验证与制品准入流程 |
| `CKV_AWS_285` | Step Functions | 已记录 `ERROR`，并故意关闭执行 Payload 记录以避免敏感数据进入日志 | 按数据分类决定是否使用 `ALL`，配套日志脱敏与访问控制 |
| `CKV_AWS_309` | API Gateway Route | 实验 Job Route 有意无鉴权 | 生产附加 JWT Authorizer 或 IAM Authorization，并增加拒绝测试 |
| `CKV_GHA_7` | Terraform Plan GitHub Actions | 手动输入是固定的 `dev/staging/prod` choice，且在进入任何路径或命令前再次通过 shell allowlist 校验 | 若环境扩展，必须同时更新 choice、allowlist、GitHub Environment 与最小权限 Plan Role |

## 审查规则

1. CI 必须继续以失败模式运行 Checkov；不得添加 `soft_fail` 或仓库级 `skip-check`。
2. 例外必须写在目标资源内，包含检查编号和一句可审计理由。
3. 生产部署前逐条核对本表的升级动作；任何已完成项目应删除对应 `skip` 并让 Checkov 直接通过。
4. 静态扫描通过不等于 AWS 部署验证；仍需审查真实 `terraform plan`，且 Apply 必须人工批准。
