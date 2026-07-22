provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
      Repository  = var.repository
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
      Repository  = var.repository
    }
  }
}

module "platform" {
  source = "../../modules/platform"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  owner                    = var.owner
  cost_center              = var.cost_center
  repository               = var.repository
  enable_nat_gateway       = var.enable_nat_gateway
  single_nat_gateway       = var.single_nat_gateway
  enable_vpc_endpoints     = var.enable_vpc_endpoints
  enable_cloudfront        = var.enable_cloudfront
  enable_waf               = var.enable_waf
  domain_name              = var.domain_name
  hosted_zone_id           = var.hosted_zone_id
  enable_alb               = var.enable_alb
  enable_ecs               = var.enable_ecs
  enable_ec2               = var.enable_ec2
  enable_rds               = var.enable_rds
  enable_rds_multi_az      = var.enable_rds_multi_az
  enable_redis             = var.enable_redis
  enable_serverless        = var.enable_serverless
  enable_cloudtrail        = var.enable_cloudtrail
  enable_config            = var.enable_config
  enable_guardduty         = var.enable_guardduty
  enable_backup            = var.enable_backup
  enable_cicd              = var.enable_cicd
  enable_github_oidc       = var.enable_github_oidc
  ecs_cpu                  = var.ecs_cpu
  ecs_memory               = var.ecs_memory
  ecs_desired_count        = var.ecs_desired_count
  instance_type            = var.instance_type
  rds_instance_class       = var.rds_instance_class
  database_name            = var.database_name
  backup_retention_days    = var.backup_retention_days
  log_retention_days       = var.log_retention_days
  github_repository        = var.github_repository
  alarm_email              = var.alarm_email
}

