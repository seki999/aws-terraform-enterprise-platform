output "data_kms_key_arn" {
  description = "应用数据 KMS Key ARN。"
  value       = aws_kms_key.data.arn
}

output "logs_kms_key_arn" {
  description = "日志 KMS Key ARN。"
  value       = aws_kms_key.logs.arn
}

output "database_secret_arn" {
  description = "数据库凭证 Secret ARN。"
  value       = aws_secretsmanager_secret.database.arn
}

output "database_password" {
  description = "生成的数据库密码，仅供 RDS 模块传递。"
  value       = random_password.database.result
  sensitive   = true
}

output "redis_secret_arn" {
  description = "Redis Token Secret ARN。"
  value       = aws_secretsmanager_secret.redis.arn
}

output "redis_auth_token" {
  description = "生成的 Redis Auth Token，仅供 ElastiCache 模块传递。"
  value       = random_password.redis.result
  sensitive   = true
}

output "log_level_parameter_arn" {
  description = "应用日志级别 Parameter ARN。"
  value       = aws_ssm_parameter.log_level.arn
}

output "runtime_role_arns" {
  description = "ECS、Lambda 和 EC2 运行 Role ARN。"
  value       = { for key, role in aws_iam_role.runtime : key => role.arn }
}

output "ec2_instance_profile_name" {
  description = "EC2 SSM Instance Profile 名称。"
  value       = aws_iam_instance_profile.ec2.name
}

output "github_plan_role_arn" {
  description = "GitHub Actions OIDC Plan Role ARN；未启用时为 null。"
  value       = try(aws_iam_role.github_plan[0].arn, null)
}

