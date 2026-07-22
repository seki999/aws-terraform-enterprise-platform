output "vpc_id" {
  description = "VPC ID。"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC IPv4 CIDR。"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public Subnet IDs。"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private Application Subnet IDs。"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private Database Subnet IDs。"
  value       = aws_subnet.private_db[*].id
}

output "private_app_route_table_ids" {
  description = "Private Application Route Table IDs。"
  value       = aws_route_table.private_app[*].id
}

output "nat_gateway_ids" {
  description = "启用时创建的 NAT Gateway IDs。"
  value       = aws_nat_gateway.this[*].id
}

output "security_group_ids" {
  description = "下游服务使用的 Security Group IDs。"
  value = {
    alb       = aws_security_group.alb.id
    app       = aws_security_group.app.id
    database  = aws_security_group.database.id
    redis     = aws_security_group.redis.id
    endpoints = aws_security_group.endpoints.id
  }
}

output "flow_log_group_name" {
  description = "VPC Flow Log Group 名称；未启用时为 null。"
  value       = try(aws_cloudwatch_log_group.flow[0].name, null)
}

