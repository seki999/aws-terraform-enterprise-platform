output "vpc_id" {
  description = "VPC ID。"
  value       = module.platform.vpc_id
}

output "frontend_url" {
  description = "前端 URL；未启用时为 null。"
  value       = module.platform.frontend_url
}

output "alb_dns_name" {
  description = "ALB DNS；未启用时为 null。"
  value       = module.platform.alb_dns_name
}

output "api_gateway_endpoint" {
  description = "API Gateway Endpoint；未启用时为 null。"
  value       = module.platform.api_gateway_endpoint
}

output "ecr_repository_url" {
  description = "ECR Repository URL。"
  value       = module.platform.ecr_repository_url
}

