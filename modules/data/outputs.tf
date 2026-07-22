output "rds_endpoint" {
  description = "RDS PostgreSQL Endpoint；未启用时为 null。"
  value       = try(aws_db_instance.postgres[0].address, null)
}

output "rds_identifier" {
  description = "RDS DB Identifier；未启用时为 null。"
  value       = try(aws_db_instance.postgres[0].identifier, null)
}

output "rds_arn" {
  description = "RDS DB ARN；未启用时为 null。"
  value       = try(aws_db_instance.postgres[0].arn, null)
}

output "dynamodb_table_name" {
  description = "Jobs DynamoDB Table 名称。"
  value       = aws_dynamodb_table.jobs.name
}

output "dynamodb_table_arn" {
  description = "Jobs DynamoDB Table ARN。"
  value       = aws_dynamodb_table.jobs.arn
}

output "dynamodb_stream_arn" {
  description = "DynamoDB Stream ARN；未启用时为 null。"
  value       = aws_dynamodb_table.jobs.stream_arn
}

output "redis_primary_endpoint" {
  description = "Redis Primary Endpoint；未启用时为 null。"
  value       = try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null)
}

output "redis_replication_group_id" {
  description = "Redis Replication Group ID；未启用时为 null。"
  value       = try(aws_elasticache_replication_group.redis[0].id, null)
}
