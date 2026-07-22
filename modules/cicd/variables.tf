variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "enable_cicd" {
  description = "是否创建 CodeBuild 和 CodePipeline。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_cicd)
    error_message = "enable_cicd 必须是布尔值。"
  }
}

variable "github_repository" {
  description = "CodeStar Connection 的 owner/repository。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.github_repository == null || can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository 必须是 owner/repository 或 null。"
  }
}

variable "github_branch" {
  description = "CodePipeline 监听分支。"
  type        = string
  default     = "main"
  nullable    = false
  validation {
    condition     = length(var.github_branch) > 0
    error_message = "github_branch 不得为空。"
  }
}

variable "bucket_suffix" {
  description = "Artifact Bucket 全局唯一后缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9-]{4,32}$", var.bucket_suffix))
    error_message = "bucket_suffix 格式无效。"
  }
}

variable "kms_key_arn" {
  description = "Artifact Bucket KMS Key ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn 必须是 ARN。"
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

