# Identity 模块

创建数据/日志 KMS Key、数据库与 Redis Secret、非敏感 Parameter Store 参数、ECS/Lambda/EC2 独立 Role，以及可选 GitHub OIDC Role。

ECR 的 `GetAuthorizationToken` 只能使用 `Resource = "*"`，这是 AWS API 的资源级授权限制；其他权限按项目前缀和资源类型限制。示例通过 Terraform 生成密码，因此敏感值仍会进入加密 State，State 访问必须严格控制。

GitHub OIDC 默认关闭。启用时必须把 Trust Policy 限制到真实 `owner/repository` 和 Subject；不要提交长期 Access Key。

