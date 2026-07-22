variable "name_prefix" {
  description = "资源名称前缀，格式为 project-environment。"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 必须由小写字母、数字和连字符组成。"
  }
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR。"
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr 必须是有效 IPv4 CIDR。"
  }
}

variable "availability_zones" {
  description = "使用的两个或三个可用区。"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3 && length(distinct(var.availability_zones)) == length(var.availability_zones)
    error_message = "availability_zones 必须包含 2-3 个不重复可用区。"
  }
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDR，顺序与 availability_zones 一致。"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "至少提供两个有效 Public Subnet CIDR。"
  }
}

variable "private_app_subnet_cidrs" {
  description = "Private Application Subnet CIDR。"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_app_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "至少提供两个有效 Private Application Subnet CIDR。"
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private Database Subnet CIDR。"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.private_db_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_db_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "至少提供两个有效 Private Database Subnet CIDR。"
  }
}

variable "enable_nat_gateway" {
  description = "是否创建 NAT Gateway。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_nat_gateway)
    error_message = "enable_nat_gateway 必须是布尔值。"
  }
}

variable "single_nat_gateway" {
  description = "是否让全部应用子网共享一个 NAT Gateway。"
  type        = bool
  default     = true
  nullable    = false

  validation {
    condition     = contains([true, false], var.single_nat_gateway)
    error_message = "single_nat_gateway 必须是布尔值。"
  }
}

variable "enable_vpc_endpoints" {
  description = "是否创建 S3、DynamoDB、ECR、Logs 和 Secrets Manager Endpoint。"
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_vpc_endpoints)
    error_message = "enable_vpc_endpoints 必须是布尔值。"
  }
}

variable "enable_flow_logs" {
  description = "是否创建 VPC Flow Logs。"
  type        = bool
  default     = true
  nullable    = false

  validation {
    condition     = contains([true, false], var.enable_flow_logs)
    error_message = "enable_flow_logs 必须是布尔值。"
  }
}

variable "container_port" {
  description = "ALB 到应用的容器端口。"
  type        = number
  default     = 8000
  nullable    = false

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port 必须在 1-65535 之间。"
  }
}

variable "log_retention_days" {
  description = "Flow Logs 的 CloudWatch Logs 保留天数。"
  type        = number
  default     = 7
  nullable    = false

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days 必须是 CloudWatch Logs 支持的值。"
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

