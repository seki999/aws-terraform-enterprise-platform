output "ecr_repository_url" {
  description = "API ECR Repository URL。"
  value       = aws_ecr_repository.api.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster 名称。"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS Service 名称；未启用时为 null。"
  value       = try(aws_ecs_service.api[0].name, null)
}

output "alb_arn_suffix" {
  description = "CloudWatch ALB 指标使用的 ARN suffix；未启用时为 null。"
  value       = try(aws_lb.api[0].arn_suffix, null)
}

output "target_group_arn_suffix" {
  description = "Target Group ARN suffix；未启用时为 null。"
  value       = try(aws_lb_target_group.api[0].arn_suffix, null)
}

output "alb_dns_name" {
  description = "ALB DNS 名称；未启用时为 null。"
  value       = try(aws_lb.api[0].dns_name, null)
}

output "autoscaling_group_name" {
  description = "EC2 Auto Scaling Group 名称；未启用时为 null。"
  value       = try(aws_autoscaling_group.worker[0].name, null)
}

