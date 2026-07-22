# 安全设计

## IAM 最小权限

Role 按 ECS Execution、ECS Task、三个 Lambda、EC2、Flow Logs、RDS Monitoring、Step Functions、EventBridge、Config、Backup、CodeBuild、CodePipeline 和 GitHub OIDC 分离。Policy 使用项目名称和资源 ARN限制范围。

`ecr:GetAuthorizationToken` 以及 Step Functions 日志交付的部分 API 不支持资源级 ARN，只能使用 `Resource = "*"`；代码单独保留并在模块 README 解释，不能把这种例外扩散到其他权限。

IAM Role 提供短期凭证并由服务或 OIDC Assume；IAM User 通常依赖长期凭证。本项目不给 CI 或应用创建 IAM User。

## KMS

- Backend 使用独立 State KMS Key。
- 应用数据和日志使用不同 KMS Key，启用轮换。
- RDS、DynamoDB、Redis、上传 Bucket、SQS、SNS、Secrets 使用 KMS。
- 前端与兼容日志交付的 Bucket 使用 S3 管理密钥，避免不完整 Key Policy 阻断 CloudFront/日志服务。
- Key 管理主体必须在真实部署前由用户确认。

## Secrets Manager 与 Parameter Store

- 数据库密码和 Redis Token 由 Terraform 生成后写入 Secrets Manager。
- 非敏感日志级别写入 Parameter Store。
- ECS 通过 Execution Role 注入，不在镜像或普通环境变量文件保存密码。
- 因 Terraform 需要创建 Secret Version，密码仍存在于 State；`sensitive` 只隐藏 CLI 展示，不会从 State 移除。

## S3

所有 Bucket 启用 Public Access Block。前端 Bucket 只允许 CloudFront Service Principal，且用 Distribution SourceArn 限制。关键 Bucket版本化并加密；Bucket Policy 拒绝非 TLS 访问。

日志交付 Bucket 因服务兼容性使用 `BucketOwnerPreferred` 与日志 ACL；不授予公众 ACL。任何 ACL 相关扫描例外必须指向该交付要求。

## Security Group 与 NACL

SG 是有状态主体级控制；数据库和 Redis 仅接受 App SG。NACL 是无状态子网边界。二者变更需先画流量方向并考虑返回流量，避免把临时端口误当成漏洞直接关闭。

## WAF

CloudFront WAF 位于 us-east-1，默认使用 AWS Common Managed Rule。初次上线建议先用 Count 模式观察误报，再 Block。WAF 不替代应用鉴权、输入校验、API Gateway 限流和 DDoS 设计。

## CloudTrail、Config 与 GuardDuty

- CloudTrail：多区域、全局事件、日志完整性验证、加密/版本化审计 Bucket。
- Config：Recorder、Delivery Channel 和 S3 Public Read Prohibited 规则。
- GuardDuty：Detector 与 S3 Protection 示例。
- 如果 AWS Organizations 已集中管理，环境模块必须关闭对应开关，避免资源冲突。

## 日志保留与脱敏

dev 默认 7 天，staging 14 天，prod 90 天。应用采用 JSON 日志，只记录关联 ID、Job ID、路径和错误类型，不记录密码、Token、Authorization Header、Secret 内容或完整负载。调试日志和 `TF_LOG` 文件不得提交 Git。

## 密钥轮换

KMS 自动轮换开启。数据库/Redis凭证的应用无中断轮换需要运行手册、双凭证窗口或服务支持；本参考不把“创建 Secret”误称为完成自动轮换。

## Terraform State 安全

- S3 版本控制、KMS、TLS-only、Public Access Block。
- 每环境独立 Key 和 `.tflock`。
- 执行 Role 只可访问对应 State 前缀。
- 不输出 State、不上传到普通 Artifact、不使用 `state push -force`。
- 紧急操作前执行 `terraform state pull > backup.tfstate` 并将文件放入受控加密存储，完成后安全清理。

## CI/CD 凭证与 OIDC

GitHub Actions 通过 OIDC Assume Role；Trust Policy 限制 `aud=sts.amazonaws.com`、仓库和 Subject。不得把长期 Access Key 放入仓库、普通变量或不受控日志。PR Plan Artifact 只保留短期并限制仓库权限；Plan 可能含敏感结构，不能公开分享。

## 安全检查

```bash
terraform fmt -check -recursive
terraform validate
tflint --recursive
checkov -d .
trivy fs .
gitleaks detect
python -m pytest
```

扫描抑制必须在代码附近说明风险、替代控制、负责人和复审日期，不能为了“全绿”静默跳过。

