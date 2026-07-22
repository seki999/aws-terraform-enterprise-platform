output "state_bucket_name" {
  description = "远程 Terraform State 的 S3 Bucket 名称。"
  value       = aws_s3_bucket.state.id
}

output "state_kms_key_arn" {
  description = "加密 Terraform State 的 KMS Key ARN。"
  value       = aws_kms_key.state.arn
}

output "state_access_policy_json" {
  description = "可附加到 Terraform 执行 Role 的最小 State 访问 Policy JSON。"
  value       = data.aws_iam_policy_document.state_access.json
  sensitive   = true
}

output "backend_config_example" {
  description = "环境 Backend 部分配置示例；use_lockfile 在环境 backend.tf 中设置。"
  value = {
    bucket     = aws_s3_bucket.state.id
    region     = var.aws_region
    kms_key_id = aws_kms_key.state.arn
    encrypt    = true
  }
}

