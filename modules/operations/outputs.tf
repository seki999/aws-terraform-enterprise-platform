output "alarm_topic_arn" {
  description = "CloudWatch Alarm SNS Topic ARN。"
  value       = aws_sns_topic.alarms.arn
}

output "dashboard_name" {
  description = "CloudWatch Dashboard 名称；未启用时为 null。"
  value       = try(aws_cloudwatch_dashboard.platform[0].dashboard_name, null)
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN；未启用时为 null。"
  value       = try(aws_cloudtrail.this[0].arn, null)
}

output "audit_bucket_arn" {
  description = "CloudTrail/Config 审计 Bucket ARN；未启用时为 null。"
  value       = try(aws_s3_bucket.audit[0].arn, null)
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID；未启用时为 null。"
  value       = try(aws_guardduty_detector.this[0].id, null)
}

output "backup_vault_name" {
  description = "AWS Backup Vault 名称；未启用时为 null。"
  value       = try(aws_backup_vault.this[0].name, null)
}

