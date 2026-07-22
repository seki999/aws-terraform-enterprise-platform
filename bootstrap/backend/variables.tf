variable "project_name" {
  description = "用于 Backend 资源命名的项目名称。"
  type        = string
  default     = "aws-terraform-enterprise-platform"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,40}$", var.project_name))
    error_message = "project_name 必须是 3-41 位小写字母、数字或连字符，并以字母开头。"
  }
}

variable "aws_region" {
  description = "Backend 所在 AWS 区域。"
  type        = string
  default     = "ap-northeast-1"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region 必须是有效的 AWS 区域格式。"
  }
}

variable "bucket_name_override" {
  description = "可选的全局唯一 State Bucket 名称；为空时追加随机后缀。"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.bucket_name_override == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name_override))
    error_message = "bucket_name_override 必须满足 S3 Bucket 命名规则或为 null。"
  }
}

variable "force_destroy" {
  description = "是否允许 Terraform 删除非空 State Bucket；默认禁止。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = var.force_destroy == false
    error_message = "安全基线禁止启用 force_destroy；如需迁移请先走人工 State 备份流程。"
  }
}

variable "kms_deletion_window_days" {
  description = "KMS Key 删除等待天数。"
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "kms_deletion_window_days 必须在 7 到 30 之间。"
  }
}

variable "tags" {
  description = "附加到 Backend 资源的公共标签。"
  type        = map(string)
  default = {
    Owner      = "platform-team"
    CostCenter = "learning"
    Repository = "aws-terraform-enterprise-platform"
  }
  nullable = false

  validation {
    condition     = alltrue([for key in ["Owner", "CostCenter", "Repository"] : contains(keys(var.tags), key)])
    error_message = "tags 必须包含 Owner、CostCenter 和 Repository。"
  }
}

