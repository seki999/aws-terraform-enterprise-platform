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
  description = "确保 S3 Bucket 全局唯一的后缀，通常使用账号 ID。"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9-]{4,32}$", var.bucket_suffix))
    error_message = "bucket_suffix 必须为 4-32 位小写字母、数字或连字符。"
  }
}

variable "kms_key_arn" {
  description = "上传数据使用的 KMS Key ARN。"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn 必须是 ARN。"
  }
}

variable "enable_cloudfront" {
  description = "是否创建 CloudFront Distribution。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_cloudfront)
    error_message = "enable_cloudfront 必须是布尔值。"
  }
}

variable "enable_waf" {
  description = "是否创建并关联 CloudFront WAF。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_waf)
    error_message = "enable_waf 必须是布尔值。"
  }
}

variable "domain_name" {
  description = "可选前端域名；为空时使用 CloudFront 默认域名。"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.domain_name == null || can(regex("^[a-z0-9.-]+[.][a-z]{2,}$", var.domain_name))
    error_message = "domain_name 必须是有效 DNS 名称或 null。"
  }
}

variable "hosted_zone_id" {
  description = "可选 Route 53 Hosted Zone ID；自定义域名时必填。"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.hosted_zone_id == null || can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id))
    error_message = "hosted_zone_id 必须是 Route 53 Zone ID 或 null。"
  }
}

variable "price_class" {
  description = "CloudFront Price Class。"
  type        = string
  default     = "PriceClass_200"
  nullable    = false

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class 值无效。"
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
