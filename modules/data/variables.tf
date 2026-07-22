variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "private_db_subnet_ids" {
  description = "RDS 与 Redis 使用的 Private Database Subnet IDs。"
  type        = list(string)
  nullable    = false
  validation {
    condition     = length(var.private_db_subnet_ids) >= 2
    error_message = "至少需要两个 Private Database Subnet。"
  }
}

variable "database_security_group_id" {
  description = "RDS Security Group ID。"
  type        = string
  nullable    = false
  validation {
    condition     = startswith(var.database_security_group_id, "sg-")
    error_message = "database_security_group_id 必须以 sg- 开头。"
  }
}

variable "redis_security_group_id" {
  description = "Redis Security Group ID。"
  type        = string
  nullable    = false
  validation {
    condition     = startswith(var.redis_security_group_id, "sg-")
    error_message = "redis_security_group_id 必须以 sg- 开头。"
  }
}

variable "kms_key_arn" {
  description = "RDS、DynamoDB 与 Redis 加密 KMS Key ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn 必须是 ARN。"
  }
}

variable "database_name" {
  description = "PostgreSQL 初始数据库名。"
  type        = string
  default     = "platform"
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.database_name))
    error_message = "database_name 必须是有效 PostgreSQL 标识符。"
  }
}

variable "database_username" {
  description = "PostgreSQL 管理用户名。"
  type        = string
  default     = "platform_admin"
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.database_username))
    error_message = "database_username 格式无效。"
  }
}

variable "database_password" {
  description = "PostgreSQL 管理密码，由 Secrets Manager 生成并传入。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.database_password) >= 16
    error_message = "database_password 至少 16 个字符。"
  }
}

variable "redis_auth_token" {
  description = "Redis Auth Token，由 Secrets Manager 生成并传入。"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.redis_auth_token) >= 16
    error_message = "redis_auth_token 至少 16 个字符。"
  }
}

variable "enable_rds" {
  description = "是否创建 RDS PostgreSQL。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_rds)
    error_message = "enable_rds 必须是布尔值。"
  }
}

variable "rds_instance_class" {
  description = "RDS Instance Class。"
  type        = string
  default     = "db.t4g.micro"
  nullable    = false
  validation {
    condition     = startswith(var.rds_instance_class, "db.")
    error_message = "rds_instance_class 必须以 db. 开头。"
  }
}

variable "enable_rds_multi_az" {
  description = "是否启用 RDS Multi-AZ。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_rds_multi_az)
    error_message = "enable_rds_multi_az 必须是布尔值。"
  }
}

variable "backup_retention_days" {
  description = "RDS Automated Backup 保留天数。"
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days 必须在 1-35 之间。"
  }
}

variable "enable_deletion_protection" {
  description = "是否启用 RDS 删除保护。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_deletion_protection)
    error_message = "enable_deletion_protection 必须是布尔值。"
  }
}

variable "skip_final_snapshot" {
  description = "销毁 RDS 时是否跳过 Final Snapshot；prod 应为 false。"
  type        = bool
  default     = true
  nullable    = false
  validation {
    condition     = contains([true, false], var.skip_final_snapshot)
    error_message = "skip_final_snapshot 必须是布尔值。"
  }
}

variable "enable_enhanced_monitoring" {
  description = "是否启用 RDS Enhanced Monitoring。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_enhanced_monitoring)
    error_message = "enable_enhanced_monitoring 必须是布尔值。"
  }
}

variable "enable_performance_insights" {
  description = "是否启用 RDS Performance Insights。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_performance_insights)
    error_message = "enable_performance_insights 必须是布尔值。"
  }
}

variable "enable_dynamodb_stream" {
  description = "是否启用 DynamoDB Stream。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_dynamodb_stream)
    error_message = "enable_dynamodb_stream 必须是布尔值。"
  }
}

variable "enable_redis" {
  description = "是否创建 ElastiCache Redis。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_redis)
    error_message = "enable_redis 必须是布尔值。"
  }
}

variable "redis_node_type" {
  description = "Redis Node Type。"
  type        = string
  default     = "cache.t4g.micro"
  nullable    = false
  validation {
    condition     = startswith(var.redis_node_type, "cache.")
    error_message = "redis_node_type 必须以 cache. 开头。"
  }
}

variable "redis_multi_az" {
  description = "是否启用 Redis Multi-AZ 与 Automatic Failover。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.redis_multi_az)
    error_message = "redis_multi_az 必须是布尔值。"
  }
}

variable "tags" {
  description = "公共标签。"
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for key, value in var.tags : length(key) > 0 && length(value) > 0])
    error_message = "标签键和值不得为空。"
  }
}

