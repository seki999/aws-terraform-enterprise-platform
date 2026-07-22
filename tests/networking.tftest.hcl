mock_provider "aws" {}

run "two_az_low_cost_network" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix              = "platform-dev"
    vpc_cidr                 = "10.20.0.0/16"
    availability_zones       = ["ap-northeast-1a", "ap-northeast-1c"]
    public_subnet_cidrs      = ["10.20.0.0/24", "10.20.1.0/24"]
    private_app_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]
    private_db_subnet_cidrs  = ["10.20.20.0/24", "10.20.21.0/24"]
    enable_nat_gateway       = false
    single_nat_gateway       = true
    enable_vpc_endpoints     = false
    enable_flow_logs         = false
    logs_kms_key_arn         = "arn:aws:kms:ap-northeast-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "必须创建两个 Public Subnet。"
  }

  assert {
    condition     = length(aws_subnet.private_app) == 2
    error_message = "必须创建两个 Private Application Subnet。"
  }

  assert {
    condition     = length(aws_subnet.private_db) == 2
    error_message = "必须创建两个 Private Database Subnet。"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0
    error_message = "低成本配置不应创建 NAT Gateway。"
  }
}

run "production_nat_per_az" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    name_prefix              = "platform-prod"
    vpc_cidr                 = "10.40.0.0/16"
    availability_zones       = ["ap-northeast-1a", "ap-northeast-1c"]
    public_subnet_cidrs      = ["10.40.0.0/24", "10.40.1.0/24"]
    private_app_subnet_cidrs = ["10.40.10.0/24", "10.40.11.0/24"]
    private_db_subnet_cidrs  = ["10.40.20.0/24", "10.40.21.0/24"]
    enable_nat_gateway       = true
    single_nat_gateway       = false
    enable_vpc_endpoints     = false
    enable_flow_logs         = false
    logs_kms_key_arn         = "arn:aws:kms:ap-northeast-1:123456789012:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "生产策略必须每 AZ 创建一个 NAT Gateway。"
  }
}
