# Backend Bootstrap 模块

创建 KMS 加密、版本控制、公共访问阻止和 TLS-only Policy 的 S3 State Bucket。环境 Backend 使用 S3 原生 `.tflock`；DynamoDB 锁已弃用，不在新项目中默认创建。

## 安全执行

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform show tfplan
# 只有人工审查并明确授权后才可：terraform apply tfplan
```

Bucket 设置 `prevent_destroy = true` 和 `force_destroy = false`。迁移或删除前必须先备份 State、核对调用方并走人工流程。

