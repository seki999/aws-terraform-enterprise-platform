variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "enable_serverless" {
  description = "是否创建 Serverless 处理链。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_serverless)
    error_message = "enable_serverless 必须是布尔值。"
  }
}

variable "kms_key_arn" {
  description = "SQS、SNS、Lambda 环境变量使用的 KMS Key ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn 必须是 ARN。"
  }
}

variable "lambda_role_arns" {
  description = "Validator、Consumer、Worker 的独立 IAM Role ARN。"
  type        = map(string)
  nullable    = false
  validation {
    condition     = alltrue([for key in ["lambda_validator", "lambda_consumer", "lambda_worker"] : contains(keys(var.lambda_role_arns), key)])
    error_message = "lambda_role_arns 必须包含三个 Lambda Role。"
  }
}

variable "dynamodb_table_name" {
  description = "处理结果写入的 DynamoDB Table 名称。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.dynamodb_table_name) >= 3
    error_message = "dynamodb_table_name 无效。"
  }
}

variable "sns_notification_email" {
  description = "可选通知邮箱；订阅需收件人确认。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.sns_notification_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.sns_notification_email))
    error_message = "sns_notification_email 必须是邮箱或 null。"
  }
}

variable "log_retention_days" {
  description = "Lambda/API/Step Functions 日志保留天数。"
  type        = number
  default     = 7
  nullable    = false
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "log_retention_days 值无效。"
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

