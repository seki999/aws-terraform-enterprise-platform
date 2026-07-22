data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    Repository  = var.repository
  })
}

module "networking" {
  source = "../networking"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
  single_nat_gateway       = var.single_nat_gateway
  enable_vpc_endpoints     = var.enable_vpc_endpoints
  enable_flow_logs         = true
  log_retention_days       = var.log_retention_days
  tags                     = local.common_tags
}

module "identity" {
  source = "../identity"

  name_prefix        = local.name_prefix
  log_retention_days = var.log_retention_days
  enable_github_oidc = var.enable_github_oidc
  github_repository  = var.github_repository
  tags               = local.common_tags
}

module "frontend" {
  source = "../frontend"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix       = local.name_prefix
  bucket_suffix     = data.aws_caller_identity.current.account_id
  kms_key_arn       = module.identity.data_kms_key_arn
  enable_cloudfront = var.enable_cloudfront
  enable_waf        = var.enable_waf
  domain_name       = var.domain_name
  hosted_zone_id    = var.hosted_zone_id
  tags              = local.common_tags
}

module "data" {
  source = "../data"

  name_prefix                 = local.name_prefix
  private_db_subnet_ids       = module.networking.private_db_subnet_ids
  database_security_group_id  = module.networking.security_group_ids.database
  redis_security_group_id     = module.networking.security_group_ids.redis
  kms_key_arn                 = module.identity.data_kms_key_arn
  database_name               = var.database_name
  database_password           = module.identity.database_password
  redis_auth_token            = module.identity.redis_auth_token
  enable_rds                  = var.enable_rds
  rds_instance_class          = var.rds_instance_class
  enable_rds_multi_az         = var.enable_rds_multi_az
  backup_retention_days       = var.backup_retention_days
  enable_deletion_protection  = var.environment == "prod"
  skip_final_snapshot         = var.environment != "prod"
  enable_enhanced_monitoring  = var.environment == "prod" && var.enable_rds
  enable_performance_insights = var.environment == "prod" && var.enable_rds
  enable_redis                = var.enable_redis
  redis_multi_az              = var.environment == "prod" && var.enable_redis
  tags                        = local.common_tags
}

module "serverless" {
  source = "../serverless"

  name_prefix         = local.name_prefix
  enable_serverless   = var.enable_serverless
  kms_key_arn         = module.identity.data_kms_key_arn
  lambda_role_arns    = module.identity.runtime_role_arns
  dynamodb_table_name = module.data.dynamodb_table_name
  log_retention_days  = var.log_retention_days
  tags                = local.common_tags
}

module "compute" {
  source = "../compute"

  name_prefix               = local.name_prefix
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  alb_security_group_id     = module.networking.security_group_ids.alb
  app_security_group_id     = module.networking.security_group_ids.app
  ecs_execution_role_arn    = module.identity.runtime_role_arns.ecs_execution
  ecs_task_role_arn         = module.identity.runtime_role_arns.ecs_task
  ec2_instance_profile_name = module.identity.ec2_instance_profile_name
  database_secret_arn       = module.identity.database_secret_arn
  redis_secret_arn          = module.identity.redis_secret_arn
  rds_endpoint              = module.data.rds_endpoint
  redis_endpoint            = module.data.redis_primary_endpoint
  log_level_parameter_arn   = module.identity.log_level_parameter_arn
  upload_bucket_name        = module.frontend.upload_bucket_id
  access_logs_bucket_name   = module.frontend.access_logs_bucket_id
  dynamodb_table_name       = module.data.dynamodb_table_name
  database_name             = var.database_name
  sqs_queue_url             = module.serverless.queue_url
  enable_alb                = var.enable_alb
  enable_ecs                = var.enable_ecs
  enable_ec2                = var.enable_ec2
  ecs_cpu                   = var.ecs_cpu
  ecs_memory                = var.ecs_memory
  ecs_desired_count         = var.ecs_desired_count
  instance_type             = var.instance_type
  log_retention_days        = var.log_retention_days
  tags                      = local.common_tags
}

module "operations" {
  source = "../operations"

  name_prefix                = local.name_prefix
  bucket_suffix              = data.aws_caller_identity.current.account_id
  kms_key_arn                = module.identity.data_kms_key_arn
  enable_monitoring          = true
  enable_cloudtrail          = var.enable_cloudtrail
  enable_config              = var.enable_config
  enable_guardduty           = var.enable_guardduty
  enable_backup              = var.enable_backup
  backup_resource_arns       = var.enable_rds ? [module.data.rds_arn] : []
  alarm_email                = var.alarm_email
  alb_arn_suffix             = module.compute.alb_arn_suffix
  ecs_cluster_name           = module.compute.ecs_cluster_name
  ecs_service_name           = module.compute.ecs_service_name
  lambda_function_names      = module.serverless.lambda_function_names
  api_id                     = module.serverless.api_id
  queue_name                 = module.serverless.queue_name
  dlq_name                   = module.serverless.dlq_name
  rds_identifier             = module.data.rds_identifier
  redis_replication_group_id = module.data.redis_replication_group_id
  nat_gateway_ids            = module.networking.nat_gateway_ids
  tags                       = local.common_tags
}

module "cicd" {
  source = "../cicd"

  name_prefix       = local.name_prefix
  enable_cicd       = var.enable_cicd
  github_repository = var.github_repository
  bucket_suffix     = data.aws_caller_identity.current.account_id
  kms_key_arn       = module.identity.data_kms_key_arn
  tags              = local.common_tags
}

check "subnet_cidr_lengths" {
  assert {
    condition = (
      length(var.availability_zones) == length(var.public_subnet_cidrs) &&
      length(var.availability_zones) == length(var.private_app_subnet_cidrs) &&
      length(var.availability_zones) == length(var.private_db_subnet_cidrs)
    )
    error_message = "三组 Subnet CIDR 数量必须与 availability_zones 一致。"
  }
}

check "production_resilience" {
  assert {
    condition = var.environment != "prod" || (
      (!var.enable_nat_gateway || !var.single_nat_gateway) &&
      (!var.enable_rds || var.enable_rds_multi_az)
    )
    error_message = "prod 启用 NAT 时必须每 AZ 一个；启用 RDS 时必须 Multi-AZ。"
  }
}
