output "vpc_id" {
  description = "VPC ID。"
  value       = module.networking.vpc_id
}

output "frontend_url" {
  description = "CloudFront 前端 URL；未启用时为 null。"
  value       = module.frontend.frontend_url
}

output "alb_dns_name" {
  description = "ALB DNS 名称；未启用时为 null。"
  value       = module.compute.alb_dns_name
}

output "api_gateway_endpoint" {
  description = "API Gateway Endpoint；未启用时为 null。"
  value       = module.serverless.api_endpoint
}

output "ecr_repository_url" {
  description = "API ECR Repository URL。"
  value       = module.compute.ecr_repository_url
}

output "dynamodb_table_name" {
  description = "DynamoDB Jobs Table 名称。"
  value       = module.data.dynamodb_table_name
}

output "alarm_topic_arn" {
  description = "CloudWatch Alarm Topic ARN。"
  value       = module.operations.alarm_topic_arn
}

output "github_plan_role_arn" {
  description = "GitHub OIDC Plan Role ARN；未启用时为 null。"
  value       = module.identity.github_plan_role_arn
}

