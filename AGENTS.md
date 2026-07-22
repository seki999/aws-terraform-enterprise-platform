# AGENTS.md

## 项目目标

本仓库是 AWS 与 Terraform 的企业平台学习项目。所有修改必须保持可部署、可审查、低成本默认值和真实验证记录。

## 目录结构

- `bootstrap/backend`：一次性创建远程 State 基础设施。
- `environments`：dev、staging、prod 独立根模块与 State。
- `modules`：可复用基础设施模块。
- `application`：FastAPI、Worker 与 Lambda。
- `docs`：架构、操作、安全、成本和学习文档。
- `scripts`、`tests`、`.github/workflows`：自动化与质量门。

## Terraform 规范

- Terraform Core 固定次版本范围；Provider 固定主版本范围并提交 Lockfile。
- 每个模块必须包含 main、variables、outputs、versions 和 README。
- 所有变量和输出必须有 description；敏感值必须标记 sensitive。
- 使用 locals 统一命名和标签；禁止硬编码账号 ID、密码、密钥和固定 ARN。
- 优先隐式依赖，只有跨资源副作用无法表达时才使用 depends_on。
- 只修改与当前任务直接相关的内容，不做无关重构。

## AWS 安全规范

- S3、RDS、Redis 不得公开；存储和日志默认加密。
- ECS、Lambda、EC2、CI/CD 和治理服务使用独立 IAM Role。
- 默认 IAM Policy 不得同时使用 `Action = "*"` 与 `Resource = "*"`。
- 密码使用 Secrets Manager，非敏感配置使用 Parameter Store。
- GitHub Actions 使用 OIDC，不使用长期 Access Key。
- State Bucket 启用版本控制、KMS、Public Access Block、TLS-only Policy 和锁。

## 禁止事项

- 未获用户明确授权，不执行真实 `terraform apply` 或 `terraform destroy`。
- 未获用户明确授权，不创建高成本资源。
- 不读取、打印或提交本机凭证、State、Plan、`.env` 或私钥。
- 不删除现有功能而不说明，不交付空模块、TODO 或关键伪代码。
- 不跳过校验，不伪造测试通过，不把未运行的检查写成成功。

## 测试命令

```bash
make fmt
make init
make validate
make lint
make security
make test
make docs
```

需要凭证或会修改云资源的命令与静态检查分离：

```bash
make plan ENV=dev
make apply ENV=dev CONFIRM=apply-dev
make destroy ENV=dev CONFIRM=destroy-dev
```

## 修改后的检查步骤

1. 运行 `terraform fmt -recursive`。
2. 对受影响根模块运行 `terraform init -backend=false` 和 `terraform validate`。
3. 运行 Terraform Test、应用单元测试和相关静态扫描。
4. 检查 `git diff`，确认没有 State、Plan、凭证或无关改动。
5. 更新与行为、变量、成本或安全边界相关的文档。
6. 在验证报告中区分成功、失败、工具缺失、凭证缺失和安全限制。

## 文档同步

新增或修改资源时同步模块 README、服务参考、架构/安全/成本文档、变量示例和验证报告。新增 AWS 服务还必须补充用途、依赖、Terraform Resource、开关、安全、成本、故障和验证方法。

