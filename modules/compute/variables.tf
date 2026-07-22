variable "name_prefix" {
  description = "资源名称前缀。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix 格式无效。"
  }
}

variable "vpc_id" {
  description = "部署 ALB 的 VPC ID。"
  type        = string
  nullable    = false
  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id 必须以 vpc- 开头。"
  }
}

variable "public_subnet_ids" {
  description = "ALB 使用的 Public Subnet IDs。"
  type        = list(string)
  nullable    = false
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "至少需要两个 Public Subnet。"
  }
}

variable "private_app_subnet_ids" {
  description = "ECS/EC2 使用的 Private Application Subnet IDs。"
  type        = list(string)
  nullable    = false
  validation {
    condition     = length(var.private_app_subnet_ids) >= 2
    error_message = "至少需要两个 Private Application Subnet。"
  }
}

variable "alb_security_group_id" {
  description = "ALB Security Group ID。"
  type        = string
  nullable    = false
  validation {
    condition     = startswith(var.alb_security_group_id, "sg-")
    error_message = "alb_security_group_id 必须以 sg- 开头。"
  }
}

variable "app_security_group_id" {
  description = "应用 Security Group ID。"
  type        = string
  nullable    = false
  validation {
    condition     = startswith(var.app_security_group_id, "sg-")
    error_message = "app_security_group_id 必须以 sg- 开头。"
  }
}

variable "ecs_execution_role_arn" {
  description = "ECS Task Execution Role ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.ecs_execution_role_arn))
    error_message = "ecs_execution_role_arn 必须是 ARN。"
  }
}

variable "ecs_task_role_arn" {
  description = "ECS Task Role ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.ecs_task_role_arn))
    error_message = "ecs_task_role_arn 必须是 ARN。"
  }
}

variable "ec2_instance_profile_name" {
  description = "EC2 SSM Instance Profile 名称。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.ec2_instance_profile_name) > 2
    error_message = "ec2_instance_profile_name 不得为空。"
  }
}

variable "database_secret_arn" {
  description = "注入 ECS 的数据库 Secret ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.database_secret_arn))
    error_message = "database_secret_arn 必须是 ARN。"
  }
}

variable "redis_secret_arn" {
  description = "注入 ECS 的 Redis Auth Token Secret ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.redis_secret_arn))
    error_message = "redis_secret_arn 必须是 ARN。"
  }
}

variable "rds_endpoint" {
  description = "RDS Host；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.rds_endpoint == null || length(var.rds_endpoint) > 3
    error_message = "rds_endpoint 无效。"
  }
}

variable "redis_endpoint" {
  description = "Redis Host；未启用时为 null。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.redis_endpoint == null || length(var.redis_endpoint) > 3
    error_message = "redis_endpoint 无效。"
  }
}

variable "log_level_parameter_arn" {
  description = "注入 ECS 的日志级别 Parameter ARN。"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^arn:", var.log_level_parameter_arn))
    error_message = "log_level_parameter_arn 必须是 ARN。"
  }
}

variable "upload_bucket_name" {
  description = "应用上传 Bucket 名称。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.upload_bucket_name) >= 3
    error_message = "upload_bucket_name 无效。"
  }
}

variable "access_logs_bucket_name" {
  description = "ALB Access Logs 目标 Bucket。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.access_logs_bucket_name) >= 3
    error_message = "access_logs_bucket_name 无效。"
  }
}

variable "dynamodb_table_name" {
  description = "应用使用的 DynamoDB Table 名称。"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.dynamodb_table_name) >= 3
    error_message = "dynamodb_table_name 无效。"
  }
}

variable "database_name" {
  description = "应用连接的 PostgreSQL 数据库名。"
  type        = string
  default     = "platform"
  nullable    = false
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]+$", var.database_name))
    error_message = "database_name 格式无效。"
  }
}

variable "sqs_queue_url" {
  description = "应用发送任务的 SQS Queue URL；Serverless 关闭时可为空字符串。"
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = var.sqs_queue_url == "" || startswith(var.sqs_queue_url, "https://")
    error_message = "sqs_queue_url 必须为空或 HTTPS URL。"
  }
}

variable "enable_alb" {
  description = "是否创建 ALB。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_alb)
    error_message = "enable_alb 必须是布尔值。"
  }
}

variable "enable_ecs" {
  description = "是否创建 ECS Fargate Service。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_ecs)
    error_message = "enable_ecs 必须是布尔值。"
  }
}

variable "enable_ec2" {
  description = "是否创建 EC2 Auto Scaling Group 示例。"
  type        = bool
  default     = false
  nullable    = false
  validation {
    condition     = contains([true, false], var.enable_ec2)
    error_message = "enable_ec2 必须是布尔值。"
  }
}

variable "container_image" {
  description = "ECS 镜像 URI；为空时使用本模块 ECR 的 latest 标签。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.container_image == null || length(var.container_image) > 5
    error_message = "container_image 必须是有效 URI 或 null。"
  }
}

variable "container_port" {
  description = "容器监听端口。"
  type        = number
  default     = 8000
  nullable    = false
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port 必须在 1-65535 之间。"
  }
}

variable "ecs_cpu" {
  description = "Fargate Task CPU 单位。"
  type        = number
  default     = 256
  nullable    = false
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_cpu)
    error_message = "ecs_cpu 必须是受支持的 Fargate CPU 值。"
  }
}

variable "ecs_memory" {
  description = "Fargate Task 内存 MiB。"
  type        = number
  default     = 512
  nullable    = false
  validation {
    condition     = var.ecs_memory >= 512 && var.ecs_memory <= 30720
    error_message = "ecs_memory 必须在 512-30720 MiB 之间。"
  }
}

variable "ecs_desired_count" {
  description = "ECS Service 期望 Task 数。"
  type        = number
  default     = 1
  nullable    = false
  validation {
    condition     = var.ecs_desired_count >= 0 && var.ecs_desired_count <= 20
    error_message = "ecs_desired_count 必须在 0-20 之间。"
  }
}

variable "ecs_max_count" {
  description = "ECS Auto Scaling 最大 Task 数。"
  type        = number
  default     = 3
  nullable    = false
  validation {
    condition     = var.ecs_max_count >= 1 && var.ecs_max_count <= 100
    error_message = "ecs_max_count 必须在 1-100 之间。"
  }
}

variable "instance_type" {
  description = "可选 EC2 示例的实例类型。"
  type        = string
  default     = "t3.micro"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][0-9a-z]+[.][a-z0-9]+$", var.instance_type))
    error_message = "instance_type 格式无效。"
  }
}

variable "log_retention_days" {
  description = "ECS Log Group 保留天数。"
  type        = number
  default     = 7
  nullable    = false
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 180, 365], var.log_retention_days)
    error_message = "log_retention_days 值无效。"
  }
}

variable "logs_kms_key_arn" {
  description = "ECS Log Group KMS Key ARN；null 时使用服务端默认加密。"
  type        = string
  default     = null
  nullable    = true
  validation {
    condition     = var.logs_kms_key_arn == null || can(regex("^arn:", var.logs_kms_key_arn))
    error_message = "logs_kms_key_arn 必须是 ARN 或 null。"
  }
}

variable "kms_key_arn" {
  description = "ECR 镜像加密使用的 KMS Key ARN。"
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
