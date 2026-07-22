# dev 环境

该目录是 dev 的独立 Terraform 根模块和独立 State。复制 `backend.hcl.example` 与 `terraform.tfvars.example` 后填入自己的非敏感配置。

```bash
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform show tfplan
```

示例 tfvars 关闭持续计费服务。启用 NAT、ALB、RDS、Redis、Interface Endpoint、治理或 CI/CD 前必须完成成本和安全审查。

