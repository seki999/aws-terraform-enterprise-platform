# 部署指南

## 安全边界

本文提供命令，但不授权执行。所有 Plan 需要 AWS 只读/Plan 权限，所有 Apply 需要用户明确授权、人工审查和预算确认。优先使用 Sandbox 与短期 OIDC/AssumeRole，不使用长期 Access Key。

## 1. 本地静态检查

```bash
terraform version
terraform fmt -check -recursive
terraform -chdir=bootstrap/backend init -backend=false -input=false
terraform -chdir=bootstrap/backend validate
terraform -chdir=environments/dev init -backend=false -input=false
terraform -chdir=environments/dev validate
terraform test
python -m pytest
docker compose config
```

缺少 TFLint/Checkov/Trivy/ShellCheck/Markdownlint 时记录“未运行”，安装后补跑。

## 2. 准备 Sandbox

确认：

- 账号和 `ap-northeast-1` 被允许；
- Service Control Policy、Permission Boundary 和配额；
- Owner、CostCenter、Repository 标签；
- 月预算与告警；
- CloudTrail/Config/GuardDuty 是否组织级管理；
- 自定义域名和 Hosted Zone 是否在范围内。

用 `aws sts get-caller-identity` 检查账号会读取当前凭证；只在用户授权的 Sandbox 会话执行，不把输出写入公开日志。

## 3. Bootstrap Plan

```bash
cd bootstrap/backend
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

检查全局唯一 Bucket、KMS 管理权限、`prevent_destroy`、Public Access Block、Versioning 和 TLS Policy。获得明确授权后才能 `terraform apply tfplan`。

## 4. 配置远程 Backend

```bash
cd ../../environments/dev
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
```

把 Bootstrap Output 写入 `backend.hcl`，不要提交该文件：

```hcl
bucket       = "实际-state-bucket"
key          = "states/dev/terraform.tfstate"
region       = "ap-northeast-1"
encrypt      = true
kms_key_id   = "实际-KMS-ARN"
```

初始化：

```bash
terraform init -backend-config=backend.hcl -reconfigure
terraform validate
```

S3 Backend 的 `use_lockfile = true` 已在 `versions.tf` 设置。

## 5. 分层 Dev Plan

第一次建议所有高成本开关关闭，先确认基础资源：

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
```

推荐启用顺序：

1. 基础：VPC、子网、IGW、路由、SG/NACL、KMS、IAM、S3、DynamoDB、ECR、CloudWatch。
2. 私网访问：根据 NAT 与 Endpoint 成本选择一条可行出站路径。
3. Serverless：开启 API/Lambda/SQS/SNS/EventBridge/Step Functions。
4. 容器：先创建 ECR，构建并推送镜像，再开启 ALB/ECS。
5. 数据：开启 RDS，再按需 Redis。
6. 边缘：CloudFront/WAF；域名资源最后开启。
7. 治理：确认组织所有权后开启 Trail/Config/GuardDuty/Backup。
8. 云端 CI/CD：确认 GitHub 仓库后开启 CodeBuild/CodePipeline。

每一步都重新 Plan/审查，不使用 `-target` 作为日常分层方法。

## 6. 容器镜像

ECR Repository 不依赖 ECS Service。获取 Output 后：

```bash
aws ecr get-login-password --region ap-northeast-1 |
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.ap-northeast-1.amazonaws.com
docker build -t platform-api application/api
docker tag platform-api:latest ECR_REPOSITORY_URL:VERSION
docker push ECR_REPOSITORY_URL:VERSION
```

不要使用 `latest` 配合 Immutable Repository；把版本化 URI写入 `container_image` 后再启用 ECS。真实命令需要用户授权的 AWS 会话。

## 7. Apply 前审查

- 账号、Region、Workspace、Backend Key；
- Create/Update/Replace/Delete 数量；
- NAT、Endpoint、ALB、RDS、Redis、Fargate、治理服务成本；
- 公网入口与 SG；
- IAM 通配例外；
- 加密与日志；
- RDS Final Snapshot/Deletion Protection；
- 域名、证书区域和 DNS 变更；
- Service Quota；
- 回滚与负责人。

## 8. Apply 与 Smoke Test

明确授权后：

```bash
terraform apply tfplan
terraform output
bash ../../scripts/smoke-test.sh dev
terraform plan -var-file=terraform.tfvars
```

最后一个 Plan 应只包含可解释差异。Smoke Test 不能替代应用集成测试和安全测试。

## 9. staging 与 prod

复制的不是 State，而是代码与经过审查的环境差异。prod 使用独立 CI Environment、Role 和审批；启用 NAT 时每 AZ 一个，启用 RDS 时 Multi-AZ，日志保留和备份更长。生产前必须进行容量、故障、恢复和安全演练。

