variable "project_name" {
  description = "项目名称。"
  type        = string
  default     = "aws-terraform-enterprise-platform"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,40}$", var.project_name))
    error_message = "project_name 格式无效。"
  }
}

variable "environment" {
  description = "本根模块的固定环境名。"
  type        = string
  default     = "prod"
  nullable    = false
  validation {
    condition     = var.environment == "prod"
    error_message = "此目录只能管理 prod 环境。"
  }
}

variable "aws_region" {
  description = "主 AWS 区域。"
  type        = string
  default     = "ap-northeast-1"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region 格式无效。"
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR。"
  type        = string
  default     = "10.40.0.0/16"
  nullable    = false
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr 无效。"
  }
}

variable "availability_zones" {
  description = "使用的可用区。"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
  nullable    = false
  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 3
    error_message = "availability_zones 必须包含 2-3 项。"
  }
}

variable "public_subnet_cidrs" {
  description = "Public Subnet CIDRs。"
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24"]
  nullable    = false
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "至少需要两个 Public Subnet。"
  }
}

variable "private_app_subnet_cidrs" {
  description = "Private Application Subnet CIDRs。"
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24"]
  nullable    = false
  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2
    error_message = "至少需要两个 Private Application Subnet。"
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private Database Subnet CIDRs。"
  type        = list(string)
  default     = ["10.40.20.0/24", "10.40.21.0/24"]
  nullable    = false
  validation {
    condition     = length(var.private_db_subnet_cidrs) >= 2
    error_message = "至少需要两个 Private Database Subnet。"
  }
}

variable "owner" {
  description = "Owner 标签。"
  type        = string
  default     = "platform-team"
  nullable    = false
  validation {
    condition     = length(var.owner) > 0
    error_message = "owner 不得为空。"
  }
}

variable "cost_center" {
  description = "CostCenter 标签。"
  type        = string
  default     = "learning"
  nullable    = false
  validation {
    condition     = length(var.cost_center) > 0
    error_message = "cost_center 不得为空。"
  }
}

variable "repository" {
  description = "Repository 标签。"
  type        = string
  default     = "aws-terraform-enterprise-platform"
  nullable    = false
  validation {
    condition     = length(var.repository) > 0
    error_message = "repository 不得为空。"
  }
}

variable "enable_nat_gateway" {
  description = "是否创建 NAT Gateway。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_nat_gateway)
    error_message = "必须是布尔值。"
  }
}

variable "single_nat_gateway" {
  description = "是否共享一个 NAT。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.single_nat_gateway)
    error_message = "必须是布尔值。"
  }
}

variable "enable_vpc_endpoints" {
  description = "是否创建 VPC Endpoints。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_vpc_endpoints)
    error_message = "必须是布尔值。"
  }
}

variable "enable_cloudfront" {
  description = "是否创建 CloudFront。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_cloudfront)
    error_message = "必须是布尔值。"
  }
}

variable "enable_waf" {
  description = "是否创建 WAF。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_waf)
    error_message = "必须是布尔值。"
  }
}

variable "domain_name" {
  description = "可选前端域名。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.domain_name == null || can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "domain_name 无效。"
  }
}

variable "hosted_zone_id" {
  description = "可选 Hosted Zone ID。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.hosted_zone_id == null || startswith(var.hosted_zone_id, "Z")
    error_message = "hosted_zone_id 无效。"
  }
}

variable "enable_alb" {
  description = "是否创建 ALB。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_alb)
    error_message = "必须是布尔值。"
  }
}

variable "enable_ecs" {
  description = "是否创建 ECS Service。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_ecs)
    error_message = "必须是布尔值。"
  }
}

variable "enable_ec2" {
  description = "是否创建 EC2/ASG。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_ec2)
    error_message = "必须是布尔值。"
  }
}

variable "enable_rds" {
  description = "是否创建 RDS。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_rds)
    error_message = "必须是布尔值。"
  }
}

variable "enable_rds_multi_az" {
  description = "是否启用 RDS Multi-AZ。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_rds_multi_az)
    error_message = "必须是布尔值。"
  }
}

variable "enable_redis" {
  description = "是否创建 Redis。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_redis)
    error_message = "必须是布尔值。"
  }
}

variable "enable_serverless" {
  description = "是否创建 Serverless 链路。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_serverless)
    error_message = "必须是布尔值。"
  }
}

variable "enable_cloudtrail" {
  description = "是否创建 CloudTrail。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_cloudtrail)
    error_message = "必须是布尔值。"
  }
}

variable "enable_config" {
  description = "是否创建 AWS Config。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_config)
    error_message = "必须是布尔值。"
  }
}

variable "enable_guardduty" {
  description = "是否创建 GuardDuty。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_guardduty)
    error_message = "必须是布尔值。"
  }
}

variable "enable_backup" {
  description = "是否创建 AWS Backup。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_backup)
    error_message = "必须是布尔值。"
  }
}

variable "enable_cicd" {
  description = "是否创建 CodeBuild/CodePipeline。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_cicd)
    error_message = "必须是布尔值。"
  }
}

variable "enable_github_oidc" {
  description = "是否创建 GitHub OIDC Role。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_github_oidc)
    error_message = "必须是布尔值。"
  }
}

variable "ecs_cpu" {
  description = "ECS CPU。"
  type        = number
  default     = 256
  nullable    = false
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_cpu)
    error_message = "ecs_cpu 无效。"
  }
}

variable "ecs_memory" {
  description = "ECS 内存 MiB。"
  type        = number
  default     = 512
  nullable    = false
  validation {
    condition     = var.ecs_memory >= 512
    error_message = "ecs_memory 至少 512。"
  }
}

variable "ecs_desired_count" {
  description = "ECS 期望 Task 数。"
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.ecs_desired_count >= 0 && var.ecs_desired_count <= 20
    error_message = "ecs_desired_count 必须在 0-20。"
  }
}

variable "instance_type" {
  description = "EC2 Instance Type。"
  type        = string
  default     = "t3.micro"
  nullable    = false
  validation {
    condition     = length(var.instance_type) >= 4
    error_message = "instance_type 无效。"
  }
}

variable "rds_instance_class" {
  description = "RDS Instance Class。"
  type        = string
  default     = "db.t4g.micro"
  nullable    = false
  validation {
    condition     = startswith(var.rds_instance_class, "db.")
    error_message = "rds_instance_class 无效。"
  }
}

variable "database_name" {
  description = "初始数据库名。"
  type        = string
  default     = "platform"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]+$", var.database_name))
    error_message = "database_name 无效。"
  }
}

variable "backup_retention_days" {
  description = "RDS 备份保留天数。"
  type        = number
  default     = 14
  nullable    = false
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days 必须在 1-35。"
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs 保留天数。"
  type        = number
  default     = 90
  nullable    = false
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "log_retention_days 无效。"
  }
}

variable "github_repository" {
  description = "GitHub owner/repository。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.github_repository == null || can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository 无效。"
  }
}

variable "alarm_email" {
  description = "可选告警邮箱。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.alarm_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alarm_email))
    error_message = "alarm_email 无效。"
  }
}

