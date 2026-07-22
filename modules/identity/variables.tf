variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "enable_github_oidc" {
  description = "是否创建 GitHub Actions OIDC Provider 与 Terraform Plan Role。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_github_oidc)
    error_message = "enable_github_oidc 必须是布尔值。"
  }
}

variable "github_repository" {
  description = "OIDC 信任的 owner/repository；启用 OIDC 时必填。"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.github_repository == null || can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository 必须是 owner/repository 格式或 null。"
  }
}

variable "github_subjects" {
  description = "允许的 GitHub OIDC Subject 后缀，例如 ref:refs/heads/main。"
  type        = list(string)
  default     = ["pull_request"]
  nullable    = false

  validation {
    condition     = length(var.github_subjects) > 0 && alltrue([for subject in var.github_subjects : length(subject) > 0])
    error_message = "github_subjects 至少包含一个非空值。"
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
