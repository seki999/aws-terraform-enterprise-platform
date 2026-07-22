variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "bucket_suffix" {
  description = "审计 Bucket 全局唯一后缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9-]{4,32}$", var.bucket_suffix))
    error_message = "bucket_suffix 格式无效。"
  }
}

variable "kms_key_arn" {
  description = "告警、审计和备份使用的 KMS Key ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn 必须是 ARN。"
  }
}

variable "enable_monitoring" {
  description = "是否创建 Dashboard 和适用告警。"
  type        = bool
  default     = true
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_monitoring)
    error_message = "enable_monitoring 必须是布尔值。"
  }
}

variable "enable_cloudtrail" {
  description = "是否创建 CloudTrail。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_cloudtrail)
    error_message = "enable_cloudtrail 必须是布尔值。"
  }
}

variable "enable_config" {
  description = "是否创建 AWS Config Recorder、Delivery Channel 和规则。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_config)
    error_message = "enable_config 必须是布尔值。"
  }
}

variable "enable_guardduty" {
  description = "是否创建 GuardDuty Detector。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_guardduty)
    error_message = "enable_guardduty 必须是布尔值。"
  }
}

variable "enable_backup" {
  description = "是否创建 AWS Backup Vault、Plan 和 Selection。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_backup)
    error_message = "enable_backup 必须是布尔值。"
  }
}

variable "backup_resource_arns" {
  description = "AWS Backup 选择的资源 ARN。"
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for arn in var.backup_resource_arns : startswith(arn, "arn:")])
    error_message = "backup_resource_arns 中每项必须是 ARN。"
  }
}

variable "alarm_email" {
  description = "可选 CloudWatch Alarm 邮箱；需收件人确认。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.alarm_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alarm_email))
    error_message = "alarm_email 必须是邮箱或 null。"
  }
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.alb_arn_suffix == null || startswith(var.alb_arn_suffix, "app/")
    error_message = "alb_arn_suffix 必须以 app/ 开头或为 null。"
  }
}

variable "ecs_cluster_name" {
  description = "ECS Cluster 名称。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.ecs_cluster_name) >= 3
    error_message = "ecs_cluster_name 无效。"
  }
}

variable "ecs_service_name" {
  description = "ECS Service 名称；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.ecs_service_name == null || length(var.ecs_service_name) >= 3
    error_message = "ecs_service_name 无效。"
  }
}

variable "lambda_function_names" {
  description = "需要监控的 Lambda Function 名称 Map。"
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for name in values(var.lambda_function_names) : length(name) > 0])
    error_message = "Lambda Function 名称不得为空。"
  }
}

variable "api_id" {
  description = "API Gateway API ID；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.api_id == null || length(var.api_id) >= 8
    error_message = "api_id 无效。"
  }
}

variable "queue_name" {
  description = "SQS Queue 名称；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.queue_name == null || length(var.queue_name) >= 3
    error_message = "queue_name 无效。"
  }
}

variable "dlq_name" {
  description = "SQS DLQ 名称；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.dlq_name == null || length(var.dlq_name) >= 3
    error_message = "dlq_name 无效。"
  }
}

variable "rds_identifier" {
  description = "RDS Identifier；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.rds_identifier == null || length(var.rds_identifier) >= 3
    error_message = "rds_identifier 无效。"
  }
}

variable "redis_replication_group_id" {
  description = "Redis Replication Group ID；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.redis_replication_group_id == null || length(var.redis_replication_group_id) >= 3
    error_message = "redis_replication_group_id 无效。"
  }
}

variable "nat_gateway_ids" {
  description = "需要监控的 NAT Gateway IDs。"
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for id in var.nat_gateway_ids : startswith(id, "nat-")])
    error_message = "nat_gateway_ids 中每项必须以 nat- 开头。"
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

